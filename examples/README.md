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

## 🆕 Novidades da v2.5.0

### 🗓️ 6. Evento com link, como na aba Eventos do aplicativo
Cria o evento no WhatsApp e devolve `data.event_invite`, que vai como está em `POST /chat/send/event-invite` para compartilhar o convite num chat. `start_time` e `end_time` são Unix em segundos e o início precisa estar no futuro: ajuste antes de testar.
```bash
curl -X POST https://api.seudominio.com/event/create \
  -H "token: SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  --data @examples/event-link-create.json
```

### 👥 7. Convite de grupo no chat individual ("Enviar convite")
Quando a privacidade da pessoa recusa a adição em `POST /group/updateparticipants`, a resposta traz `add_request` com `code` e `expiration`. Envie esses valores para a pessoa aceitar pela própria conta.
```bash
curl -X POST https://api.seudominio.com/chat/send/group-invite \
  -H "token: SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  --data @examples/group-invite.json
```

### 🗳️ 8. Voto em enquete de canal
`options` usa o nome exato de cada opção; uma lista vazia retira o voto. A rota confere a enquete antes de enviar e recusa com 409, sem enviar, quando a publicação não é enquete ou a opção não existe. A contagem por opção leva alguns minutos para refletir o voto, também nos aplicativos.
```bash
curl -X POST https://api.seudominio.com/newsletter/poll-vote \
  -H "token: SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  --data @examples/newsletter-poll-vote.json
```

---

### ✅ Antes de testar
- Garanta que a sessão esteja conectada (`/session/connect`) e que a licença Enterprise esteja ativa para recursos avançados.
- Altere o campo `"Phone"` (ou `"phone"`, nos exemplos novos) para o número desejado (com DDI + DDD, apenas dígitos), e os JIDs de grupo e de canal para os seus.
- Ajuste URLs de mídia/callback conforme necessário.
- Utilize `NumberCheck: true` se quiser validar automaticamente se o telefone tem WhatsApp.

Bom proveito! 🚀
