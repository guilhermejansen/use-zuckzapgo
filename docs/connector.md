# ZuckZapGo Connector

An embeddable, dependency-free widget that lets any app (the ZuckZapGo dashboard
or a third-party SaaS) pair a WhatsApp number — **QR**, **phone code**, or
**passkey** — without ever exposing the real instance token to the browser.
It is modeled on the z-api connector.

```html
<script src="https://YOUR-HOST/connector.js"></script>
<script>
  ZZ.connector.open({
    token: "ct_…",              // EPHEMERAL connector token (minted server-side)
    baseUrl: "https://YOUR-HOST",
    theme: "auto",              // 'light' | 'dark' | 'auto'
    locale: "pt",               // 'pt' | 'en'
    methods: { qr: true, phone: true, passkey: true },
  }).then((paired) => console.log("paired?", paired));
</script>
```

---

## Architecture

```
Partner app (any stack)                 ZuckZapGo (self-host)
  backend ──POST /session/connector/token (REAL token)──►  mint ephemeral (10min)
                       │ ephemeral token
  browser ◄───────────┘
    <script src="https://HOST/connector.js">
    ZZ.connector.open({ token: EPHEMERAL, baseUrl, … })
        │ polls 2s → /connector/{status, qr, passkey/status}
        │ QR / phone code ─────────────────► pairs a normal number
        └─ passkey required?
             → probe /connector/passkey/challenge
             → owner opens /passkey-bookmarklet.html with ephemeral token
             → bookmarklet runs WebAuthn on web.whatsapp.com
             → POST /connector/passkey/response → confirm → poll loggedIn
```

**Two tokens, one secret.** The *real* instance token authenticates the mint call
and lives only on the partner's backend. The *ephemeral* token (`ct_…`, default
10-minute TTL) is the only thing the browser ever holds, and it is accepted
**only** on the `/connector/*` routes — enforced by routing, translated back to
the real token server-side by `authConnector`.

---

## 1. Mint the ephemeral token (server-side)

Your backend mints the ephemeral token. Protect your own mint route with your
application's authentication and per-user authorization. The HTTP shape is:

```
POST {ZUCKZAPGO_URL}/session/connector/token
Header: token: <REAL instance token>
→ 200 { "code":200, "success":true, "data": { "token":"ct_…", "expiresIn":600, "tokenType":"connector" } }
```

Return only `data.token` to the browser. Never ship the real token to the client.

Rate-limited per real token via `CONNECTOR_TOKEN_RATE_PER_MIN` (default 60/min);
excess mints get `429`.

## 2. Embed the widget (browser)

```html
<script src="https://YOUR-HOST/connector.js"></script>
<script type="module">
  const { token } = await (await fetch("/my-backend/connector-token", { method: "POST" })).json();
  await ZZ.connector.open({ token, baseUrl: "https://YOUR-HOST" });
</script>
```

`ZZ.connector` (alias `ZZGConnector`) API:

| Method | Description |
|--------|-------------|
| `open(opts) → Promise<boolean>` | Opens the modal, drives pairing. Resolves `true` when paired (loggedIn), `false` if closed first. |
| `close()` | Tears down the modal. |
| `on(ev, fn)` / `off(ev, fn)` | Global event listeners. |

### Options

| Option | Default | Notes |
|--------|---------|-------|
| `token` | — | **Required.** Ephemeral token. |
| `baseUrl` | same origin | ZuckZapGo host (cross-origin embeds). |
| `theme` | `"auto"` | `light` \| `dark` \| `auto` (follows `prefers-color-scheme`). |
| `locale` | `"pt"` | `pt` \| `en`. |
| `methods` | all true | `{ qr, phone, passkey }` toggles. |
| `messages` | — | Override any i18n string (deep-merged over the locale). |
| `container` | `document.body` | CSS selector or element to mount into. |
| `pollIntervalMs` | `2000` | Status polling cadence. |
| `subscribe` | `["Message"]` | Events subscribed on connect. |
| `autoConnect` | `true` | POST `/connector/connect` on open. Set `false` when the instance is already connected. |
| `extensionInstallUrl` | `{}` | Legacy `{ chrome, firefox }` operator-provided links; no extension is distributed. |
| `bookmarkletUrl` | `/passkey-bookmarklet.html` | Fallback link. |

### Events

`open`, `status`, `qr`, `connected`, `error`, `close`. Each also
maps to an `on<Event>` callback in `open(opts)` (e.g. `onConnected`, `onStatus`,
`onError`). `status` fires on every poll with the raw `/connector/status` payload.

### Theming & i18n

Theme uses CSS custom properties inside a Shadow DOM (fully style-isolated from
the host page). Override any label:

```js
ZZ.connector.open({
  token,
  locale: "en",
  messages: { title: "Link your WhatsApp", tabPasskey: "Security key" },
});
```

