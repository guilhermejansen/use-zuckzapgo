# Webhook events — payload enrichment schema

ZuckZapGo's webhook payload is **fully backward compatible**. Every existing
payload key (`type`, `event`, jid fields, etc.) is unchanged and every event
type that was emitted before is still emitted.

## Primary and fallback callback URLs

`POST /webhook` and `PUT /webhook` continue to accept the existing
`webhookurl` field. Clients may additionally send `fallback_webhookurl`.
The primary URL is attempted first; the fallback is used only for transport
errors, timeouts, HTTP 408/425/429, or 5xx responses. Other 4xx responses are
treated as definitive application rejections and are not retried through the
fallback.

When `fallback_webhookurl` is omitted, delivery behaves exactly as in earlier
releases. Both attempts carry the same `X-Event-ID`, so receivers can preserve
at-least-once delivery while deduplicating ambiguous timeout retries. The
capability is advertised as `capabilities.webhook_fallback = 1` by `/health`.

## Delivery envelope

O evento lógico fica em `data` nos webhooks/RabbitMQ e em `payload` nos envelopes SQS/WebSocket/Redis. **Os envelopes externos não são idênticos.** Webhook individual usa `token`; webhook global usa `userToken` e `source`. O Redis Streams codifica o envelope em MessagePack. Consulte a [matriz completa por transporte](#contrato-de-saída-por-transporte--global-e-individual) ao implementar um receptor.

Nos exemplos de enriquecimento abaixo, `data` refere-se ao payload de webhook. Para SQS/WebSocket/Redis, leia o mesmo conteúdo em `payload`, após decodificar o envelope. Enriquecimentos são irmãos de `event`, nunca substituem automaticamente o evento bruto.

## Spec 004 `v1` envelope

Spec 004 adds **one** new key to the event payload: **`data.v1`**. All v1
enrichment is nested under that single additive key. Consumers that don't
know about `v1` simply ignore it.

| Field            | Type   | Notes                                              |
|------------------|--------|----------------------------------------------------|
| `schema_version` | string | Always `"1"` for this schema.                      |
| `event`          | string | Dotted event name, e.g. `v1.call.offer`.           |
| `instance_id`    | string | The ZuckZapGo user/instance id.                    |
| `ts`             | string | RFC3339Nano UTC timestamp.                          |
| `data`           | object | Event-specific payload (see below).                 |

## Call events (`v1.call.*`)

The `v1` object is co-emitted with the existing call webhook (`type` stays
`CallOffer`/`CallAccept`/...). **All** call events keep `dowebhook=1` — none
are suppressed, including `v1.call.relay_latency` and `v1.call.transport`.

| Event                   | Emitted with `type`   | Key `data` fields                                                                 |
|-------------------------|-----------------------|-----------------------------------------------------------------------------------|
| `v1.call.offer`         | `CallOffer`           | `call_id`, `from`, `caller_phone`, `caller_lid`, `is_group`, `group_jid`, `media`, `platform`, `client_version`, `timestamp_unix_ms`, `raw_xml` |
| `v1.call.offer_notice`  | `CallOfferNotice`     | `call_id`, `from`, `caller_phone`, `caller_lid`, `is_group`, `group_jid`, `media`, `notice_type`, `timestamp_unix_ms`, `raw_xml` |
| `v1.call.accept`        | `CallAccept`          | `call_id`, `from`, `caller_phone`, `caller_lid`, `platform`, `client_version`, `timestamp_unix_ms` |
| `v1.call.preaccept`     | `CallPreAccept`       | `call_id`, `from`, `caller_phone`, `caller_lid`, `platform`, `client_version`, `timestamp_unix_ms` |
| `v1.call.transport`     | `CallTransport`       | `call_id`, `from`, `timestamp_unix_ms`, `raw_xml`                                  |
| `v1.call.terminate`     | `CallTerminate`       | `call_id`, `from`, `reason`, `terminated_by`, `timestamp_unix_ms`, **`duration_ms` (only when computable)** |
| `v1.call.reject`        | `CallReject`          | `call_id`, `from`, `rejected_by`, `reject_type`, `timestamp_unix_ms`               |
| `v1.call.relay_latency` | `CallRelayLatency`    | `call_id`, `from`, `timestamp_unix_ms`, `raw_xml`                                  |
| `v1.call.unknown`       | `UnknownCallEvent`    | `raw_xml`, `timestamp_unix_ms`                                                     |
| `v1.call.log`           | `CallLog`             | `call_id`, `call_result`, `duration_ms`, `started_at_unix`, `is_incoming`, `is_video`, `is_call_link`, `call_creator_jid`, `group_jid`, `call_type`, `participants[]{jid, call_result}`, `timestamp_unix_ms` |

> **`duration_ms` is never fabricated.** Because there is no call-log table,
> call duration is not computable from inbound webhook events alone, so
> `v1.call.terminate.data.duration_ms` is **omitted** rather than guessed.

> **`CallLog` is the phone's own record.** After a call ends, the primary phone syncs its
> call log through app state (`callLogAction`). The gateway re-emits that record as a
> dedicated `CallLog` webhook (typed `event` keys `CallID`, `CallResult`, `Duration` in
> seconds, `StartTime`, `IsIncoming`, `IsVideo`, `IsCallLink`, `CallCreatorJID`,
> `GroupJID`, `CallType`, `Participants[]{UserJID, CallResult}`, `Timestamp`) next to
> the raw `AppState` one. It is the only way a linked device learns the outcome and
> duration of a call the phone answered: WhatsApp does not send `<terminate>` to devices
> that did not take part in the call.
> (The former sidecar route `/call/media/{call_id}/hangup`, which returned a measured
> `duration_ms`, was removed together with the Spec 005 sidecar bridge.)

## Order events (`v1.order.*`)

`v1.order.received` is the enrichment envelope for an inbound `OrderMessage`,
built via `BuildOrderReceivedV1`. `data`: `message_id`, `business_jid`,
`customer_jid`, `order_id`, `item_count`, `total`, `currency`, `products[]`,
`enrichment_error`.

## `OrderState` event — order state kept by the gateway

The official WhatsApp apps keep the seller's order/billing card state (Accept /
Decline, "Update status") only on the device that acted; nothing syncs it to the
seller's other devices. The gateway is a linked device, so it keeps its **own**
order state and emits `type: "OrderState"` after every change. Subscribe with
`OrderState` (or `All`). The same state is readable with
`GET /business/order/state/{messageID}` (or `?reference_id=`, `?order_id=`,
`?billing_message_id=`).

Changes come from three places:

- **received order** (`source: "device"`): an `OrderMessage` received from a buyer
  (state `received`);
- **this gateway** (`source: "api"`): `POST /business/order/accept`, `/reject`,
  `/status/send` and `/payment/status/send` after WhatsApp acknowledged the message;
- **the seller's phone** (`source: "device"`): own messages sent from another device
  of the account — billing with `order_request_id` (accept), the refusal text
  `Este pedido foi recusado.` quoting the order (decline), `payment_status` and
  `review_order` declarations quoting the billing.

One event is emitted per change (a payment declaration with `order_status` emits two).
Messages already recorded are not recorded again (API sends, redeliveries).

```jsonc
{
  "type": "OrderState",
  "event": {
    "incoming_message_id": "3EB0C767D26A1D6B8A9F",  // received order message
    "order_id": "1976123456789012",
    "buyer": "5511999999999@s.whatsapp.net",
    "previous_state": "received",
    "previous_payment_status": "",
    "previous_order_status": "",
    "state": "accepted",               // received | accepted | rejected
    "payment_status": "",              // "" | pending | captured | failed
    "order_status": "",                // "" | last lifecycle value (shipped, completed, ...)
    "billing_message_id": "3EB0B1C2D3E4F5A6B7C8",
    "reference_id": "order-2026-0915-001",
    "updated_at": 1790000300,
    "seller_card_state": "local_to_acting_device",
    "change": {
      "event": "accepted",             // received | accepted | rejected | payment_status | order_status
      "value": "",                     // new status, or the order ID for "received"
      "source": "device",              // api | device
      "message_id": "3EB0B1C2D3E4F5A6B7C8",
      "at": 1790000300,
      "note": "out_of_order"           // only when present: out_of_order | backfilled
    }
  }
}
```

