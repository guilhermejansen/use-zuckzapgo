# WhatsApp call integration — native gateway API

ZuckZapGo provides an in-process calls engine controlled by REST with audio/video streams
for application clients. Use the [canonical Calls API guide](../api/llm.txt) and
[OpenAPI](../api/spec.yml) for exact bodies, response schemas and media framing in
your installed release. The former sidecar design is only historical (§4).

## 1. Current architecture and configuration

The native engine is attached to each enabled WhatsApp client when it connects.
`GET/PUT /call/config` reads/writes per-user configuration. Use JSON fields
`callsEnabled`, `callInboundMode` and `callRecord`:

- Configuration normally applies on the next session reconnect.
- `callRecord` applies to the live manager immediately; disabling it does not
  interrupt a recording already running.
- `manual` lets your app answer/control the call and exchange PCM audio.
- `webhook` is the default: the engine answers and emits lifecycle events,
  recording only with authorization and the user's S3 configured.
- `reject` leaves the native engine off. `bot`, `ivr` and `ai` are accepted values
  but reject inbound calls because the built-in voice agent is unavailable.

Configuration is persisted in existing `users` columns. Recording control/parts
also have durable database state; live `/call/status` is not a call-history database.
There are no `/call/history` or `/call/missed` routes in the current API.

## 2. Native control and media

| Endpoint | Method | Purpose |
|---|---|---|
| `/call/config` | GET / PUT | Read/update per-user engine configuration |
| `/call/status` | GET | List this instance's live calls |
| `/call/dial` | POST | Dial with `phone` and optional `video`; returns `callId` |
| `/call/answer`, `/call/hangup` | POST | Answer/end using `callId` |
| `/call/play` | POST | Play `audioUrl` or `audioBase64` with `callId` |
| `/call/record/start`, `/call/record/stop` | POST | Authorized recording to the user's S3 |
| `/call/{call_id}/stream` | GET (WS) | Bidirectional s16le, 16 kHz, mono PCM; 960 samples / 1920 bytes / 60 ms |
| `/call/{call_id}/video/stream` | GET (WS) | H.264 Annex-B access units, encoded/decoded by the client |
| `/call/{call_id}/video/state` | GET (SSE) | Peer video state |
| `/call/{call_id}/video/stats` | GET | Video telemetry |

REST uses header `token: SEU_USER_TOKEN`; browser WebSocket clients use the same
user token as `?token=…`. Connector `ct_…` tokens do not authenticate `/call/*`.
Preserve the exact call ID returned by the API. Check HTTP status and response
`success`; use `data` when the operation returns the standard envelope.

Audio is available after answer. Your browser must obtain microphone permission,
resume playback, frame outbound audio correctly and clean up when the call ends.
Recording and the PCM stream are mutually exclusive per call. Video is not automatic
WebRTC/camera conversion: supply H.264 in the client and validate the actual media path.

A fail-closed mobile TCP-only route blocks the native engine. A permissive policy
does not activate that guard; it still does not make SOCKS TCP carry native UDP media.
See [network route](./network-route.md).

### Minimal outbound example

Enable `callsEnabled:true`, `callInboundMode:"manual"` and `callRecord:false` through
`PUT /call/config`, then coordinate a reconnect with the operator. For a paired,
enabled instance and an authorized destination:

```bash
BASE_URL='https://SEU_GATEWAY_HOST'
USER_TOKEN='SEU_USER_TOKEN'
curl --fail-with-body -X POST "$BASE_URL/call/dial" \
  -H "token: $USER_TOKEN" -H 'Content-Type: application/json' \
  --data '{"phone":"SEU_DESTINO_E164","video":false}'

curl --fail-with-body "$BASE_URL/call/status" -H "token: $USER_TOKEN"
```

Read `data.callId`, open the media socket for that call and wait for the callee to
answer. End it using its actual ID:

```bash
CALL_ID='SEU_CALL_ID'
curl --fail-with-body -X POST "$BASE_URL/call/hangup" \
  -H "token: $USER_TOKEN" -H 'Content-Type: application/json' \
  --data "{\"callId\":\"$CALL_ID\"}"
```

## 3. Legacy signaling and webhook compatibility

The additive signaling routes remain: `/call/reject/send`, `/call/reject`,
`/call/accept`, `/call/preaccept` and `/call/terminate`. They send signaling
commands; they are not substitutes for the native audio stream.

`/call/initiate` returns `501` by default. Use `/call/dial` for native outbound
media. `GLOBAL_CALL_INITIATE_DIAL_ALIAS=true` explicitly makes initiate an alias
of dial; it does not create a remote-media service.

Existing webhook payloads remain compatible. Domain enrichment is nested under
`data.v1`; see [webhook events](./webhook-events.md). Do not infer successful
media from call signaling alone, or infer a duration that the event does not provide.

## 4. HISTORICAL — Spec 005 sidecar removed

The old `/session/sidecar/config`, `/call/media/*`, external WASM/WebRTC sidecar,
SDP/ICE proxy examples and `sidecar_not_configured` recipes describe a removed
implementation. They are not available endpoints or deployment requirements.
There is no executable sidecar recipe in this guide. Use the native control/media
surface above and [api/llm.txt](../api/llm.txt).

The earlier Spec 004 document also included catalog/order proposals. The current
business APIs are documented in OpenAPI; do not assume a permanent
`503 catalog_unavailable` stub. Business sends follow the licensing policy of
the installed distribution: protected interactive/shop/order sends require Enterprise; the commercial startup license remains required.

## 5. See also

- [Calls API / LLM guide](../api/llm.txt)
- [Native audio and recording](./call-audio-implementation-guide.md)
- [Video guide](./call-video-guide.md)
- [Webhook events](./webhook-events.md)
- [OpenAPI](../api/spec.yml)
- [Public documentation index](./INDEX.md)
