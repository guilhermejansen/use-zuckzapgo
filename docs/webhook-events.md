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

Both the per-user webhook and the global webhook POST the same outer envelope,
with the WhatsApp event payload nested under **`data`**:

```jsonc
{
  "userID": "<instance id>",
  "eventType": "Message",
  "userJID": "5511999999999@s.whatsapp.net",
  "timestamp": 1752345600,
  "data": {                      // ← the event payload ("postmap")
    "type": "Message",           // existing key — unchanged
    "event": { /* ... */ },      // existing key — unchanged (whatsmeow event)
    "pollVote": { /* ... */ },   // enrichment keys — see below
    "v1": { /* ... */ }          // Spec 004 envelope — see below
  }
}
```

Everything documented below lives inside `data` — the enrichment keys
(`data.pollVote`, `data.calendarEvent`, …) are siblings of `data.event`.
The global webhook adds `userToken`, `userName`, `pushName`, `businessName`,
`baseURL` and `source: "zuckzapgo-global"` to the outer envelope.

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