API sends follow the transitions (`409 ...; nothing sent`, checked before sending):
a decision only from `received`; payment/status declarations on a billing linked to a
tracked order only when `accepted`, never after `rejected`, `completed` or `canceled`.
Phone actions are never refused; one outside the expected order is recorded with
`note: "out_of_order"`. Standalone charges (`/business/order/charge/send`) are not
tracked. The state is stored in `message_metadata` (kinds `order_state` /
`order_state_ref`), history capped at the last 100 changes.

## Message enrichment keys

These keys are attached to a `type: "Message"` payload, next to `data.event`.
They exist because WhatsApp encrypts polls, calendar RSVPs and edits with the
**message secret of the original message**, and whatsmeow does not decrypt them
for you — without this enrichment the consumer would only see an opaque
envelope. Each key is emitted **only when it applies**, so a plain text message
carries none of them.

### `data.pollVote` — decrypted poll vote

Present on a `Message` whose `data.event.Message.pollUpdateMessage` exists and
whose vote could be decrypted (the poll-creation message secret must be known).

```jsonc
{
  "data": {
    "type": "Message",
    "pollVote": {
      "selectedOptionHashes": ["3fa1c0…", "9be27d…"],  // SHA-256 of each chosen option, hex
      "selectedOptions": ["Pizza", "Sushi"],           // resolved names — see below
      "options": ["Pizza", "Sushi", "Burger"],         // all poll options
      "title": "Dinner tonight?",
      "maxSelectableOptions": 2
    }
  }
}
```

- `selectedOptionHashes` is always present. WhatsApp only transmits hashes.
- `selectedOptions`, `options`, `title` and `maxSelectableOptions` are present
  **only when the poll-creation metadata is known** to this instance (the poll
  was created or seen by it, so its options are cached/persisted). Otherwise the
  key carries just the hashes and the consumer must resolve them itself.
- `selectedOptions` only lists the options whose hash matched — an unmatched
  hash is skipped rather than guessed.
- **A vote retraction** (voter cleared their choice) arrives as
  `"pollVote": { "selectedOptionHashes": [] }` — an empty array and nothing else.

### `data.calendarEvent` — received calendar event

Present on a `Message` carrying an `eventMessage`. `location` is present only
when the event has one.

```jsonc
{
  "data": {
    "type": "Message",
    "calendarEvent": {
      "name": "Sprint review",
      "description": "Demo + retro",
      "startTime": 1752345600,        // unix seconds
      "endTime": 1752352800,
      "joinLink": "https://call.whatsapp.com/video/abc123",
      "isCanceled": false,
      "extraGuestsAllowed": true,
      "isScheduleCall": true,
      "hasReminder": true,
      "reminderOffsetSec": 900,
      "location": {
        "name": "HQ",
        "address": "Av. Paulista, 1000",
        "latitude": -23.5613,
        "longitude": -46.6565
      }
    }
  }
}
```

The event's identity is also persisted, so that a later RSVP — which only
carries the event's message ID — can be reported with the event's name and
schedule instead of an opaque ID (see `data.eventResponse.event`).

### `data.eventResponse` — decrypted RSVP

Present on a `Message` carrying an `encEventResponseMessage` that could be
decrypted. This is the RSVP to a calendar event.

```jsonc
{
  "data": {
    "type": "Message",
    "eventResponse": {
      "eventId": "3EB0C767D26B8F4A1C42",   // message ID of the event-creation message
      "respondedBy": "218937128973128@lid",
      "response": "GOING",                  // UNKNOWN | GOING | NOT_GOING | MAYBE
      "extraGuestCount": 2,
      "timestampMs": 1752345600123,
      "event": {                            // only when the event-creation message was seen
        "name": "Sprint review",
        "description": "Demo + retro",
        "startTime": 1752345600,
        "endTime": 1752352800,
        "joinLink": "https://call.whatsapp.com/video/abc123",
        "location": "HQ",                   // NOTE: a string (the location name), not an object
        "isCanceled": false
      }
    }
  }
}
```

- `response` is the RSVP enum as a string: `UNKNOWN`, `GOING`, `NOT_GOING` or
  `MAYBE`.
- `respondedBy` is the sender's JID as delivered — for a DM this is normally a
  `@lid` (see *LID identity* below).
- The nested `event` object is present **only when the creation message was seen**
  by this instance. Its `location` is the location **name only** (a string) —
  unlike `data.calendarEvent.location`, which is a full object.

### `data.editType` / `data.editTargetId` — message edits

Since ~2026 WhatsApp no longer ships edits as a `protocolMessage` with
`type == 14`. Edits now arrive as a **`SecretEncryptedMessage`**, encrypted with
the *original* message's secret. ZuckZapGo decrypts it and **lifts the decrypted
content to the top of `data.event.Message`**, so a consumer reads the edited text
at `data.event.Message.conversation` exactly like a normal message — there is no
`protocolMessage` wrapper to unwrap.

```jsonc
{
  "data": {
    "type": "Message",
    "editType": "MESSAGE_EDIT",              // see enum below
    "editTargetId": "3EB0C767D26B8F4A1C42",  // ID of the ORIGINAL message being edited
    "event": {
      "Info": {
        "ID": "3EB0C767D26B8F4A1C42",        // realigned to the original message ID
        "…": "…"
      },
      "IsEdit": true,
      "Message": {
        "conversation": "the corrected text"  // the decrypted, edited content — lifted here
      }
    }
  }
}
```

- `editType` ∈ `UNKNOWN` | `EVENT_EDIT` | `MESSAGE_EDIT` | `MESSAGE_SCHEDULE` |
  `POLL_EDIT` | `POLL_ADD_OPTION`.
- `editTargetId` is present when WhatsApp reports a target message key. When it
  is present, `data.event.Info.ID` is **realigned to that original message ID**,
  so the edit keys naturally to the message it replaces.
- `data.event.IsEdit` is set to `true` only for `MESSAGE_EDIT` and `EVENT_EDIT`.
- If decryption fails (the original message's secret is unknown — e.g. the
  original predates this instance), **neither key is emitted** and the raw
  envelope reaches the webhook untouched.

### `data.event_invite` / `data.payment_invite_type`

`data.event_invite` is attached for an `eventInviteMessage` and carries only the
fields WhatsApp actually sent: `event_id`, `title`, `start_time`, `caption`,
`is_canceled`, `thumbnail_b64` (base64 JPEG). `data.payment_invite_type` is the
`PaymentInviteMessage` invite-type enum as a string.

### LID identity

WhatsApp now addresses direct messages by **LID**. On an inbound message,
`data.event.Info.Sender` may therefore be a `<number>@lid` rather than a phone
JID — the phone-shaped JID, when available, is in `data.event.Info.SenderAlt`
(and `RecipientAlt` for the recipient side). Anything that keys on a phone
number should prefer `SenderAlt` and fall back to `Sender`.

### View-once and undecryptable messages

- `data.event.IsViewOnce` marks a view-once message.
- A message this device could not decrypt is emitted as an
  `UndecryptableMessage` event type. ZuckZapGo re-requests it from the primary
  phone (`AutomaticMessageRerequestFromPhone`, disable with
  `GLOBAL_DISABLE_PHONE_REREQUEST=true`), which recovers messages whose
  ciphertext the companion missed. **It does not recover received view-once
  media** — WhatsApp does not deliver that content to companion devices at all,
  by design.

### Contact request (`request_contact_info`) and the shared contact

`POST /chat/send/contact-request` sends the native contact request. No new
event type or key exists for it; everything arrives as a regular `Message`.

- **The request itself** (API echo or another device of the account) is
  `data.event.Message.interactiveMessage`:
  ```json
  {"interactiveMessage": {"body": {"text": "…"}, "contextInfo": {},
    "InteractiveMessage": {"NativeFlowMessage": {"buttons": [{"name": "request_contact_info"}]}}}}
  ```
  The same shape arrives when a business sends one to this account.
