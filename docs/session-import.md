# Session Import (Path B) — native Go conversion of a web.whatsapp.com session

**Status: BETA · impersonation-grade — treat the payload as a live account secret.**

Path B is the alternative to forwarding a WebAuthn assertion
([`passkey-integration.md`](./passkey-integration.md)). Instead of pairing, it takes an
**existing `web.whatsapp.com` session** and converts it into a native whatsmeow device
in Go, then boots it — **without any new database migration** (it writes through the
existing session store).

Use it only when Path A is not viable and you accept the higher fragility and ToS risk.

---

## 1. When to use it

| | Path A (WebAuthn) | Path B (import) |
|---|---|---|
| Mechanism | forward a fresh assertion | import an existing web session |
| Device type | first-class linked device | reconstructed device |
| Fragility | low | higher (depends on WA-Web internals) |
| ToS risk | lower | higher |
| Recommendation | **default** | opt-in |

---

## 2. Endpoint

```
POST /session/import
Header: token: <real per-instance user token>
```

Accepts **either** shape:

### 2.1 Structured `WebDeviceSnapshot` (recommended, fully supported)

```jsonc
{
  "meJid": "5521999999999:0@s.whatsapp.net",   // required — device JID
  "lid": "111111111111111:0@lid",              // optional
  "registrationId": 12345,                      // required, non-zero
  "noiseKey":    { "priv": "YOUR_NOISE_KEY_PRIVATE_BASE64_32_BYTES" }, // required
  "identityKey": { "priv": "YOUR_IDENTITY_KEY_PRIVATE_BASE64_32_BYTES" }, // required
  "signedPreKey": {                             // required
    "keyId": 1,
    "priv": "YOUR_SIGNED_PRE_KEY_PRIVATE_BASE64_32_BYTES",
    "signature": "base64-64-bytes"              // signature by the identity key
  },
  "account": {                                  // required — ADVSignedDeviceIdentity
    "details": "base64",
    "accountSignature": "base64",
    "accountSignatureKey": "YOUR_ACCOUNT_SIGNATURE_KEY_BASE64",
    "deviceSignature": "base64"
  },
  "advSecretKey": "YOUR_ADV_SECRET_KEY_BASE64_32_BYTES",            // optional (app-state secret)
  "platform": "web", "pushName": "…", "businessName": "…"  // optional
}
```

All binary fields are base64 (std or url; padded or not). The converter validates every
required field and **never fabricates key material**.

### 2.2 Generic wa-web dump (companion `--mode=dump`)

```jsonc
{ "source": "wa-web", "localStorage": { ... }, "indexeddb": { ... } }
```

The backend attempts best-effort extraction. Because the exact WA-Web IndexedDB schema is
not validated end-to-end here, it **honestly returns `422`** with the list of fields it
could not resolve, rather than guessing:

```json
{
  "error": "incomplete wa-web dump: auto-extraction could not resolve required fields",
  "missing": ["meJid", "registrationId", "noiseKey", "identityKey", "signedPreKey", "account"],
  "hint": "supply a structured WebDeviceSnapshot — see docs/session-import.md"
}
```

Until a validated dumper populates the required fields, provide the **structured
snapshot** (2.1).

---

## 3. Responses

| Status | Meaning |
|---|---|
| `200` | Imported; device booting. Poll `GET /session/status` until `loggedIn`. |
| `400` | Invalid/unrecognized payload. |
| `422` | Snapshot conversion failed OR incomplete generic dump (see `missing`). |
| `500` | Container unavailable or persist failed. |

`200` body:

```json
{ "status": "imported", "jid": "5521999999999:0@s.whatsapp.net",
  "note": "device booting (BETA); poll /session/status for loggedIn" }
```

---

## 4. How the conversion works (no new migration)

1. `container.NewDevice()` seeds a fresh device (keys + store backends).
2. `applySnapshotToDevice` overrides the identity fields from the snapshot:
   `ID`, `LID`, `RegistrationID`, `NoiseKey`, `IdentityKey`, `SignedPreKey` (+64-byte
   signature), `Account` (`ADVSignedDeviceIdentity`), and `AdvSecretKey` (kept fresh when
   omitted). `Initialized` stays `false` so `PutDevice` wires the SQL-backed stores.
3. `container.PutDevice(...)` persists through the **existing** sqlstore schema — **no new
   migration**.
4. The JID is written to the `users` table and the device boots via the same `startClient`
   path a normal connect uses (`GetDevice(jid)` → connect).

Deeper signal state (pre-existing sessions/prekeys) is re-established by the server on
reconnect where the protocol allows; interop with pre-existing conversations is **BETA**
until validated on a real device.

---

## 5. Caveats (documented, not hidden)

- **Premature dump → `logged_out_401`.** Dump only after the web session is *stable*
  (the companion waits for a stable login before extracting).
- **Noise-key fragility.** A wrong/truncated noise key surfaces as a distinct connection
  error, not a silent hang.
- **App-state resync.** When `advSecretKey` is absent, the imported device uses a fresh
  one; app-state (contacts/chat settings) may need a resync — messaging still works.
- **Single-instance state.** As with passkey, the boot happens on one node.

---

## 6. Security (mandatory)

- The snapshot is **impersonation-grade** — anyone holding it controls the account.
- **Authentication:** `/session/import` requires the real per-instance user token
  in the `token` header. The companion's `--pair-code` flag is only an alias for
  this credential; it does not mint or scope a new one. Connector `ct_…` tokens
  are restricted to `/connector/*` and do not authenticate session import. Keep
  the real token on a trusted operator machine/backend; never expose it in an embed.
- **Always HTTPS.**
- The companion **never writes the dump to disk** and **wipes the browser session** after
  a successful import.
- **Never log the dump.** The backend logs only the resulting JID and the field-level
  `missing` list — never key material.
- Consider an audit-log entry (who imported which JID, when) at your integration layer.

---

## 7. ToS

Extracting and re-hosting a WhatsApp Web session may violate WhatsApp's Terms. Path B is
**opt-in and documented**; Path A (WebAuthn) is the default precisely because it links a
device the normal way. Use Path B deliberately, for accounts you own, with consent.
