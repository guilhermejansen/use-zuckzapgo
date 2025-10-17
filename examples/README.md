# 📚 Exemplos de Mensagens Interativas

Use estes arquivos prontos para testar rapidamente os recursos avançados da API.
> ✅ **Dica**: substitua `https://api.seudominio.com` e `SEU_TOKEN_AQUI` pelos valores do seu ambiente.

---

## 🔘 1. Botões (reply / URL / call)
```bash
curl -X POST https://api.seudominio.com/chat/send/buttons \
  -H "token: SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  --data @examples/buttons-basic.json
```

## 💸 2. Botões com Pix e copiar código
```bash
curl -X POST https://api.seudominio.com/chat/send/buttons \
  -H "token: SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  --data @examples/buttons-pix.json
```

> ℹ️ Recursos com Pix, flows e carrossel exigem licença **Enterprise**.

## 📋 3. Lista interativa
```bash
curl -X POST https://api.seudominio.com/chat/send/list \
  -H "token: SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  --data @examples/list-basic.json
```

## 🎠 4. Carrossel com imagem, vídeo e documento
```bash
curl -X POST https://api.seudominio.com/chat/send/carousel \
  -H "token: SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  --data @examples/carousel-basic.json
```

## 📅 5. Evento (calendário/agenda)
```bash
curl -X POST https://api.seudominio.com/chat/send/event \
  -H "token: SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  --data @examples/event-basic.json
```

---

### ✅ Antes de testar
- Garanta que a sessão esteja conectada (`/session/connect`) e que a licença Enterprise esteja ativa para recursos avançados.
- Altere o campo `"Phone"` para o número desejado (com DDI + DDD, apenas dígitos).
- Ajuste URLs de mídia/callback conforme necessário.
- Utilize `NumberCheck: true` se quiser validar automaticamente se o telefone tem WhatsApp.

Bom proveito! 🚀