- **The answer**, when the contact taps "Share contact", is
  `data.event.Message.contactMessage` with `isSelfContact: true` and a vCard
  carrying `TEL;…;waid=<phone>:+<formatted>` and `X-WA-LID:<lid>`:
  ```json
  {"contactMessage": {"displayName": "…", "vcard": "BEGIN:VCARD\n…\nTEL;type=Celular;waid=5511999990000:+55 11 99999-0000\nX-WA-LID:100000000000001\nEND:VCARD",
    "contextInfo": {"expiration": 0, "…": "…"}, "isSelfContact": true}}
  ```
  It has **no `stanzaID`**: nothing links it to the request. Correlate by chat,
  never by timing alone. `isSelfContact` is provenance from WhatsApp, not an
  identity verification.
- Delivery/read receipts for the request id arrive as the usual `ReadReceipt`
  events; the gateway also uses them to mark the request `confirmed` for retries.
- **Native phone-number sharing (`ProtocolMessage` `SHARE_PHONE_NUMBER`, the
  username-era flow) is not sent by this gateway and has never been captured
  live.** If one arrives, nothing filters it: the library dispatches every
  decrypted message as `events.Message`, and the gateway emits it as
  `data.event.Message = {"protocolMessage": {"type": 11}}`, with no payload. Any
  phone number would only be in `data.event.Info.SenderAlt` if the stanza carried
  it. Do not depend on it until a live capture shows its real shape.

## Backward compatibility

- No existing key is renamed or removed.
- No event type stopped being emitted.
- All additions are new, optional keys inside `data` (`v1`, `pollVote`,
  `calendarEvent`, `eventResponse`, `editType`/`editTargetId`, `event_invite`,
  `payment_invite_type`).
- A strict consumer that validates an exact key set should treat every key above
  as optional and ignorable.

## See also

- `docs/whatsapp-web-call-integration.md` — call control and the native calls engine (the Spec 005 sidecar was removed).
- `static/api/spec.yml` — full OpenAPI surface for the new endpoints.

## Contrato de saída por transporte — global e individual

Este guia cobre o evento lógico **P** produzido pelo gateway e o envelope **E** de cada saída. Primeiro decodifique o transporte, depois obtenha P. `E.eventType`, `P.type` e `P.v1.event` são discriminadores diferentes: respectivamente tipo de entrega, tipo legado e nome enriquecido versionado. Não trate `Message`, `v1.order.received` e um recibo como três mensagens de texto.

### Matriz de codecs, escopo e caminhos

| Saída | Escopo existente | Decodificação | Evento P | ID de entrega | Relógio externo |
|---|---|---|---|---|---|
| Webhook HTTP | Individual | Body JSON UTF-8 | `E.data` | Header `X-Event-ID` | `timestamp`: Unix **segundos**, criação do envelope |
| Webhook HTTP | Global | Body JSON UTF-8 | `E.data` | Header `X-Event-ID` | `timestamp`: Unix **segundos**, tentativa de entrega |
| RabbitMQ | Individual | AMQP body JSON UTF-8 | `E.data` | Propriedade AMQP `message_id` | `timestamp`: Unix segundos, criação do envelope |
| RabbitMQ | Global | AMQP body JSON UTF-8 | `E.data` | Propriedade AMQP `message_id` | `timestamp`: Unix segundos, tentativa de publish |
| Amazon SQS | Global | `json.loads(Message.Body)` | `E.payload` | `E.id`; não confundir com SQS MessageId/ReceiptHandle | `createdAt`: Unix **nanossegundos**, inteiro64 |
| WebSocket de eventos | Global | Frame **text** contendo JSON UTF-8 | `E.payload` | `E.id` | `createdAt`: Unix nanossegundos, inteiro64 |
| Redis Streams | Global | `entry.fields["payload"]` é **bytes MessagePack**; decodifique o objeto E | `E.payload` após MessagePack | `E.id`; ID da entrada Redis é outro identificador | `createdAt`: Unix nanossegundos, inteiro64 |

A escolha de eventos é sensível a maiúsculas/minúsculas: use `Message,ReadReceipt,CallOffer,QR` ou `All`, não `message,call,qr`. O nome cadastrado Receipt não é traduzido automaticamente para ReadReceipt pelo filtro individual atual.

No caminho bufferizado Redis, `P.event` pode ser **outro binário contendo JSON**, restaurado de json.RawMessage antes da serialização MessagePack. Depois de MessagePack, se event for bytes, faça JSON decode desse campo; se já for objeto/string, preserve-o. Não decodifique base64/mídia por engano nem execute decode JSON recursivo em todas as strings.

No Redis, os outros campos da entrada são `event` (tipo) e `userID`; eles não contêm o enriquecimento. Não faça JSON.parse nos bytes MessagePack, não chame o próprio campo binário de evento bruto e não perca bytes convertendo a resposta Redis para texto. Use cliente com resposta binária e decoder MessagePack com chaves string (`raw=False` no pacote Python msgpack). A biblioteca/versão do cliente pertence ao seu aplicativo; este guia não instala dependências.

Não há transporte WebSocket/SQS/Redis individual registrado no fan-out atual. A inscrição é por eventos e existem flags por usuário para **pular** destinos globais; isso não transforma um destino global em individual. S3 é armazenamento de anexos, não uma fila de envelopes. O SSE administrativo de monitoramento e o stream PCM/H.264 de chamadas têm contratos próprios e não substituem este fluxo.

O WebSocket global é **saída ativa**: o gateway conecta aos endpoints de `GLOBAL_WEBSOCKET_ENDPOINTS` e envia frames. O integrador hospeda um servidor receptor; não é uma rota genérica de subscribe no gateway. `/call/{call_id}/stream` transporta mídia, não esses envelopes.

### Campos externos exatos

Todos os envelopes de fan-out abaixo levam `userID`, `eventType`, `userName`, `userJID`, `baseURL` e o evento P. Valores de nome/JID podem estar vazios antes do pareamento. Campos adicionais por serializador:

| Serializador | Campos adicionais (além dos comuns) |
|---|---|
| Webhook individual | `token`, `pushName`, `businessName`, `timestamp`, `data` |
| Webhook global | `userToken`, `pushName`, `businessName`, `timestamp`, `source`, `data` |
| RabbitMQ individual, caminho EventEnvelope | `userToken`, `pushName`, `businessName`, `timestamp`, `queueName`, `data` |
| RabbitMQ global | `userToken`, `timestamp`, `source`, `data`, `metadata:{connectionIdx,queueName,dynamicQueue}`; não acrescenta pushName/businessName ao body |
| SQS/WebSocket globais | `id`, `userToken`, `pushName`, `businessName`, `payload`, `createdAt`, `metadata` opcional |
| Redis global, objeto MessagePack E | os mesmos campos lógicos de SQS/WebSocket, codificados em MessagePack |

O caminho legado de publicação direta RabbitMQ não inclui pushName/businessName; consumidores aceitam sua ausência. O objeto Go interno `EventEnvelope` contém `payload`, `metadata` e `createdAt` time.Time, mas **não é o JSON wire universal**: cada serializador acima escolhe seus campos e unidades. Não publique um schema único que exija `data` ou `payload` em todos os transportes.

`token`/`userToken` são credenciais reais em entregas autenticadas existentes. Não envie o envelope inteiro a logs, analytics ou outro tenant. Autentique o receptor, restrinja broker/stream e armazene raw com controle de acesso e retenção. O valor de source no webhook global desta distribuição é `zuckzapgo-global`. `source` identifica a distribuição do gateway e não prova autenticidade. Metadados AMQP/SQS, `userID` e o texto do evento são dados recebidos, não autorização para ações administrativas.

