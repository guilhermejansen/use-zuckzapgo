# Native call audio — operator and integration guide

This guide describes the native calls API in ZuckZapGo. For exact schemas, media framing,
full client examples and availability limits, use the [canonical Calls API guide](../api/llm.txt)
and [OpenAPI](../api/spec.yml) for the installed release. This is an operational guide;
the earlier cross-project gap audit and implementation proposal are not current API requirements.

## 1. Architecture

```text
Application -- REST /call/* --> native engine in the gateway --> WhatsApp relay
Application <-- WSS /call/{call_id}/stream --> PCM audio bridge
```

The engine runs in the gateway process. The application controls calls over REST and
exchanges raw audio over the WebSocket. No external call-media sidecar is required.
The WebSocket does not negotiate WebRTC/SDP/ICE for your application, and the gateway
does not provide a bundled SIP/PABX service or the new remote-media/desktop platform.

| Surface | Contract |
|---|---|
| REST authentication | Header `token: SEU_USER_TOKEN`, using the per-instance user token |
| Browser WebSocket authentication | `?token=SEU_USER_TOKEN`; non-browser clients may use the header |
| Audio | Signed 16-bit little-endian PCM, 16,000 Hz, mono |
| Audio frame | 960 samples = 1,920 bytes = 60 ms, without WAV/container headers |
| Call identity | Use the exact `callId` returned by the API; preserve its case |

Do not expose the admin token to a call client. A Connector `ct_…` token only works
on `/connector/*` and does not authenticate `/call/*`. URLs carrying a user token
must not be logged or shared.

## 2. Configuration and inbound modes

Configure the instance through `GET/PUT /call/config`, not by editing the database.
The JSON uses `callsEnabled`, `callInboundMode` and `callRecord`; database column names
such as `calls_enabled` are not request field names.

```bash
BASE_URL='https://SEU_GATEWAY_HOST'
USER_TOKEN='SEU_USER_TOKEN'
curl --fail-with-body -X PUT "$BASE_URL/call/config" \
  -H "token: $USER_TOKEN" -H 'Content-Type: application/json' \
  --data '{"callsEnabled":true,"callInboundMode":"manual","callRecord":false}'
```

The configuration takes effect on the next session reconnect, except `callRecord`,
which is applied immediately to the live manager. Coordinate reconnection with the
operator: disconnecting an active session interrupts its current work. Reconnect with
the documented `/session/disconnect` and `/session/connect` flow when appropriate.

| `callInboundMode` | Current behavior |
|---|---|
| `manual` | Your app answers and drives the call through REST/audio WebSocket. Use for app/browser audio. |
| `webhook` | Default: the engine answers and emits lifecycle webhooks; records only when `callRecord` is enabled and user S3 is available. |
| `reject` | Native engine is not attached; rejection follows the legacy path. |
| `bot`, `ivr`, `ai` | Accepted configuration values, but the built-in voice agent is unavailable and inbound calls are rejected. |

Provider URLs and prompts do not activate a built-in agent. An external STT/LLM/TTS
application can implement its own audio loop using `manual` mode and the PCM socket.

A desired mobile route with `failClosed:true` and `tcpOnly:true` blocks the native
engine. A permissive route does not activate that guard, but does not add UDP media
to the TCP SOCKS path or guarantee calls through the mobile exit.

## 3. Application/browser audio flow

1. Obtain microphone permission and resume the `AudioContext` from an explicit user
   action in a secure browser context. Handle device denial/unavailability visibly.
2. Dial or answer through REST, then open `/call/{call_id}/stream` for that live call.
3. Play incoming s16le frames through your audio pipeline. For a browser, the canonical
   guide shows AudioWorklet playout with a bounded jitter buffer.
4. Capture the microphone, resample if the device does not use 16 kHz, convert to s16le
   and send complete 960-sample frames. Do not send a WAV header on the media socket.
5. To mute your microphone, send zero-filled audio frames while keeping the socket open.
6. Observe `/call/status` or lifecycle events. A call that has ended disappears from the
   live list; close sockets/audio resources and update your UI when it does.

Audio starts after the peer answers or the inbound call is answered. A successful dial,
WebSocket upgrade or signaling event alone is not proof of two-way audio. Browser
playback, microphone capture and the network path each need validation in your client.

## 4. REST operator flow

Use the `BASE_URL` and `USER_TOKEN` variables above. Place calls only to an authorized
destination. The dial body uses `phone`, not `to`:

```bash
curl --fail-with-body -X POST "$BASE_URL/call/dial" \
  -H "token: $USER_TOKEN" -H 'Content-Type: application/json' \
  --data '{"phone":"SEU_DESTINO_E164","video":false}'

curl --fail-with-body "$BASE_URL/call/status" -H "token: $USER_TOKEN"
```

