# Passkey Integration Guide — pairing WhatsApp accounts in the passkey cohort

This guide shows how to link a WhatsApp account that WhatsApp has enrolled in its
**server-driven passkey cohort** — the accounts that receive a `PairPasskeyRequest`
instead of a QR code — from **any platform** (n8n, PHP, Java, curl, Node, Go, a
browser dashboard).

> **TL;DR:** accounts in the cohort require a **real WebAuthn assertion** produced by
> the account owner's authenticator at the **origin `https://web.whatsapp.com`**. You
> cannot do it headless and you cannot host the ceremony on your own domain. Deliver
> the browser step with the **bookmarklet** or a **packaged companion binary**, when
> included in your platform release. Browser and account support still require validation.

---

## 1. The one fact that breaks integrations: rpId vs. origin

| | Value | Note |
|---|---|---|
| **rpId** (relying-party id) | `whatsapp.com` | What the credential is scoped to |
| **origin** (where the ceremony runs) | `https://web.whatsapp.com` | The page `navigator.credentials.get()` runs in |

- The client **never constructs the rpId.** Pass the server's `publicKey` object from
  `GET /session/passkey/status` **verbatim** to `navigator.credentials.get({ publicKey })`.
- Building your own rpId (e.g. hardcoding `web.whatsapp.com`) causes a **silent server
  rejection** — "it just won't connect". This was the #1 bug in earlier integrations.

---

## 2. Cohort matrix — which path applies

| Account state | How to pair | Headless possible? |
|---|---|---|
| **Not** in passkey cohort | QR code or pair-code (existing `/session/qr`, `/session/pairphone`) | ✅ Yes |
| In cohort, `PairPasskeyRequest` arrives | **Path A** (forward WebAuthn) or **Path B** (import) | ❌ No — owner's browser required |

Detect the cohort at runtime: after `POST /session/connect`, poll
`GET /session/passkey/status`. If `required=true` with a `challenge`, you are in the
cohort.

---

## 3. Two native paths

### Path A — forward the WebAuthn assertion (default, recommended)

A browser context on `web.whatsapp.com` runs `navigator.credentials.get(publicKey)` and
POSTs the assertion to `POST /session/passkey/response`. whatsmeow becomes a first-class
linked device. Lowest ToS risk.

### Path B — import an existing session (BETA)

The owner logs into `web.whatsapp.com`; a dumper extracts the session and POSTs it to
`POST /session/import`, which converts it to a native device in Go. More fragile, higher
ToS risk — opt-in. See [`session-import.md`](./session-import.md).

Both paths for the cohort need **one browser touch** by the owner. The only choice is
packaging.

---

## 4. Delivering the browser step

### 4.1 Zero-install bookmarklet

The dashboard serves `/passkey-bookmarklet.html`. The owner drags the bookmarklet to
their bar, opens `web.whatsapp.com`, and clicks it. It polls `/session/passkey/status`,
runs `navigator.credentials.get` with the server `publicKey` verbatim, and POSTs the
assertion. Add `https://web.whatsapp.com` to `CONNECTOR_CORS_ORIGINS` for requests
from that page. The operator still needs a compatible browser and the account's
authenticator; submission alone is not proof of completed pairing. For an embedded
app, use an ephemeral `ct_…` token and `/connector/passkey/*` as described in
[Connector](./connector.md), keeping the real instance token on your backend.

### 4.2 Single companion binary (Go, no Node, no extension)