- HTTP individual/global: `Content-Type: application/json`; ID no header, não obrigatoriamente no body. Primary e fallback individuais mantêm o ID daquela entrega.
- AMQP: `content_type=application/json`, `type=eventType`, `message_id` e headers de identidade/roteamento. Global inclui source/connectionIdx/queueName/dynamicQueue/authenticatedUser; individual inclui queueName/attempt. Não use nome de fila nem routing key como identificador de mensagem.
- SQS: MessageAttributes `EventType`, `UserID`, `DedupKey` quando disponível; FIFO usa MessageGroupId configurado ou userID, e MessageDeduplicationId do envelope (fallback gerado quando vazio). ReceiptHandle serve para DeleteMessage, não para identidade de negócio.
- `metadata` em SQS/WS/Redis conserva metadados de transporte sanitizados (exclui a cópia interna de JSON persistido). Campos como source, hasS3Attachment e dedupKey dependem da origem; não são todos obrigatórios. RabbitMQ global monta outro metadata de roteamento.

### Exemplo do mesmo evento lógico em cada família

Exemplos sintéticos, não capturas de WhatsApp. Campos opcionais foram reduzidos para leitura; não são schemas fechados.

```json
{"userID":"instance-example","eventType":"Message","timestamp":1790000000,"data":{"type":"Message","event":{"Info":{"ID":"MESSAGE_EXAMPLE","Chat":"100000000000001@lid","Sender":"100000000000001@lid","IsFromMe":false},"Message":{"conversation":"Olá"}},"customFutureField":{"preserved":true}}}
```

Webhook/RabbitMQ usam essa família `data`. Para identificar a entrega, o receptor passa também o header X-Event-ID ou message_id AMQP ao normalizador. Campos de credencial foram omitidos do exemplo.

```json
{"id":"delivery-example","userID":"instance-example","eventType":"Message","createdAt":1790000000123456789,"payload":{"type":"Message","event":{"Info":{"ID":"MESSAGE_EXAMPLE"},"Message":{"conversation":"Olá"}}},"metadata":{"source":"gateway"}}
```

SQS/WS usam esse JSON; Redis contém esse **objeto lógico** após MessagePack, dentro do campo binário `payload` da entrada. Sua forma textual aqui é só uma representação para leitura.

### Entrega, ACK, filtros e deduplicação

1. Configure o destino e suas assinaturas (`All` é seletor, não evento de negócio). O webhook individual usa inscrição da sessão; RabbitMQ individual tem sua própria lista; cada saída global tem `GLOBAL_*_EVENTS`. Confira também flags skip globais/por usuário, mídia e echo API. Inscrição aceita não garante que a conta/WhatsApp emita aquele evento.
2. Persistência, retries, timeout, replay e fallback permitem duplicatas. Não há garantia geral de exatamente uma vez ou ordem total entre transportes/instâncias. Global e individual podem chegar juntos.
3. IDs de entrega são estáveis para uma entrega persistida/retry, mas IDs de transportes diferentes podem ser gerados separadamente quando o produtor não fornece um ID comum. O engine de chamadas fornece IDs estáveis específicos; não generalize isso para todos os eventos.
4. Mantenha inbox durável com chave `(tenant, transport, deliveryId)` quando o ID existir, e chave de negócio apropriada à operação quando precisar reconciliar global/individual. Para Message, combine instância/chat/Info.ID e a ação (nova/edição/reação/etc). Para Receipt, inclua MessageIDs, remetente, Type/state e tempo; só MessageID apagaria transições delivered/read. Para call, preserve CallID e tipo/estágio. Nunca use timestamp externo sozinho para deduplicar.
5. Webhook: devolva 2xx **após** a admissão durável; se processamento de negócio for assíncrono, use fila/outbox local. RabbitMQ: ACK manual após commit local; falha deve ir para retry/quarentena limitada. SQS: DeleteMessage após commit e ajuste visibility timeout. Redis: consumer group + XACK após commit, monitore pending e reclamation; trimming pode remover entradas antes do consumo.
6. WS: o envio global atual considera sucesso se **pelo menos um** endpoint recebeu a escrita; uma falha em outro endpoint não garante replay exclusivo para ele. WriteMessage bem-sucedido não é um ACK do seu banco ou da regra de negócio. O transporte atual não implementa ACK aplicativo/replay pelo cliente. Se precisar de entrega reconciliável, use webhook/broker persistente e reconciliação; não invente um protocolo ACK que o produtor não lê.
7. Erros de schema, evento desconhecido e enrichment indisponível vão para quarentena com limites/alertas; nunca descarte silenciosamente nem reenvie uma ação WhatsApp para "testar" o recebimento.

### Contrato do payload P

| Campo | Tipo e significado |
|---|---|
| `type` | string legado; geralmente corresponde a E.eventType |
| `event` | valor bruto serializado: normalmente objeto, mas QR/passkey podem trazer string; pode conter subobjetos protobuf variáveis |
| `v1` | objeto opcional: schema_version string, event string, instance_id string, ts RFC3339Nano quando conhecido, data objeto; o schema_version não é a versão do produto |
| `pollVote` | objeto opcional; selectedOptionHashes array de hex; nomes/title/options/maxSelectableOptions dependem da metadata da criação |
| `calendarEvent` | objeto opcional; nome/descrição, tempos Unix segundos, flags, joinLink e location objeto opcional |
| `eventResponse` | objeto opcional; eventId, respondedBy, response enum, extraGuestCount, timestampMs inteiro; event contextual opcional e location string |
| `editType`, `editTargetId` | strings opcionais; edição decifrada e alvo original; não transforme edição em novo envio |
| `event_invite`, `payment_invite_type` | objeto observado de convite e string enum de convite de pagamento |
| `base64`, `mimeType`, `fileName` | strings opcionais de mídia; podem ser ausentes conforme modo/configuração/erro de download |
| `s3` | objeto de mídia: url, key, bucket, size inteiro em bytes, mimeType, fileName; use key para identidade e respeite expiração/permissão da URL |
| `mediaUnavailable`, `mediaError`, `mediaErrorType` | bool/string/string opcionais; ex. media_expired_on_cdn, sem inventar conteúdo recuperado |
| `state` | string adicional em ReadReceipt/Presence, não estado universal de qualquer evento |
| campos adicionais do catálogo | específicos do evento; mantenha desconhecidos para evolução aditiva |

Ausente, null, string vazia e array vazio têm significados distintos. `pollVote.selectedOptionHashes:[]` pode ser retirada do voto. Não substitua campos ausentes por dados adivinhados. Nos eventos JSON/JIDs restaurados de JSON, JIDs são strings opacas com server e podem ser LID; não os converta obrigatoriamente em telefone. Respeite a capitalização: `event.Info.ID` não é `event.info.id`; nomes Go e protobuf coexistem.

A versão rica de API echo usa `event.Info.IsFromAPI:true`, mantendo IsFromMe; isso indica origem API, não confirmação de entrega/leitura. Eventos reais podem ter IsAssociatedChild, enquanto o DTO de echo não inclui esse campo. Preserve Message/RawMessage e wrappers conforme o payload recebido.



### Campos incorporados e identidade da mensagem

- `MessageSource` é incorporado em Info e em Receipt/ChatPresence: Chat, Sender, IsFromMe, IsGroup, AddressingMode, SenderAlt, RecipientAlt, BroadcastListOwner, BroadcastRecipients[]. JIDs serializados são strings; não são o telefone garantido da pessoa.
- `MessageInfo`: campos incorporados de MessageSource mais ID, ServerID, Type, PushName, Timestamp, Category, Multicast, MediaType, Edit, MsgBotInfo, MsgMetaInfo, IsNewsletterStatus, VerifiedName e DeviceSentMeta. `Info.IsFromAPI` é adicionado pelo DTO de echo API. Valores opcionais/ponteiros podem estar null; não assuma que todos estão preenchidos.
- `BasicCallMeta`: From, Timestamp, CallCreator, CallCreatorAlt, CallID, GroupJID. `CallRemoteMeta`: RemotePlatform, RemoteVersion. Campos enriquecidos caller_phone/caller_lid podem complementar a identidade, sem substituir os JIDs brutos.
- `AppState` incorpora SyncActionValue: o tipo de action define quais subobjetos existem; não o interprete como uma mensagem de texto. GroupInfo/JoinedGroup incorporam metadados de grupo e pointers de alterações, não um snapshot invariavelmente completo.
- Mensagens interativas, contatos, listas, carrosséis, reação, localização, pedidos e revoke aparecem dentro de variantes de `event.Message`. Revoke não exige um novo eventType: pode ser Message/protocolMessage. Preserve IDs alvos e diferencie nova mensagem, edição e ação sobre outra mensagem.
- Eventos de teste/health podem não ter userID/type/data completos (`eventType:test`, por exemplo). Direcione-os para handler de probe antes do normalizador de eventos de instância; não use um probe como fixture que prova a forma de todos os eventos reais.