---

## Passkey — owner-operated browser step

Some accounts require a passkey instead of QR/phone. The credential is scoped to
`whatsapp.com`, and WebAuthn must run at `https://web.whatsapp.com`, with the server's
`publicKey` options verbatim. Neither the dashboard nor an embed can perform the
ceremony on its own origin. See [Passkey Integration](./passkey-integration.md).

1. Probe `POST /connector/passkey/challenge`, then read `/connector/passkey/status`.
   Accounts outside the cohort can return `503 passkey_unavailable`.
2. Open `/passkey-bookmarklet.html` on the gateway. Provide its base URL and a
   freshly minted ephemeral `ct_…` token, or have your integration build a prefill
   URL with `?apiUrl=…&token=…`. The widget's default link does not mint or prefill it.
3. The owner drags the bookmarklet to their bookmarks bar, opens
   `https://web.whatsapp.com` and invokes it there. It uses `/connector/passkey/*`
   with `ct_…`, obtains the challenge, runs the authenticator and submits the assertion.
4. When `skipHandoffUX=false`, have the owner verify `confirmationCode` on the
   phone and POST `/connector/passkey/confirm`. Poll `/connector/status` until
   `loggedIn`; assertion submission alone is not completed pairing.

For the bookmarklet, include `https://web.whatsapp.com` as well as your embed's
origin in `CONNECTOR_CORS_ORIGINS`. Treat prefilled URLs and bookmarks as temporary
credentials and remove them after pairing. Browser/CSP restrictions and the
account's credentials can still prevent this flow from completing.

**No passkey browser extension is distributed.** The widget retains optional
bridge detection at `/connector.html` and the `extensionInstallUrl` option for
compatibility; neither provides an extension download. With no solver installed,
the widget exposes the bookmarklet action. A companion, when included in a platform
release package, is a separate trusted-operator path using the real user token on
`/session/*`; it cannot use a Connector token with those routes.

---

## Security

- **Real token never reaches the browser.** Mint server-side; only the ephemeral
  token is public. It is scoped to `/connector/*` by routing.
- **CORS allowlist.** Cross-origin embeds require the partner origin in
  `CONNECTOR_CORS_ORIGINS` (comma-separated; `*` for dev only). Preflight is
  answered before auth. Origins not on the list get no CORS headers, so the
  browser blocks the request.
- **Ephemeral TTL.** `CONNECTOR_TOKEN_TTL` (default 600s). A pruner removes
  expired tokens every minute.
- **Mint rate limit.** `CONNECTOR_TOKEN_RATE_PER_MIN` (default 60) per real token.
- **Origin isolation.** The bridge iframe validates `event.origin` against the
  ZuckZapGo origin and only accepts messages from its embedder.
- **Bookmarklet credentials.** Use an ephemeral Connector token for the browser
  flow. Do not expose the real instance token in an embed, URL or shared bookmark.

### Env vars

```env
CONNECTOR_CORS_ORIGINS=https://app.partner.com,https://other.com   # empty = same-origin only; * = dev
CONNECTOR_TOKEN_TTL=600                                             # ephemeral TTL (seconds)
CONNECTOR_TOKEN_RATE_PER_MIN=60                                     # mint cap per real token per minute
```

---

## Operational notes & known limits

- **In-memory state.** Ephemeral tokens and passkey state live in process memory.
  They are lost on restart and are **not shared across replicas**. For a
  multi-replica deployment, pin connector traffic to one replica (sticky) or move
  the store to Redis (future work). Documented, accepted for this release.
- **Handoff window.** WhatsApp's passkey handoff proof expires ~5 minutes after
  the challenge. If it lapses, reconnect to get a fresh challenge.
- **Passkey rate limit.** `POST /connector/passkey/response` is limited to one submission
  per user per 5s. If a user cancels the OS prompt and retries immediately, wait
  a moment before resubmitting.

---

## Live validation runbook

Pairing must be checked with a real authorized account and the owner's authenticator.
This documentation update does not provide new runtime or live-account evidence.

1. Configure `CONNECTOR_CORS_ORIGINS` with the embed origin and, for the
   bookmarklet path, `https://web.whatsapp.com`.
2. Open the dashboard at `/dashboard/` or an app that uses `/connector.js`.
   Mint an ephemeral token on your authenticated backend and open the widget.
3. Pair a normal account using QR/phone. For a passkey account, follow the
   bookmarklet steps above and explicitly complete confirmation when required.
4. Check `/connector/status` for `loggedIn`; do not infer success from a `200`
   assertion response alone. On failure, inspect sanitized status/error fields,
   the browser's origin and the challenge lifetime. Never share raw assertion,
   QR, token or session material in support logs.