Read the returned `data.callId`. Inbound ringing calls can be discovered from the live
list or a subscribed call-offer event. Answer or hang up using the actual call ID:

```bash
CALL_ID='SEU_CALL_ID'
curl --fail-with-body -X POST "$BASE_URL/call/answer" \
  -H "token: $USER_TOKEN" -H 'Content-Type: application/json' \
  --data "{\"callId\":\"$CALL_ID\"}"

curl --fail-with-body -X POST "$BASE_URL/call/hangup" \
  -H "token: $USER_TOKEN" -H 'Content-Type: application/json' \
  --data "{\"callId\":\"$CALL_ID\"}"
```

For file playback, `POST /call/play` accepts `callId` and either `audioUrl` or
`audioBase64` (WAV/MP3/Ogg-Opus), decoded/resampled by the gateway. See the canonical
guide for errors and complete examples. `/call/initiate` returns `501` by default;
use `/call/dial` for outbound media. The opt-in `GLOBAL_CALL_INITIATE_DIAL_ALIAS=true`
only makes the legacy endpoint an alias of dial.

If audio fails, inspect sanitized gateway diagnostics and the actual browser/media
state. Check that the engine is enabled after reconnect, the call exists, the peer
answered, and your input/output frame formats match. Do not infer that a silent
browser proves a backend protocol defect, or that working signaling proves audio.

## 5. Historical note — removed Spec 005 sidecar

**HISTORICAL, REMOVED:** `/session/sidecar/config`, `/call/media/*` and the former
WASM/WebRTC sidecar bridge are not part of the current API. Old SDP/ICE examples
and sidecar configuration instructions must not be used. The current media endpoint
is `/call/{call_id}/stream`, documented above and in [api/llm.txt](../api/llm.txt).

## 6. Video calls (H.264 Annex-B)

- `POST /call/dial` accepts `video:true`.
- `/call/{call_id}/video/stream` carries H.264 Annex-B access units on a separate
  WebSocket; `/call/{call_id}/video/state` exposes peer video state over SSE.
- The engine does not encode camera pixels or decode them for display. Your client
  supplies the codec and handles SPS/IDR/keyframes, timing and cleanup.
- Open the video socket alongside the audio socket when both are required. Do not
  send raw camera frames, JPEG images or WebRTC tracks to the H.264 endpoint.

See [Call Video Guide](./call-video-guide.md) for detailed formats, controls and limits.
Validate the actual account, client codec and network combination before relying on video.

## 7. Call recording (no local disk)

Recording requires `callRecord:true` in `PUT /call/config` and the **user's own S3**.
With the flag off, `/call/record/start` returns `403 call_recording_disabled` and
records nothing. With no user object store, start is refused with `400`; it does
not create a recording in a fallback destination. Global S3 is not a substitute.

`webhook` mode records answered calls automatically only when authorized; `manual`
mode starts through `POST /call/record/start`. Recording and the PCM WebSocket share
the inbound audio sink and are mutually exclusive on the same call.

- Audio is held in memory and uploaded to user S3. Database tables
  `call_recordings` / `call_recording_parts` hold control/ownership and part metadata,
  not the audio itself. Keep both database and S3 in your backup plan.
- Audio is uploaded as 5 MiB multipart parts. Private 30 s checkpoints of audio
  not yet covered by a part support recovery after a crash when S3 is healthy.
  Audio after the last confirmed checkpoint can be lost; S3 outages weaken that bound.
- On close, the gateway finalizes the WAV and removes temporary parts/checkpoints.
  `/call/record/stop` returns `mediaKey`; an empty value can mean no recording was
  active, not that a file was saved. Upload failure returns an error and can remain
  pending for background recovery; follow `CallRecordingReady` instead of assuming success.
- Silence gaps above 2 s may not enter the recording. Recorded duration can be
  shorter than call duration; checkpoint cadence is measured in recorded audio.
- Memory use is limited by `GLOBAL_CALL_RECORDING_MEMORY_QUOTA_MB` (default: 25% of
  the detected container limit, or 256 MiB). Quota/recording limits can stop recording
  while the call continues, with `CallRecordingStopped` describing the reason.
- Failed finalization is retried from persisted control state. After attempts are
  exhausted, DLQ control/error data may remain while uploaded audio parts are aborted
  or cleaned up. A DLQ entry is not a recoverable audio backup.

`callRecord` changes affect the live manager immediately but do not cut an already
running recording. Delivery retries can duplicate webhooks; deduplicate by event identity.
Do not share audio, signed URLs, user tokens or raw call/session diagnostics in public logs.

## 8. See also

- [Calls API / LLM guide](../api/llm.txt)
- [OpenAPI 3](../api/spec.yml)
- [Video calls](./call-video-guide.md)
- [Webhook events](./webhook-events.md)
- [Mobile network route](./network-route.md)
- [Public documentation index](./INDEX.md)