### Catálogo completo de nomes aceitos nesta distribuição

A lista inclui nomes cadastrados, aliases e seletores; a coluna de emissão evita prometer callbacks inexistentes. `event` bruto conserva chaves com capitalização original. `embed` indica campos incorporados em Go (flatten na serialização conforme seus tags), não uma chave JSON chamada embed. Os tipos abaixo são descritores da implementação; ponteiros podem ser null, slices podem ser null/arrays e time.Time serializa RFC3339. Protobuf/SyncActionValue/waBinary.Node são estruturas variáveis: preserve-as; os campos de primeiro nível não representam validação recursiva fechada desses subobjetos.

| Nome de inscrição | Emissão / campos P adicionais | Estrutura de P.event (primeiro nível) |
|---|---|---|
| `Message` | P pode ter todos os enriquecimentos descritos neste guia; echo API tem DTO próprio | `Info: types.MessageInfo; Message: *waE2E.Message; IsEphemeral: bool; IsViewOnce: bool; IsViewOnceV2: bool; IsViewOnceV2Extension: bool; IsDocumentWithCaption: bool; IsLottieSticker: bool; IsBotInvoke: bool; IsEdit: bool; IsAssociatedChild: bool; SourceWebMsg: *waWeb.WebMessageInfo; UnavailableRequestID: types.MessageID; RetryCount: int; NewsletterMeta: *NewsletterMessageMeta; RawMessage: *waE2E.Message` |
| `UndecryptableMessage` | Message that couldn't be decrypted | `Info: types.MessageInfo; IsUnavailable: bool; UnavailableType: UnavailableType; DecryptFailMode: DecryptFailMode` |
| `FBMessage` | Facebook/Instagram message | `Info: types.MessageInfo; Message: armadillo.MessageApplicationSub; RetryCount: int; Transport: *waMsgTransport.MessageTransport; FBApplication: *waMsgApplication.MessageApplication; IGTransport: *instamadilloTransportPayload.TransportPayload` |
| `Receipt` | nome cadastrado, mas este emitter produz ReadReceipt; use inscrição ReadReceipt ou All | `embed types.MessageSource; MessageIDs: []types.MessageID; Timestamp: time.Time; Type: types.ReceiptType; MessageSender: types.JID` |
| `MediaRetry` | Media download retry | `Ciphertext: []byte; IV: []byte; Error: *MediaRetryError; Timestamp: time.Time; MessageID: types.MessageID; ChatID: types.JID; SenderID: types.JID; FromMe: bool` |
| `ReadReceipt` | emitido por events.Receipt; P.state=Read/ReadSelf/Delivered/Unknown-* | `embed types.MessageSource; MessageIDs: []types.MessageID; Timestamp: time.Time; Type: types.ReceiptType; MessageSender: types.JID` |
| `Star` | Message starred/unstarred | `ChatJID: types.JID; SenderJID: types.JID; IsFromMe: bool; MessageID: string; Timestamp: time.Time; Action: *waSyncAction.StarAction; FromFullSync: bool` |
| `Pin` | P.chatJid, timestamp RFC3339Nano, fromFullSync bool, pinned bool ou null | `JID: types.JID; Timestamp: time.Time; Action: *waSyncAction.PinAction; FromFullSync: bool` |
| `Archive` | Chat archived/unarchived | `JID: types.JID; Timestamp: time.Time; Action: *waSyncAction.ArchiveChatAction; FromFullSync: bool` |
| `Mute` | Chat muted/unmuted | `JID: types.JID; Timestamp: time.Time; Action: *waSyncAction.MuteAction; FromFullSync: bool` |
| `MarkChatAsRead` | Entire chat marked as read | `JID: types.JID; Timestamp: time.Time; Action: *waSyncAction.MarkChatAsReadAction; FromFullSync: bool` |
| `ClearChat` | Chat cleared (messages deleted locally) | `JID: types.JID; Timestamp: time.Time; Action: *waSyncAction.ClearChatAction; FromFullSync: bool; DeleteMedia: bool` |
| `DeleteChat` | Chat deleted | `JID: types.JID; Timestamp: time.Time; Action: *waSyncAction.DeleteChatAction; FromFullSync: bool; DeleteMedia: bool` |
| `DeleteForMe` | Message deleted for current user | `ChatJID: types.JID; SenderJID: types.JID; IsFromMe: bool; MessageID: string; Timestamp: time.Time; Action: *waSyncAction.DeleteMessageForMeAction; FromFullSync: bool` |
| `LabelAssociationChat` | Chat labeled/unlabeled | `JID: types.JID; Timestamp: time.Time; LabelID: string; Action: *waSyncAction.LabelAssociationAction; FromFullSync: bool` |
| `LabelAssociationMessage` | Message labeled/unlabeled | `JID: types.JID; Timestamp: time.Time; LabelID: string; MessageID: string; Action: *waSyncAction.LabelAssociationAction; FromFullSync: bool` |
| `LabelEdit` | Label edited | `Timestamp: time.Time; LabelID: string; Action: *waSyncAction.LabelEditAction; FromFullSync: bool` |
| `GroupInfo` | Group information changed | `JID: types.JID; Notify: string; Sender: *types.JID; SenderPN: *types.JID; Timestamp: time.Time; Name: *types.GroupName; Topic: *types.GroupTopic; Locked: *types.GroupLocked; Announce: *types.GroupAnnounce; Ephemeral: *types.GroupEphemeral; MembershipApprovalMode: *types.GroupMembershipApprovalMode; Delete: *types.GroupDelete; Link: *types.GroupLinkChange; Unlink: *types.GroupLinkChange; NewInviteLink: *string; PrevParticipantVersionID: string; ParticipantVersionID: string; JoinReason: string; Join: []types.JID; Leave: []types.JID; Promote: []types.JID; Demote: []types.JID; MembershipRequestsCreated: []types.JID; MembershipRequestsRevoked: []types.JID; MembershipRequestMethod: string; Suspended: bool; Unsuspended: bool; UnknownChanges: []*waBinary.Node` |
| `JoinedGroup` | User joined a group | `Reason: string; Type: string; CreateKey: types.MessageID; Sender: *types.JID; SenderPN: *types.JID; Notify: string; embed types.GroupInfo` |
| `Contact` | Contact modified | `JID: types.JID; Timestamp: time.Time; Action: *waSyncAction.ContactAction; FromFullSync: bool` |
| `Picture` | Profile picture changed | `JID: types.JID; Author: types.JID; Timestamp: time.Time; Remove: bool; PictureID: string` |
| `PushName` | Contact name changed | `JID: types.JID; JIDAlt: types.JID; Message: *types.MessageInfo; OldPushName: string; NewPushName: string` |
| `BusinessName` | P.jid, oldBusinessName, newBusinessName strings | `JID: types.JID; Message: *types.MessageInfo; OldBusinessName: string; NewBusinessName: string` |
| `UserAbout` | User status/about changed | `JID: types.JID; Status: string; Timestamp: time.Time` |
| `PrivacySettings` | Privacy settings changed | `NewSettings: types.PrivacySettings; GroupAddChanged: bool; LastSeenChanged: bool; StatusChanged: bool; ProfileChanged: bool; ReadReceiptsChanged: bool; OnlineChanged: bool; CallAddChanged: bool; MessagesChanged: bool; DefenseChanged: bool; StickersChanged: bool` |
| `IdentityChange` | Identity key changed | `JID: types.JID; Timestamp: time.Time; Implicit: bool` |
| `Blocklist` | Blocklist updated | `Action: BlocklistAction; DHash: string; PrevDHash: string; Changes: []BlocklistChange` |
| `BlocklistChange` | Contact blocked/unblocked | `JID: types.JID; Action: BlocklistChangeAction` |
| `UserStatusMute` | User status muted | `JID: types.JID; Timestamp: time.Time; Action: *waSyncAction.UserStatusMuteAction; FromFullSync: bool` |
| `Connected` | Client connected and authenticated | `custom conforme coluna anterior` |
| `Disconnected` | Client disconnected | `custom conforme coluna anterior` |
| `QR` | canal QR: event string, qrCodeBase64 e code; raw events.QR pode trazer codes[] | `Codes: []string` |
| `PairSuccess` | cadastrado; handler atual só atualiza store/cache, sem dowebhook=1; não espere callback garantido | `ID: types.JID; LID: types.JID; BusinessName: string; Platform: string; Props: *waCompanionReg.ClientPairingProps` |
| `PairError` | Error during pairing | `ID: types.JID; LID: types.JID; BusinessName: string; Platform: string; Props: *waCompanionReg.ClientPairingProps; Error: error` |
| `QRScannedWithoutMultidevice` | QR scanned without multidevice enabled | `custom conforme coluna anterior` |
| `LoggedOut` | Logged out from device | `OnConnect: bool; Reason: ConnectFailureReason` |
| `StreamReplaced` | Stream replaced by new connection | `custom conforme coluna anterior` |
| `StreamError` | WebSocket stream error | `Code: string; Raw: *waBinary.Node` |
| `ConnectFailure` | Connection failure | `Reason: ConnectFailureReason; Message: string; Raw: *waBinary.Node` |
| `KeepAliveTimeout` | Keepalive ping timeout | `ErrorCount: int; LastSuccess: time.Time` |
| `KeepAliveRestored` | Keepalive restored after timeout | `custom conforme coluna anterior` |
| `ManualLoginReconnect` | Manual reconnection required | `custom conforme coluna anterior` |
| `TemporaryBan` | Account temporarily banned | `Code: TempBanReason; Expire: time.Duration` |
| `ClientOutdated` | Client version outdated | `custom conforme coluna anterior` |
| `CATRefreshError` | CAT token refresh error | `Error: error` |
| `CallOffer` | Call received (1:1) | `embed types.BasicCallMeta; embed types.CallRemoteMeta; Data: *waBinary.Node` |
| `CallAccept` | Call accepted by WhatsApp signaling | `embed types.BasicCallMeta; embed types.CallRemoteMeta; Data: *waBinary.Node` |
| `CallAcceptEngine` | event={CallID}; mídia pronta, não confundir com CallAccept | `custom` |
| `CallPreAccept` | Call pre-acceptance | `embed types.BasicCallMeta; embed types.CallRemoteMeta; Data: *waBinary.Node` |
| `CallTransport` | Call transport information | `embed types.BasicCallMeta; embed types.CallRemoteMeta; Data: *waBinary.Node` |
| `CallTerminate` | Call terminated by WhatsApp signaling | `embed types.BasicCallMeta; Reason: string; Data: *waBinary.Node` |
| `CallTerminateEngine` | event={CallID,Reason?} | `custom` |
| `CallRecordingReady` | event={CallID,MediaKey}; chave do objeto, não exigir URL | `custom` |
| `CallRecordingStopped` | event={CallID,RecordingID,Reason?}; chamada pode continuar | `custom` |
| `CallReject` | Call rejected | `embed types.BasicCallMeta; Data: *waBinary.Node` |
| `CallOfferNotice` | Call notification (group calls) | `embed types.BasicCallMeta; Media: string; Type: string; Data: *waBinary.Node` |
| `CallRelayLatency` | Call latency information | `embed types.BasicCallMeta; Data: *waBinary.Node` |
| `CallReminder` | A call link we created was opened and started by someone else | `embed types.BasicCallMeta; Type: string; LinkToken: string; Media: string; Data: *waBinary.Node` |
| `CallLog` | objeto custom do log do telefone + v1.call.log; campos descritos acima | `custom` |
| `UnknownCallEvent` | Unknown call event | `Node: *waBinary.Node` |
| `Presence` | P.state=online/offline | `From: types.JID; Unavailable: bool; LastSeen: time.Time` |
| `ChatPresence` | User typing/recording in chat | `embed types.MessageSource; State: types.ChatPresence; Media: types.ChatPresenceMedia` |
| `NewsletterJoin` | Joined newsletter | `embed types.NewsletterMetadata` |
| `NewsletterLeave` | Left newsletter | `id: types.JID; role: types.NewsletterRole` |
| `NewsletterMuteChange` | Newsletter muted/unmuted | `id: types.JID; mute: types.NewsletterMuteState` |
| `NewsletterLiveUpdate` | Newsletter live update | `JID: types.JID; Time: time.Time; Messages: []*types.NewsletterMessage` |
| `AppState` | App state data received | `Index: []string; embed *waSyncAction.SyncActionValue` |
| `AppStateSyncComplete` | P.name:string, version:uint64, recovery:bool | `Name: appstate.WAPatchName; Version: uint64; Recovery: bool` |
| `AppStateSyncError` | P.name:string, error:string, full_sync:bool; raw Error pode serializar objeto vazio | `Name: appstate.WAPatchName; Error: error; FullSync: bool` |
| `HistorySync` | History synchronized | `Data: *waHistorySync.HistorySync; Notification: *waE2E.HistorySyncNotification; MessageID: types.MessageID` |
| `OfflineSyncPreview` | Offline sync preview | `Total: int; AppDataChanges: int; Messages: int; Notifications: int; Receipts: int` |
| `OfflineSyncCompleted` | Offline sync completed | `Count: int` |
| `PushNameSetting` | Push name setting changed | `Timestamp: time.Time; Action: *waSyncAction.PushNameSetting; FromFullSync: bool` |
| `UnarchiveChatsSetting` | Unarchive chats setting changed | `Timestamp: time.Time; Action: *waSyncAction.UnarchiveChatsSetting; FromFullSync: bool` |
| `OrderState` | objeto custom de transição; campos completos já descritos neste guia | `custom` |
| `PasskeyRequest` | event string; publicKey opcional, opções WebAuthn do titular | `custom` |
| `PasskeyConfirmation` | event string; code e skipHandoffUX opcionais | `custom` |
| `All` | seletor, não emitido | `—` |