A companion can drive Chrome/Chromium via the DevTools Protocol; it does not bundle
that browser. Download the gateway package for your platform from
[public releases](https://github.com/guilhermejansen/use-zuckzapgo/releases) and check whether
`passkey-companion` (Windows: `passkey-companion.exe`) is included. If it is absent,
use the bookmarklet. You do not need access to private source or a build environment
to use a packaged executable.

From the extracted package on Linux/macOS:

```bash
# Path A — forward WebAuthn; use the actual per-instance token
./passkey-companion --api https://your-host --token "<USER_TOKEN>" --mode webauthn

# Path B — import (BETA); generic dumps can return 422 for missing fields
./passkey-companion --api https://your-host --token "<USER_TOKEN>" --mode dump
```

On Windows, invoke `passkey-companion.exe` with the same arguments. These calls use
`/session/*` and require the real user token. The `--pair-code` flag is only an alias
for the credential passed as `token`; this gateway does not mint a separate scoped
pairing code for those routes. A random code or Connector `ct_…` token will not work.
Run only on the trusted operator's machine and protect shell history/process visibility.

**No browser extension is distributed or required by these paths.** Completion still
depends on the real account, authenticator, browser, network and WhatsApp acceptance.

---

## 5. Orchestration for non-browser platforms

n8n, PHP, Java, and curl integrations **never run WebAuthn**. They orchestrate and poll,
handing the browser step to the owner (bookmarklet or companion).

### 5.1 The flow

```
POST /session/connect            → start; WhatsApp may send PairPasskeyRequest
   ↓ poll every ~2.5s
GET  /session/passkey/status     → required=true & challenge set?
   ↓  (hand the browser step to the owner: bookmarklet or companion)
   ↓ poll every ~2.5s
GET  /session/status             → loggedIn=true?  → done
```

### 5.2 n8n recipe (HTTP Request nodes)

1. **HTTP Request** — `POST {{base}}/session/connect`, header `token`, body
   `{ "Subscribe": ["Message"], "Immediate": true }`.
2. **HTTP Request** — `GET {{base}}/session/passkey/status?token={{token}}` inside a
   **Loop** (Wait node 2.5s) until `{{$json.data.required}} === true`.
3. **Set / Notify** — surface the bookmarklet URL (`{{base}}/passkey-bookmarklet.html`)
   or instruct the owner to run the companion. (n8n cannot perform WebAuthn itself.)
4. **HTTP Request** — `GET {{base}}/session/status?token={{token}}` inside a **Loop**
   (Wait 2.5s) until `{{$json.data.loggedIn}} === true`.
5. Continue your workflow — the session is live.

### 5.3 curl

```bash
BASE=https://your-host; TOKEN=YOURTOKEN
curl -s -X POST "$BASE/session/connect" -H "token: $TOKEN" \
  -H 'Content-Type: application/json' -d '{"Subscribe":["Message"],"Immediate":true}'
# poll challenge
until curl -s "$BASE/session/passkey/status?token=$TOKEN" | grep -q '"required":true'; do sleep 2.5; done
echo "Passkey required — open $BASE/passkey-bookmarklet.html on web.whatsapp.com, or run the companion."
# poll login
until curl -s "$BASE/session/status?token=$TOKEN" | grep -q '"loggedIn":true'; do sleep 2.5; done
echo "Paired."
```

### 5.4 Python

```python
import time, requests
BASE = "https://your-host"
TOKEN = "YOURTOKEN"
h = {"token": TOKEN}
requests.post(f"{BASE}/session/connect", headers=h, json={"Subscribe": ["Message"], "Immediate": True})
while not requests.get(f"{BASE}/session/passkey/status", headers=h).json()["data"]["required"]:
    time.sleep(2.5)
print("Passkey required — owner runs bookmarklet/companion.")
while not requests.get(f"{BASE}/session/status", headers=h).json()["data"]["loggedIn"]:
    time.sleep(2.5)
print("Paired.")
```

### 5.5 PHP

```php
<?php
$base = "https://your-host"; $token = "YOURTOKEN";
function req($m,$u,$t,$b=null){ $c=curl_init($u); curl_setopt_array($c,[
  CURLOPT_CUSTOMREQUEST=>$m, CURLOPT_RETURNTRANSFER=>true,
  CURLOPT_HTTPHEADER=>["token: $t","Content-Type: application/json"],
  CURLOPT_POSTFIELDS=>$b?json_encode($b):null ]); $r=curl_exec($c); curl_close($c); return json_decode($r,true); }
req("POST","$base/session/connect",$token,["Subscribe"=>["Message"],"Immediate"=>true]);
do { sleep(3); $s=req("GET","$base/session/passkey/status?token=$token",$token); } while(!$s["data"]["required"]);
echo "Passkey required — owner runs bookmarklet/companion.\n";
do { sleep(3); $s=req("GET","$base/session/status?token=$token",$token); } while(!$s["data"]["loggedIn"]);
echo "Paired.\n";
```

### 5.6 Node

```js
const base = "https://your-host", token = "YOURTOKEN";
const h = { token, "Content-Type": "application/json" };
const get = (p) => fetch(`${base}${p}`, { headers: h }).then((r) => r.json());
await fetch(`${base}/session/connect`, { method: "POST", headers: h, body: JSON.stringify({ Subscribe: ["Message"], Immediate: true }) });
while (!(await get(`/session/passkey/status`)).data.required) await new Promise((r) => setTimeout(r, 2500));
console.log("Passkey required — owner runs bookmarklet/companion.");
while (!(await get(`/session/status`)).data.loggedIn) await new Promise((r) => setTimeout(r, 2500));
console.log("Paired.");
```

### 5.7 Go

```go
// A packaged companion can drive connect+poll+WebAuthn with the owner present.
// For pure orchestration, mirror the curl flow: POST /session/connect, poll
// /session/passkey/status until required, hand off the browser step, poll
// /session/status until loggedIn.
```

### 5.8 Generate a client for any language

The full OpenAPI spec is served at `/api/spec.yml`. Generate an SDK for 50+ languages:

```bash
openapi-generator-cli generate -i https://your-host/api/spec.yml -g python -o ./client-python
```

---

## 6. Webhook events (drive UI outside the dashboard)

The event dispatcher emits (subscribe via webhook/SSE):

- `type: "PasskeyRequest"` — carries `publicKey` (the WebAuthn challenge).
- `type: "PasskeyConfirmation"` — carries `code` and `skipHandoffUX`.

---

## 7. Confirmation step

- `skipHandoffUX=true` → the backend auto-confirms; nothing more to do.
- `skipHandoffUX=false` → render `confirmationCode` from `/session/passkey/status`, have
  the owner verify it on their phone, then `POST /session/passkey/confirm`.

---

## 8. Operational notes

- **State is in-memory, single-instance.** The passkey challenge lives for **12 minutes**
  (covers the server's 10-minute WebAuthn `timeout`). Behind a round-robin load balancer,
  use **sticky sessions** or a **dedicated replica** during the pairing window.
- **Authentication:** `/session/*` requires the real user token. Do not treat the
  companion's `--pair-code` alias as a new scoped credential. For an embedded
  browser flow, use a minted Connector token on `/connector/*` instead.
- **Security:** always HTTPS. The dump path (B) is impersonation-grade — see
  [`session-import.md`](./session-import.md).

---

## 9. Endpoint reference

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/session/connect` | Start; may trigger `PairPasskeyRequest` |
| `GET`  | `/session/passkey/status` | Poll challenge, confirmation code, state |
| `POST` | `/session/passkey/response` | Submit WebAuthn assertion (path A) |
| `POST` | `/session/passkey/confirm` | Final confirmation when `skipHandoffUX=false` |
| `POST` | `/session/import` | Import an existing session (path B, BETA) |
| `GET`  | `/session/status` | Poll `loggedIn` |
