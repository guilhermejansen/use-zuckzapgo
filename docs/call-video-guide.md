# Call Video Guide — H.264 over the native calls engine (BETA)

Companion to [`call-audio-implementation-guide.md`](./call-audio-implementation-guide.md).
The audio plane is production-validated; **video is BETA** until proven against a real
WhatsApp video call (the engine's media path still carries `NOT VALIDATED` markers).

The engine (`meowcaller` fork under `whatsmeow-private/calls`) carries **encoded H.264
Annex-B** over the WhatsApp relay. It does **not** encode or decode pixels — an external
codec (the browser's WebCodecs, ffmpeg, a hardware encoder) produces and consumes the
H.264.

---

## 1. Wire format

- **Codec:** H.264, **Annex-B** byte stream (NAL units prefixed with the start code
  `0x00 0x00 0x00 0x01`).
- **Framing:** one WebSocket **binary** message = one access unit (one frame's NALUs),
  reassembled on the RTP marker bit inbound.
- **Keyframes:** send an IDR/keyframe immediately after opening the socket and at a
  sensible GOP interval (~every 1–2 s). The peer cannot decode until it sees a keyframe;
  a decoder cannot configure until it sees the SPS.

---

## 2. Endpoints

| Method | Path | Purpose |
|---|---|---|
| `GET` (WS) | `/call/{call_id}/video/stream?token=…` | Bidirectional H.264 Annex-B |
| `GET` (SSE) | `/call/{call_id}/video/state?token=…` | Peer camera on/off + orientation |
| `GET` | `/call/{call_id}/video/stats?token=…` | Live server-side video telemetry |
| `GET` (SSE) | `/call/{call_id}/events?token=…` | Reactions, hand, mute, screen share, roster, phase |
| `POST` | `/call/video` | Turn local video on/off mid-call (audio→video upgrade) |
| `POST` | `/call/screenshare` | Tell peers the outbound video is now a screen |

Video is opened **in addition to** the audio socket (`/call/{call_id}/stream`) for a call
placed or answered with video (`dial { video: true }`).

The rest of the call surface — dial/answer/hangup, recording, group calls, call links,
the waiting room, reactions and hand raise — is listed in §7 alongside its SDK wrapper.

### 2.3 What you may pass as a call target

`POST /call/dial` takes `phone`, and the name undersells it. Three forms are accepted:

| Form | Example | Notes |
|---|---|---|
| Plain number | `5521999999999` | E.164 digits, no `+`. **Resolved to the callee's LID first** — see below. |
| Phone JID | `557192856732@s.whatsapp.net` | Used as given. |
| LID | `47588875227343@lid` | Used as given; skips resolution entirely. |

**Anything carrying an explicit `@` is passed through untouched.** That matters more than
it sounds: stripping non-digits from a target destroys the suffix, and a LID sent as a
phone number comes back as *"usync returned no LID for 47588875227343"* — about the very
LID it was handed.

The resolution step exists because **a typed number is not always the canonical one**.
WhatsApp keeps many Brazilian mobiles WITHOUT the ninth digit, so `5571992856732` is not
the JID `557192856732`. Asking usync about the typed form returns an *empty* user record —
no lid, no devices, no status — which surfaces as "peer unreachable or not on WhatsApp"
for a contact sitting in the chat list. Dialling resolves via the query that performs that
normalization, so both spellings work.

A group JID (`120363…@g.us`) is **not** a valid target here — it needs the group endpoints
in §2.4.

### 2.4 Group calls and WhatsApp's participant limit

| Endpoint | Use |
|---|---|
| `POST /call/group/dial-by-id` | `{groupJid, video}` — calls **every** remote member. Refuses if the roster exceeds the limit. |
| `POST /call/group/dial` | `{targets[], video, groupJid?}` — calls an **explicit** list. Not capped. |

**The limit is WhatsApp's, not ours, and it is dynamic.** The server declares it as
`connected-limit`, a *required* attribute of the group-control stanza — 32 including you
(so 31 remote) on a group, and 8 on a call link. It arrives only once the call is
established, which is why `dial-by-id` uses a static 31 as its pre-flight check.

So a 105-member group is not uncallable — it just cannot be called *wholesale*. Pick up to
31 members and use `/call/group/dial`, passing **`groupJid`** so the call stays bound to
that group instead of becoming an unrelated ad-hoc call that happens to hold the same
people.

### 2.5 In-call control stanzas are addressed per call type

Relevant if you drive the engine directly rather than through this API. Control stanzas —
`screen_share`, `user_action` (hand raise) — are addressed to `<call-id>@call` on a
**group** call but to the **peer's LID** on a 1:1 call; the official client sends 1:1
screen share peer-to-peer. Sending a 1:1 control stanza to the group address gets it
rejected, and a rejected control stanza must **not** be treated as the call failing: doing
so ends a perfectly healthy call. Lifecycle acks (offer/accept/terminate) stay fatal;
control acks do not.

### 2.1 `/video/stream` (WebSocket)

- **Server → client** (binary): the peer's video as Annex-B access units.
- **Client → server** (binary): your camera video as Annex-B access units; the engine
  forwards them to the peer. Do **not** send raw frames, JPEG, or WebRTC tracks.
- **Backpressure:** the server buffers outbound frames and **drops the oldest** when a slow
  client falls behind (newest-wins) — it never blocks the media loop. One video subscriber
  per call (last wins).
- **Outbound camera state:** on your first sent frame the engine announces your camera
  active to the peer (`<video>` state); it announces off when the socket closes. (BETA.)

### 2.2 `/video/state` (SSE)

Proper SSE framing (`data: <json>\n\n`) with a 15 s heartbeat comment and a
`retry: 3000` hint. Each event:

```json
{ "active": true, "upgrade": false, "orientation": 0, "raw": 1 }
```

- `active` — peer camera on (state 1).
- `upgrade` — mid-call audio→video upgrade (state 11).
- `orientation` — 0..3; rotate the rendered video by `orientation × 90°`.

The hub self-cleans: when the last SSE subscriber disconnects, the hub is removed and the
peer callback detached (no per-call leak).

---

## 3. Browser rendering (WebCodecs) — ready-made SDK helper

The dashboard SDK ships `ZZ.sdk.calls.video` (`static/dashboard/js/sdk/modules/calls.js`):

```js
// Feature-detect first.
if (!ZZ.sdk.calls.video.isSupported()) {
  // No WebCodecs — show an "unsupported browser" message.
}

// One call wires the whole session: WS + decode→canvas + camera→encode→WS + state SSE.
const session = await ZZ.sdk.calls.video.startSession({
  callId, token,
  remoteCanvas: document.getElementById("remoteVideoCanvas"), // peer video
  localVideo:   document.getElementById("localVideoPreview"),  // local camera
  sendCamera: true,
  onFirstFrame: () => console.log("peer video live"),
  onState: (st) => console.log("peer camera:", st.active),
});

// Later:
await session.setCameraEnabled(false); // toggle camera mid-call
session.stop();                          // tear down WS + SSE + camera
```

What the helper does:

- **Decode (peer → `<canvas>`):** a `VideoDecoder` fed Annex-B `EncodedVideoChunk`s. It
  derives the `avc1.PPCCLL` codec string from the **SPS** (profile/constraint/level bytes),
  **gates on the first keyframe** before configuring, and rotates by the peer's orientation.
- **Encode (camera → Annex-B):** a `VideoEncoder` configured `avc: { format: "annexb" }`,
  `latencyMode: "realtime"`. Frames come from `MediaStreamTrackProcessor` where available,
  else a `<canvas>` draw-loop + `new VideoFrame(...)`. A keyframe is forced ~every 3 s.

Lower-level building blocks are also exposed: `createDecoder({canvas})`,
`createEncoder({width,height,onChunk})`, `hasIDR(bytes) / hasParameterSets(bytes)`,
`codecFromAnnexB(bytes)`, `fitEncoderSize(w,h,maxW,maxH)`, `h264LevelFor(w,h,fps)`,
`h264Codec(levelByte)`.

### 3.1 The H.264 level is derived from the frame size — never hard-coded

A codec string like `avc1.42E01E` is three fields: profile `0x42` (Baseline), constraint
flags `0xE0`, and **level `0x1E`, i.e. level 3.0**. The level is not decoration. It is a
promise about how big a frame is and how fast frames arrive, and `VideoEncoder.
isConfigSupported()` enforces it — a picture that overruns its level is refused just as
flatly as a codec the browser does not have.

Level 3.0 allows **1620 macroblocks** per frame (a macroblock is 16×16 pixels, and a
partial one still costs a whole one):

| Source | Size | Macroblocks | Fits level 3.0? |
|---|---|---|---|
| Camera | 640×480 | 1200 | yes |
| Level 3.0's actual ceiling | 720×576 | 1620 | exactly |
| Screen, squeezed to the old box | 1152×720 | 3240 | **no — 2× over** |
| Screen or webcam at 720p | 1280×720 | 3600 | **no** |
| Screen at 1080p | 1920×1080 | 8160 | **no** |

This is why screen sharing died while the camera worked: **same codec string, different
picture size**. `createEncoder` threw `this browser cannot encode H.264 (avc1.42E01E)`
before `POST /call/screenshare` was ever reached, so the peer was never told and the
share "flashed and left". A 1280×720 webcam would have hit the identical wall.

So `V.h264LevelFor(width, height, framerate)` picks the **smallest** level that holds
both limits — smallest, because a lower level is accepted by more decoders:

| Level | Level byte | `MaxFS` (macroblocks) | `MaxMBPS` (macroblocks/s) | Covers |
|---|---|---|---|---|
| 3.0 | `1E` | 1620 | 40 500 | 640×480 |
| 3.1 | `1F` | 3600 | 108 000 | 1280×720 |
| 3.2 | `20` | 5120 | 216 000 | 1280×960 |
| 4.0 | `28` | 8192 | 245 760 | 1920×1080 |

1920×1080 is 120 × 68 = **8160** macroblocks against level 4.0's **8192** — it fits, with
32 to spare. That is not a coincidence; 4.0 is the level 1080p was defined around.

Two details worth keeping in mind when changing this code:

- **Levels are sized for `V.H264_LEVEL_FPS_HEADROOM` (20 fps), not for the rate you start
  at.** `retune()` changes bitrate and frame rate on the live encoder without touching the
  codec string, and the call-size ladder raises the rate back up as participants leave. A
  level chosen tightly for 10 fps would be quietly violated the moment a group shrank.
- **If a browser refuses anyway, the encoder adapts rather than dying**: it climbs the
  level ladder first, then halves the picture area (keeping aspect ratio and even sides)
  and tries again. Only after that does it throw — and the message then names the size,
  the frame rate and every level it tried, instead of just a codec string.

The object returned by `createEncoder` exposes **`info()`**, which reports the codec
string, size, frame rate and bitrate that were actually negotiated alongside the size
that was requested — so "why is my share soft?" has an answer when the fallback shrank
the picture.

### 3.2 Screen sharing goes out at native size

There is exactly **one** outbound video pipeline on a WhatsApp call, so sharing a screen
**replaces** the camera; `POST /call/screenshare` is what labels it for peers.

The ceiling is **1920×1080**, and it is chosen to agree with the protocol rather than to
be a round number:

- Our own offer already advertises `screen_width="1920" screen_height="1080"` in the
  `<video>` child (`calls/signaling/video.go`).
- **Nothing in the signalling negotiates a per-frame resolution.** The `<video>` node
  carries the codec, the orientation and that static screen hint — nothing else. The real
  dimensions of every frame travel **inside the SPS**, in the bitstream. That is precisely
  why the receiving side has `codecFromAnnexB`, which reads profile/constraint/level back
  out of the peer's SPS.

Below the ceiling the capture is sent at its **native** size; only the even-sides rule of
4:2:0 chroma subsampling applies (an odd dimension is not encodable at all, and captured
windows are very often odd — 1147×717). Above the ceiling it is scaled down
proportionally. The earlier 1280×720 box was our own invention and squeezed, for example,
a 1512×982 window into 1152×720 for no protocol reason.

Bitrate for a shared screen is **2.5 Mbps at 10 fps** — the opposite trade from a talking
head. Text must stay legible, and screen content is nearly static, so H.264 spends almost
nothing on an unchanged frame; the higher ceiling costs little on average and buys back
sharpness on redraws. Unlike the camera, the screen budget is **not** divided by the
call-size ladder.

### 3.3 Browser support

WebCodecs is in current Chromium (Chrome/Edge) and Safari 16.4+. Where it is missing,
`isSupported()` returns `false` — surface an "unsupported browser" message. A full **MSE
fallback** would require an in-browser **Annex-B→fMP4 muxer** (not shipped) — documented
here as a known limitation, not a silently broken path.

---

## 4. Audio ↔ video parity

| Capability | Audio | Video |
|---|---|---|
| Dial / answer with media | ✅ | ✅ (`dial { video: true }`) |
| Two-way media socket | `/…/stream` (PCM) | `/…/video/stream` (H.264 Annex-B) |
| Peer state signal | mute events | `/…/video/state` SSE |
| Outbound state to peer | — | `<video>` active/off on send/close (BETA) |
| Incoming-media flag | media attr | `v1.call.offer.is_video` (webhook, additive) |

The `v1.call.offer` webhook now carries **`is_video`** (derived like the engine's own
detection: a `<video>` child or `media="video"`), so integrators can route "incoming video
call" without parsing `raw_xml`. Additive-only, under the `v1` key.

---

## 5. BETA status — honest diagnostic + what "validated" will mean

The video plane is meowcaller's **initial / experimental** video support (the upstream
`purpshell/meowcaller` engine calls it "initial video calls support"). It is **not** a
finished protocol implementation, and this fork does **not** reverse-engineer the missing
pieces. Treat every video path as **BETA** until proven on real devices.

### 5.1 The inbound bridge — superseded: video *does* arrive

**This section previously said the opposite, and it was wrong.** It recorded that "no
`first video RTP demuxed` line ever appears", concluding that WhatsApp never bridges the
video SSRC onto the audio relay channel. A `VOIP_DIAG_DIR` capture of a real group call
settles it: **6125 complete video access units across 5 distinct SSRCs**, i.e. the log
line at `engine_media.go:1068` fires and the bridge assumption holds.

What remains true from the original diagnosis:

- **Egress is real.** `videoSender.send()` (`calls/engine_media.go`) packetizes the H.264
  access unit into RTP, protects it with SRTP, and hands it to the relay channel. Bytes
  leave the process — and peers do render them.
- **Upstream still labels its video support "initial"**, and the markers in `calls/` are
  upstream's, not ours. Do not delete them from that tree: it is regenerated wholesale by
  `scripts/sync-meowcaller.sh`, so an edit there is lost at the next sync.

The open defect is now a **different** one, and narrower: in a group call a participant's
video can freeze permanently while that same camera is fine on everyone's phone. The same
capture shows ~12 % of video packets failing `UnprotectVideo`. Whether that is one dead
stream or loss spread across all of them decides the fix, and the two are indistinguishable
from an aggregate — see §6.3, which exists precisely to answer it. **That question is open;
this guide does not claim a cause for it.**

### 5.2 Code-complete but `NOT VALIDATED`

These compile and send/receive at the wire level. The `NOT VALIDATED` markers on them are
upstream's and stay until a live capture proves each path:

- inbound video RTP demux (`livecall.go` `ReceiveVideo`) — the marker is still in the
  source, but frames *have* now been observed end to end (§5.1)
- outbound video send (`SendVideo` / `sendVideoFrame`)
- video E2E keying — `engine_media.go:607` still assumes video shares the audio E2E keys
- group audio mixing (`group_audio_mixer.go`) — five separate markers

`video_fork.go` no longer exists: it was retired at the `6d9b7b2` re-sync when upstream
shipped native video, and the accept-video patch was absorbed upstream as
`m.localVideo || m.remoteVideo`. Earlier revisions of this guide pointed at that file.

### 5.3 What became validated

| Path | Status | Evidence |
|---|---|---|
| Inbound video demux + reassembly | **observed working** | 6125 access units / 5 SSRCs in a `VOIP_DIAG_DIR` capture |
| Per-participant framing (group video) | **observed working** | one decoder and tile per camera; pinned by `TestParticipantVideoFrameRoundTrip` + `scripts/video-frame-parser-test.js` |
| Outbound camera → peer | **observed working** | peers render our camera on a real device |
| H.264 level selection | **unit-pinned** | `scripts/video-frame-parser-test.js` |
| Screen share at native size | **needs a live run** | encoder no longer refuses the config; peer-side rendering to be confirmed on a device |
| Permanent freeze of one participant | **measured — Branch A** | see §5.5 |

### 5.5 The freeze is Branch A: SSRCs we never registered

Measured on a real two-call capture (`analyze-video-drops`, 2026-08-08), not inferred:

| SSRC | Label | Frames | Failures | Fail% |
|---|---|---|---|---|
| `0xc62676b1` | **UNMATCHED** | **0** | 1613 | 100 % |
| `0x24c064a2` | **UNMATCHED** | **0** | 1491 | 100 % |
| `0x4f5c5715` | **UNMATCHED** | **0** | 573 | 100 % |
| `0x4fb1121f` | **UNMATCHED** | **0** | 55 | 100 % |
| `0xc47a51ff` | participant …859:0@lid video | 120 | 19 | 13.7 % |
| `0x51a9366a` | participant …623:0@lid video | 2322 | 165 | 6.6 % |
| `0x2c4c2f12` | participant …028:0@lid video | 1044 | 9 | 0.9 % |
| `0xce5359b5` | participant …028:0@lid video | 1488 | 3 | 0.2 % |
| `0x596aba7a` | participant …859:0@lid video | 2315 | 4 | 0.2 % |
| `0x0a6fc69d` | participant …623:0@lid video | 123 | 0 | 0 % |

**Four SSRCs produced zero frames while absorbing 94.9 % of all 3932 failures.** Every one
of the six SSRCs that *does* decode matches `VideoSlotWord` (slot 2) of a known
participant, so the derivation itself is right; the four dead ones match nothing — not
another participant, not another slot, and not the second call in the dump (that was
checked explicitly, because deriving with the wrong call ID would fake this exact result).

So the sender uses an SSRC that was never registered, and `byVideoSSRC` holds exactly one
per participant. This also explains why the freeze is **permanent** rather than a glitch:
recovery PLIs come from `videoState.assembler.Push(...)`, the assembler only sees packets
that survived unprotect, and a stream failing 100 % pushes nothing — so it never detects a
gap and never asks for a keyframe. The 12 % aggregate seen earlier was the average of one
dead stream and several healthy ones.

The fix belongs in the receiver-allocation path inside `whatsmeow-private/calls/`, which is
regenerated by `scripts/sync-meowcaller.sh` — so it has to be carried as a declared
divergence there, not a hand edit. **Not implemented yet.**

### 5.4 Validation runbook

To attempt end-to-end validation (and flip a path from BETA to validated):

1. Enable engine trace logging for the calls package (the engine logs via the injected
   `zerolog` logger), and set `VOIP_DIAG_DIR` so the packet-level recorder runs (§6.3).
2. From the dashboard (or API), **dial a video call** (`dial { video: true }`) to a
   **second real phone** you control — or place an audio call from the phone and let the
   widget answer with the accept-video path.
3. **Answer on the other device** and turn its camera on.
4. Watch the logs for **`first video RTP demuxed`** (inbound video) and for the peer
   rendering our camera (outbound). Both have now been seen; a run where either is
   *missing* is a regression, which is the opposite of what this step used to mean.
5. For screen sharing, share a window and confirm on the peer device that it arrives at
   its **native** aspect ratio, that `POST /call/screenshare` was actually sent, and that
   pressing stop hands the camera back. Repeat with an odd-sized window (e.g. 1147×717) —
   4:2:0 makes odd dimensions unencodable, and that exception is what used to kill the
   share mid-swap.
6. To investigate a participant freezing, keep `VOIP_DIAG_DIR` on until it happens, then
   run `analyze-video-drops` and **read the verdict before writing a fix** (§6.3).

Do **not** remove the `NOT VALIDATED` markers or the **BETA** labels until frames are
confirmed peer→screen and camera→peer on a real device. Note that those markers live in
`whatsmeow-private/calls/`, which is regenerated by `scripts/sync-meowcaller.sh` — the
place to record validation is here, not there.

---

## 6. Diagnosing a broken video call

Three instruments, from cheapest to heaviest. Reach for them in this order.

### 6.1 `/video/stats` and the browser's own counters

`GET /call/{call_id}/video/stats` is the server's view: who is sending, frames received
versus delivered, what was shed under backpressure, backlog bytes.

The browser half is `session.stats()`, and the number that matters there is **`frames`
versus `drawn`** per participant. They answer different questions:

- frames arriving but not drawn → the browser cannot keep up (decode and paint still run
  on the main thread; past roughly eight cameras that is the real ceiling).
- no frames arriving at all → nothing to draw; the problem is upstream of the browser.

`decoderResets` climbing means the decoder keeps hitting fatal errors and rebuilding.

### 6.2 `client-log` — errors only the page can see

A capture or codec failure happens **inside the browser**; asking a user to open devtools
is not a diagnosis path. `session.report(message)` pushes a line over the existing video
websocket as `{"type":"client-log","message":…}`, and the server logs it as
`video client reported a problem`.

This is how the screen-share failure in §3.1 was finally pinned down: the server log
carried the exact exception text, `screen share failed — Error: this browser cannot encode
H.264 (avc1.42E01E)`, which is what turned "it flashes and leaves" into an arithmetic
problem with a table.

### 6.3 `VOIP_DIAG_DIR` + `analyze-video-drops`

Set `VOIP_DIAG_DIR=/some/dir` and the engine records packet-level JSONL, one file per
stream (`video.jsonl`, `video_wire.jsonl`, `ssrc.jsonl`, `srtp.jsonl`, …), one JSON object
per line with an injected `ts_ms`.

`scripts/analyze-video-drops` reads that dump — **read-only, it never writes to it** — and
aggregates the `video` stream per SSRC:

```bash
go run ./scripts/analyze-video-drops -dir /some/dir
go run ./scripts/analyze-video-drops -dir /some/dir -participants 123:4@lid,567:8@lid
go run ./scripts/analyze-video-drops -dir /some/dir -json
```

It labels each observed SSRC by deriving the expected ones from the roster
(`rtp.DeriveWasmParticipantSsrc(callID, id, rtp.VideoSlotWord)` plus the nine relay-stream
slots), so an SSRC that matches nobody is visible as `UNMATCHED`.

One caveat about the reported rate: a **frame** is many packets, while a **failure** is
one packet, so `failures / (frames + failures)` is a *comparative index between SSRCs* —
not a wire packet-loss percentage. That is all the classifier needs, because the question
is which SSRC differs from the others, not what the absolute loss is.

The thresholds are explicit and testable (`defaultClassifyConfig`): a zero-frame SSRC needs
**≥ 20** failures before it counts as dead, an SSRC needs **≥ 20** events before its ratio
informs the uniformity test, and "comparable" means within **0.15** absolute and **4×**
relative. There is a third outcome, `inconclusive`, for a dump that supports neither
branch — and it is the right answer surprisingly often, so it is not a bug.

**Read the verdict before writing any fix.** `unprotect_failed` is emitted for **two**
different causes, and each record now names which one via a **`reason`** field:

| `reason` | Meaning | Where the fix lives |
|---|---|---|
| `no_receiver` | The SSRC has no registered receiver at all — nothing was ever set up to decrypt it. | Registration / SSRC derivation |
| `auth_failed` | Authentication failed on a receiver that **does** exist. | Keys / epoch, or genuine packet loss |

Reporting both as one number is what made "12 % of video packets fail" read like packet
loss when it was in fact one stream that had never been wired up. Aggregate rate alone
still cannot tell you which shape you have:

- **Branch A — one SSRC with ~100 % failures and zero frames, among healthy ones.** That
  is a state/mapping defect, not the network. It also explains a *permanent* freeze:
  recovery PLIs are driven by `videoState.assembler.Push(...)`, and the assembler only
  ever sees packets that survived unprotect. A partially failing stream shows the
  assembler a gap and gets a keyframe; a stream failing 100 % pushes **nothing**, detects
  **no** gap, and therefore **never asks for a keyframe**. If that SSRC is also
  `UNMATCHED`, the sender is using an SSRC we never registered — `byVideoSSRC` holds
  exactly one per participant.
- **Branch B — failures spread evenly across every SSRC.** That is packet loss. Unprotect
  is not the fault and the recovery PLI already fires; the lever is the 300 ms PLI
  throttle (`videoPLIInterval`) and keyframe policy, not the mapping.

An aggregate figure such as "12 % failures over 6125 frames in 5 SSRCs" has the *shape* of
Branch A but does not prove it — that is exactly the distinction this tool exists to make.
(On the first real dump it made it: see §5.5.)

**A diagnostics directory accumulates across calls** — the recorder appends, so one dump
routinely holds several. The call ID is HKDF input, so the tool derives against **every**
call ID it finds and says so in `notes`. Deriving with only the first one would label every
SSRC of every later call `UNMATCHED`, manufacturing a Branch A verdict out of nothing.
When a dump spans calls, use the per-SSRC `FIRST`/`LAST` timestamps to tell which call an
SSRC belongs to.

---

## 7. SDK reference — `ZZ.sdk.calls`

All 25 functions of `static/dashboard/js/sdk/modules/calls.js`. Every one takes an
optional trailing `opts` (request options); auth is applied automatically from the active
session, so `token` is only passed explicitly to the stream helpers, which put it in the
URL because `WebSocket`/`EventSource` cannot set headers.

### 7.1 Engine configuration and call lifecycle

| Function | Endpoint | Parameters | Returns |
|---|---|---|---|
| `getConfig()` | `GET /call/config` | — | `{callsEnabled, callInboundMode, callRecord, callSttUrl, callLlmUrl, callTtsUrl, callSystemPrompt, callGreeting}` |
| `setConfig(params)` | `PUT /call/config` | `callsEnabled`, `callInboundMode` (`manual\|bot\|ivr\|ai\|webhook\|reject`), optional `callRecord`, `callSttUrl`, `callLlmUrl`, `callTtsUrl`, `callProviderToken`, `callSystemPrompt`, `callGreeting` | `{ok}` |
| `list()` | `GET /call/status` | — | `{calls: Array}` |
| `dial(params)` | `POST /call/dial` | `phone` — number, phone JID or `@lid` (see §2.3), `video?` | `{callId}` |
| `answer(params)` | `POST /call/answer` | `callId` | `{ok}` |
| `hangup(params)` | `POST /call/hangup` | `callId` | `{ok}` |
| `terminate(params)` | `POST /call/terminate` | `callId` | `{ok}` |

### 7.2 Media

| Function | Endpoint | Parameters | Returns |
|---|---|---|---|
| `play(params)` | `POST /call/play` | `callId`, `audioUrl?` \| `audioBase64?` | `{ok}` |
| `recordStart(params)` | `POST /call/record/start` | `callId` | `{ok}` |
| `recordStop(params)` | `POST /call/record/stop` | `callId` | `{ok, mediaKey}` |
| `setVideo(params)` | `POST /call/video` | `callId`, `enabled` | `{ok}` |
| `setScreenShare(params)` | `POST /call/screenshare` | `callId`, `enabled` | `{ok}` |

`setScreenShare` only **labels** the stream for peers — the screen pixels travel through
the same video websocket as the camera, because a call has a single video sender.

### 7.3 In-call interaction

| Function | Endpoint | Parameters | Returns |
|---|---|---|---|
| `reaction(params)` | `POST /call/reaction` | `callId`, `emoji` (a single emoji) | `{ok}` |
| `setHand(params)` | `POST /call/hand` | `callId`, `raised` | `{ok}` |

### 7.4 Group calls and the waiting room

| Function | Endpoint | Parameters | Returns |
|---|---|---|---|
| `groupState(params)` | `GET /call/{call_id}/group/state` | `callId` | roster with per-participant mute/hand/video flags |
| `waitingRoom(params)` | `GET /call/{call_id}/waiting-room` | `callId` | people asking to join |
| `admitParticipant(params)` | `POST /call/waiting-room/admit` | `callId`, `participant` (JID) | `{ok}` |
| `denyParticipant(params)` | `POST /call/waiting-room/deny` | `callId`, `participant` (JID) | `{ok}` |
| `setApprovalRequired(params)` | `POST /call/waiting-room/approval` | `callId`, `enabled` | `{ok}` |
| `addParticipants(params)` | `POST /call/participants/add` | `callId`, `participants` (JID array) | `{ok}` |
| `ringParticipant(params)` | `POST /call/participants/ring` | `callId`, `participant` (JID) | `{ok}` |

### 7.5 Streams

| Function | Endpoint | Parameters | Returns |
|---|---|---|---|
| `audioStream(params)` | `GET (WS) /call/{call_id}/stream` | `callId`, `token` | `WebSocket` (PCM both ways) |
| `videoStream(params)` | `GET (WS) /call/{call_id}/video/stream` | `callId`, `token`, `fmt?` (`"participant"` for per-camera demux) | `WebSocket` (Annex-B both ways) |
| `videoState(params)` | `GET (SSE) /call/{call_id}/video/state` | `callId`, `token` | `EventSource` |
| `events(params)` | `GET (SSE) /call/{call_id}/events` | `callId`, `token` | `EventSource` |

`events` is a stream rather than a poll because reactions are **transient**: there is no
state to read back afterwards.

### 7.6 Endpoints without an SDK wrapper

These are registered in `routes.go` and reachable over HTTP, but have no helper in the
`calls` module yet — call them directly:

`POST /call/group/dial`, `POST /call/group/dial-by-id`, `POST /call/link/create`,
`GET /call/link/preview`, `POST /call/link/join`, `GET /call/{call_id}/video/stats`.

The legacy signalling block (`/call/reject`, `/call/accept`, `/call/preaccept`,
`/call/terminate`, `/call/initiate`, `/call/reject/send`) belongs to the pre-engine call
plane and is out of scope for this guide.

### 7.7 `ZZ.sdk.calls.video` — the WebCodecs namespace

Not HTTP: browser-side helpers. `startSession(params)` wires a whole call (see §3); the
session it returns exposes `stats()`, `report(message)`, `captureKind()`,
`startScreenShare(acquired?)`, `stopScreenShare(resumeCamera?)`, `setCameraEnabled(bool)`,
`setCamera(deviceId)`, `rotateParticipant(id)`, `setParticipantOrientation(id, 0..3)`,
`resetParticipant(id)` and `stop()`.

`resetParticipant(id)` rebuilds one participant's decoder while **keeping** the tile. A
`VideoDecoder` that swallowed a corrupt access unit can keep accepting frames and painting
none, with nothing inside it noticing; recycling gives it a clean slate that waits for the
next IDR. Releasing the tile instead would drop the canvas, which reads to the user as the
participant leaving the call.

Building blocks: `isSupported()`, `canCaptureCamera()`, `createDecoder(params)`,
`createEncoder(params)`, `parseParticipantFrame(bytes)`, `hasIDR(bytes)`,
`hasParameterSets(bytes)`, `codecFromAnnexB(bytes)`, `fitEncoderSize(w,h,maxW,maxH)`,
`h264LevelFor(w,h,fps)`, `h264Codec(levelByte)`, plus the constants
`PARTICIPANT_FRAME_VERSION`, `SINGLE_STREAM_ID`, `H264_LEVELS` and
`H264_LEVEL_FPS_HEADROOM`.

The browser half of the participant framing and the encoder sizing are pinned by
`scripts/video-frame-parser-test.js`, which `go test` runs via
`TestBrowserParticipantFrameParser` against the **shipped** SDK file — not a copy of it.