### Contrato versionado adicional de pedidos e chamadas

Além das tabelas v1 já presentes neste guia:

- `CallReminder` leva `v1.call.link_started`: call_id, call_creator, from, reminder_type, link_token, media, timestamp_unix_ms e raw_xml. Link token é material de convite; trate-o como acesso ao link.
- `v1.order.received` só publica campos observados; item_count/total/currency/business_jid/order_id/customer_jid/ts podem ser omitidos quando ausentes. Pode acrescentar catalog_order_status, catalog_order_status_raw, order_surface e order_surface_raw; products pode estar null e enrichment_error ser not_requested. `total` mantém a unidade do protocolo totalAmount1000; não assuma unidades monetárias inteiras.
- `v1.order.lifecycle` descreve **declaração observada**, não liquidação confirmada: message_id, observed_claim:true, message_direction, sender_jid/chat_jid quando conhecidos; reference_id/source/order_status/payment_status/payment_method e flags *_known quando presentes. Payload inválido preserva raw e enrichment_error=invalid_order_lifecycle_payload. Se já havia v1, os dados podem ficar em `v1.order_lifecycle` em vez de substituir o envelope.
- `CallAcceptEngine`/`CallTerminateEngine`/`CallRecordingReady`/`CallRecordingStopped` são eventos próprios de mídia, sem obrigação de v1. Não equipare CallAccept sinalizado a áudio recebido. CallLog é sync do telefone; Duration bruto é segundos e duration_ms enriquecido é milissegundos.
- Horário de entrega (timestamp/createdAt) difere do horário da mensagem/evento. Preserve os dois; não substitua Info.Timestamp pelo horário do consumidor.

### Normalizador de referência para seu integrador

Não existe um serviço adicional obrigatório de "mapeamento" nesta entrega. Você pode usar o código abaixo na borda de seu próprio gateway/inbox. Ele não abre porta, não faz chamada WhatsApp, não envia evento e não dá ACK: a integração com HTTP/broker, autenticação, limites de tamanho, inbox transacional, deduplicação e quarentena fica com seu aplicativo.

Copie o bloco para `event_mapper.py`. Decodifique o wire **antes** de chamá-lo: HTTP/AMQP/WS usam json.loads no body/frame; SQS json.loads no Body; Redis usa decoder MessagePack no campo binário payload (por exemplo msgpack.unpackb(bytes, raw=False)). Passe transport explicitamente; não tente adivinhar o codec olhando só uma chave chamada payload.

```python
import json

DATA_TRANSPORTS = {"webhook-individual", "webhook-global", "rabbitmq-individual", "rabbitmq-global"}
PAYLOAD_TRANSPORTS = {"sqs-global", "websocket-global", "redis-global"}

def normalize_event(transport, envelope, delivery_id=None):
    """Receive an already decoded envelope. No network, sends or ACKs here."""
    if transport not in DATA_TRANSPORTS | PAYLOAD_TRANSPORTS:
        raise ValueError("unsupported transport")
    if not isinstance(envelope, dict):
        raise ValueError("envelope must be an object")
    field = "data" if transport in DATA_TRANSPORTS else "payload"
    payload = envelope.get(field)
    if not isinstance(payload, dict):
        raise ValueError("missing event payload")
    # Buffered Redis delivery can carry event as JSON bytes (json.RawMessage).
    if transport == "redis-global" and isinstance(payload.get("event"), (bytes, bytearray)):
        payload = dict(payload)
        payload["event"] = json.loads(payload["event"])
    event_type = envelope.get("eventType")
    if not isinstance(event_type, str) or not event_type:
        raise ValueError("missing eventType; route probes separately")
    if payload.get("type") is not None and payload["type"] != event_type:
        raise ValueError("eventType/type mismatch; quarantine without ACK")
    instance = envelope.get("userID")
    if not isinstance(instance, str) or not instance:
        raise ValueError("missing instance identity")
    time_field = "timestamp" if transport in DATA_TRANSPORTS else "createdAt"
    stamp = envelope.get(time_field)
    if isinstance(stamp, bool) or not isinstance(stamp, int):
        raise ValueError("timestamp must be an integer in the transport unit")
    # Python json.loads retains int64 precision; never pass through float.
    nanoseconds = stamp * 1_000_000_000 if time_field == "timestamp" else stamp
    event_id = envelope.get("id") or delivery_id
    if event_id is not None and (not isinstance(event_id, str) or not event_id):
        raise ValueError("invalid delivery identifier")
    v1 = payload.get("v1")
    return {
        "mappingVersion": "1",
        "transport": transport,
        "instanceId": instance,
        "eventType": event_type,
        "deliveryId": event_id,  # None is allowed; do not invent a dedup identity.
        "deliveryTimeUnixNs": str(nanoseconds),  # safe for downstream JS consumers
        "payload": payload,  # retain all enrichments and unknown future keys
        "rawEvent": payload.get("event"),  # object, string, null or another raw shape
        "enrichment": v1,  # preserve even unknown schema_version for quarantine/routing
    }
```

Exemplo de uso após HTTP: `normalize_event("webhook-individual", json.loads(body), delivery_id=headers.get("X-Event-ID"))`. Após AMQP, passe o message_id; SQS/WS/Redis já carregam id em E. Os nomes de parâmetros body/headers são os do seu framework, não globais fornecidos pelo gateway.

O resultado é um modelo **local**, não uma nova versão do wire ZuckZapGo: mappingVersion, transport, instanceId, eventType, deliveryId opcional, deliveryTimeUnixNs string decimal, payload completo, rawEvent e enrichment. Payload pode conter dados pessoais/segredos; ele não é um objeto seguro para log. Unknown schema_version deve ter handler/quarentena, não ser silenciosamente tratado como "1". Não escolha automaticamente v1.data no lugar de payload: isso eliminaria campos legados e enriquecimentos irmãos.

```python
# Exercício local sem rede: payload desconhecido não é descartado e ns não arredonda.
p = {"type": "Message", "event": {"Info": {"ID": "example"}}, "future": {"kept": True}}
n = normalize_event("sqs-global", {"id": "delivery-example", "userID": "instance-example", "eventType": "Message", "createdAt": 1790000000123456789, "payload": p})
assert n["deliveryTimeUnixNs"] == "1790000000123456789"
assert n["payload"]["future"]["kept"] is True
assert normalize_event("webhook-individual", {"userID": "instance-example", "eventType": "Message", "timestamp": 1790000000, "data": p}, "header-example")["deliveryId"] == "header-example"
```

### Como validar seu receptor antes de produção

Cubra os sete perfis de transporte com uma fixture conhecida; valide body vazio, JSON inválido, MessagePack inválido/binário, limite de tamanho, identidade ausente, type divergente, evento novo, campo opcional ausente/null, array vazio, int64 com nanossegundos, dois tenants, duplicata, replay, inversão de ordem, falha antes/depois do commit e recuperação da pending/DLQ. Não ACK antes do armazenamento durável. Redija logs por whitelist de campos sem token/QR/passkey/conteúdo de mensagem.

Catálogo e campos abaixo vêm da implementação da distribuição documentada, não de uma captura real de todos os eventos. Uma conta pode não produzir alguns tipos; os campos protobuf internos seguem as mensagens efetivamente recebidas. Nenhum schema fechado deve rejeitar novas propriedades. Use OpenAPI para configuração dos endpoints; ele não substitui o contrato de eventos de saída. Não há certificação de tráfego real por todos os brokers apenas por executar os exemplos deste guia.

### JSON Schema copiável do envelope decodificado

Este schema de compatibilidade cobre as famílias de envelope e os campos estáveis enriquecidos. Ele é **aberto**, não uma especificação fechada de todos os protobufs de WhatsApp. Os campos de calendário/RSVP/convite/pedidos são detalhados nas seções próprias; subobjetos raw continuam preservados. Selecione o `$defs` do transporte conhecido; `anyOf` na raiz aceita famílias que têm campos em comum. Redis só pode ser validado **após** MessagePack. Não valide a entrada bruta Redis como se fosse este JSON. Headers/AMQP properties ficam fora do schema do body.

`v1.ts` é opcional para origens sem horário conhecido. Credenciais são opcionais no schema de compatibilidade para aceitar fixtures sanitizadas e produtores legados; a presença em produção depende do serializador descrito na matriz, não de uma autorização dada pelo schema. Eventos novos continuam permitidos como string, sem enum fechado. Use os nomes do catálogo para roteamento/alertas e preserve desconhecidos.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Decoded outbound event envelope compatibility schema",
  "description": "Validate after transport decoding; does not validate transport headers, authentication, all protobuf subtypes or broker ACK. Choose a concrete $defs entry for a known transport.",
  "anyOf": [
    {
      "$ref": "#/$defs/WebhookIndividual"
    },
    {
      "$ref": "#/$defs/WebhookGlobal"
    },
    {
      "$ref": "#/$defs/RabbitIndividual"
    },
    {
      "$ref": "#/$defs/RabbitGlobal"
    },
    {
      "$ref": "#/$defs/GlobalPayload"
    }
  ],
  "$defs": {
    "EventPayload": {
      "type": "object",
      "required": [
        "type"
      ],
      "properties": {
        "type": {
          "type": "string"
        },
        "event": {},
        "v1": {
          "type": "object",
          "properties": {
            "schema_version": {
              "type": "string"
            },
            "event": {
              "type": "string"
            },
            "instance_id": {
              "type": "string"
            },
            "ts": {
              "type": "string",
              "format": "date-time"
            },
            "data": {
              "type": "object"
            },
            "order_lifecycle": {
              "type": "object"
            }
          },
          "required": [
            "schema_version",
            "event",
            "instance_id",
            "data"
          ],
          "additionalProperties": true
        },
        "pollVote": {
          "type": "object",
          "properties": {
            "selectedOptionHashes": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "selectedOptions": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "options": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "title": {
              "type": "string"
            },
            "maxSelectableOptions": {
              "type": "integer"
            }
          },
          "required": [
            "selectedOptionHashes"
          ],
          "additionalProperties": true
        },
        "calendarEvent": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "description": {
              "type": "string"
            },
            "joinLink": {
              "type": "string"
            },
            "startTime": {
              "type": "integer"
            },
            "endTime": {
              "type": "integer"
            },
            "reminderOffsetSec": {
              "type": "integer"
            },
            "isCanceled": {
              "type": "boolean"
            },
            "extraGuestsAllowed": {
              "type": "boolean"
            },
            "isScheduleCall": {
              "type": "boolean"
            },
            "hasReminder": {
              "type": "boolean"
            },
            "location": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string"
                },
                "address": {
                  "type": "string"
                },
                "latitude": {
                  "type": "number"
                },
                "longitude": {
                  "type": "number"
                }
              },
              "additionalProperties": true
            }
          },
          "additionalProperties": true
        },
        "eventResponse": {
          "type": "object",
          "properties": {
            "eventId": {
              "type": "string"
            },
            "respondedBy": {
              "type": "string"
            },
            "response": {
              "type": "string"
            },
            "extraGuestCount": {
              "type": "integer"
            },
            "timestampMs": {
              "type": "integer"
            },
            "event": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string"
                },
                "description": {
                  "type": "string"
                },
                "joinLink": {
                  "type": "string"
                },
                "startTime": {
                  "type": "integer"
                },
                "endTime": {
                  "type": "integer"
                },
                "isCanceled": {
                  "type": "boolean"
                },
                "location": {
                  "type": "string"
                }
              },
              "additionalProperties": true
            }
          },
          "additionalProperties": true
        },
        "event_invite": {
          "type": "object",
          "properties": {
            "event_id": {
              "type": "string"
            },
            "title": {
              "type": "string"
            },
            "start_time": {
              "type": "integer"
            },
            "caption": {
              "type": "string"
            },
            "is_canceled": {
              "type": "boolean"
            },
            "thumbnail_b64": {
              "type": "string"
            }
          },
          "additionalProperties": true
        },
        "payment_invite_type": {
          "type": "string"
        },
        "editType": {
          "type": "string"
        },
        "editTargetId": {
          "type": "string"
        },
        "base64": {
          "type": "string"
        },
        "mimeType": {
          "type": "string"
        },
        "fileName": {
          "type": "string"
        },
        "s3": {
          "type": "object",
          "properties": {
            "url": {
              "type": "string"
            },
            "key": {
              "type": "string"
            },
            "bucket": {
              "type": "string"
            },
            "size": {
              "type": "integer"
            },
            "mimeType": {
              "type": "string"
            },
            "fileName": {
              "type": "string"
            }
          },
          "additionalProperties": true
        },
        "mediaUnavailable": {
          "type": "boolean"
        },
        "mediaError": {
          "type": "string"
        },
        "mediaErrorType": {
          "type": "string"
        },
        "state": {
          "type": "string"
        },
        "qrCodeBase64": {
          "type": "string"
        },
        "code": {
          "type": "string"
        },
        "codes": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "publicKey": {},
        "skipHandoffUX": {
          "type": "boolean"
        },
        "name": {
          "type": "string"
        },
        "version": {
          "type": "integer"
        },
        "recovery": {
          "type": "boolean"
        },
        "error": {
          "type": "string"
        },
        "full_sync": {
          "type": "boolean"
        },
        "jid": {
          "type": "string"
        },
        "oldBusinessName": {
          "type": "string"
        },
        "newBusinessName": {
          "type": "string"
        },
        "chatJid": {
          "type": "string"
        },
        "timestamp": {
          "type": "string",
          "format": "date-time"
        },
        "fromFullSync": {
          "type": "boolean"
        },
        "pinned": {
          "type": [
            "boolean",
            "null"
          ]
        }
      },
      "additionalProperties": true
    },
    "WebhookIndividual": {
      "type": "object",
      "required": [
        "userID",
        "eventType",
        "data",
        "timestamp"
      ],
      "properties": {
        "userID": {
          "type": "string"
        },
        "eventType": {
          "type": "string"
        },
        "userName": {
          "type": "string"
        },
        "userJID": {
          "type": "string"
        },
        "baseURL": {
          "type": "string"
        },
        "data": {
          "$ref": "#/$defs/EventPayload"
        },
        "timestamp": {
          "type": "integer"
        },
        "token": {
          "type": "string"
        },
        "pushName": {
          "type": "string"
        },
        "businessName": {
          "type": "string"
        }
      },
      "additionalProperties": true
    },
    "WebhookGlobal": {
      "type": "object",
      "required": [
        "userID",
        "eventType",
        "data",
        "timestamp"
      ],
      "properties": {
        "userID": {
          "type": "string"
        },
        "eventType": {
          "type": "string"
        },
        "userName": {
          "type": "string"
        },
        "userJID": {
          "type": "string"
        },
        "baseURL": {
          "type": "string"
        },
        "data": {
          "$ref": "#/$defs/EventPayload"
        },
        "timestamp": {
          "type": "integer"
        },
        "userToken": {
          "type": "string"
        },
        "pushName": {
          "type": "string"
        },
        "businessName": {
          "type": "string"
        },
        "source": {
          "type": "string"
        }
      },
      "additionalProperties": true
    },
    "RabbitIndividual": {
      "type": "object",
      "required": [
        "userID",
        "eventType",
        "data",
        "timestamp"
      ],
      "properties": {
        "userID": {
          "type": "string"
        },
        "eventType": {
          "type": "string"
        },
        "userName": {
          "type": "string"
        },
        "userJID": {
          "type": "string"
        },
        "baseURL": {
          "type": "string"
        },
        "data": {
          "$ref": "#/$defs/EventPayload"
        },
        "timestamp": {
          "type": "integer"
        },
        "userToken": {
          "type": "string"
        },
        "pushName": {
          "type": "string"
        },
        "businessName": {
          "type": "string"
        },
        "queueName": {
          "type": "string"
        }
      },
      "additionalProperties": true
    },
    "RabbitGlobal": {
      "type": "object",
      "required": [
        "userID",
        "eventType",
        "data",
        "timestamp"
      ],
      "properties": {
        "userID": {
          "type": "string"
        },
        "eventType": {
          "type": "string"
        },
        "userName": {
          "type": "string"
        },
        "userJID": {
          "type": "string"
        },
        "baseURL": {
          "type": "string"
        },
        "data": {
          "$ref": "#/$defs/EventPayload"
        },
        "timestamp": {
          "type": "integer"
        },
        "userToken": {
          "type": "string"
        },
        "source": {
          "type": "string"
        },
        "metadata": {
          "type": "object"
        }
      },
      "additionalProperties": true
    },
    "GlobalPayload": {
      "type": "object",
      "required": [
        "userID",
        "eventType",
        "payload",
        "createdAt"
      ],
      "properties": {
        "userID": {
          "type": "string"
        },
        "eventType": {
          "type": "string"
        },
        "userName": {
          "type": "string"
        },
        "userJID": {
          "type": "string"
        },
        "baseURL": {
          "type": "string"
        },
        "payload": {
          "$ref": "#/$defs/EventPayload"
        },
        "createdAt": {
          "type": "integer"
        },
        "id": {
          "type": "string"
        },
        "userToken": {
          "type": "string"
        },
        "pushName": {
          "type": "string"
        },
        "businessName": {
          "type": "string"
        },
        "metadata": {
          "type": "object"
        }
      },
      "additionalProperties": true
    }
  }
}
```
