# ZuckZapGo — WhatsApp API Gateway

**ZuckZapGo**, da Setup Automatizado, é um gateway REST auto-hospedado para conectar números WhatsApp, trocar mensagens e distribuir eventos para suas integrações. Inclui dashboard web, sessões independentes por usuário e engine nativo de chamadas.

Este é o repositório público de apoio: documentação, contratos de API, Postman, configurações e acesso aos pacotes de distribuição. O código do servidor tem licença comercial. A integração usa o protocolo de aparelhos vinculados; **não é a API oficial da Meta/WhatsApp**. Mudanças no serviço, restrições de conta e regras do WhatsApp podem afetar os recursos. Use contas e destinatários autorizados.

[Documentação](docs/INDEX.md) · [Guias para LLMs](llms.txt) · [Releases](https://github.com/guilhermejansen/use-zuckzapgo/releases) · [Changelog](CHANGELOG.md)

## O que você pode integrar

| Grupo | Recursos |
|---|---|
| Sessões e dispositivos | Múltiplas sessões, QR, código por telefone, status, reconexão e preferências por usuário. Passkey depende da conta e do autenticador do titular. |
| Mensagens | Texto, resposta/citação, imagens, áudio, vídeo, documentos, stickers, contatos, localização, links, reações, listas e enquetes. |
| Interativos e negócios | Botões, carrosséis, flows, catálogo, produtos, coleções, pedidos e cobranças, conforme contrato e licença da distribuição. |
| Conversas e organização | Presença, leitura, arquivamento, fixação, silenciamento, etiquetas e favoritos; disponibilidade depende da sincronização da conta. |
| Grupos, comunidades e canais | Participantes, permissões, convites, comunidades, newsletters e status. Cada operação respeita as permissões da conta. |
| Eventos | Webhooks individuais/globais, RabbitMQ, Amazon SQS, Redis Streams e WebSocket; filtros, retries, buffer persistente, DLQ e replay administrativo. |
| Mídia e armazenamento | Upload/download, thumbnails e S3 compatível, com configuração global/por usuário e retenção configurável. |
| Pareamento em aplicativos | Connector incorporável com token efêmero, QR/código e encaminhamento do passo de passkey ao titular. |
| Rede | Proxy por sessão e rota móvel nativa via Tailscale/tsnet, com versionamento e controle de prontidão. |
| Chamadas nativas | Controle de chamadas no gateway, áudio PCM por WebSocket, reprodução e gravação em S3. Vídeo H.264 e recursos de grupo/link têm condições próprias. |
| Operação | Dashboard, `/health`, monitoramento SSE, métricas, Sentry e tracing OpenTelemetry/Jaeger, conforme configuração. |

Não há promessa de capacidade ilimitada: dimensione sessões, mídia, filas e conexões conforme seus recursos e sua carga real.

## Licença e identidade da distribuição

| Item | Valor |
|---|---|
| Produto | ZuckZapGo |
| Repositório público | [guilhermejansen/use-zuckzapgo](https://github.com/guilhermejansen/use-zuckzapgo) |
| Imagem | `setupautomatizado/zuckzapgo-private` |
| Registro | Docker Hub |
| Prefixo das variáveis do servidor | `ZUCKZAPGO_` |
| Licença | Comercial, informada em `LICENSE_KEY` |

Botões, carrosséis, flows, shop e operações de envio de pedidos/cobranças protegidas exigem licença Enterprise. Leituras e demais rotas seguem seus próprios contratos.

`LICENSE_KEY` não usa o prefixo do produto. `DATABASE_URL`, `GLOBAL_*`, `CONNECTOR_*` e `NETWORK_ROUTE_*` também mantêm esses nomes. O token administrativo é `ZUCKZAPGO_ADMIN_TOKEN`; ele é diferente da licença e do token de cada sessão.

## Quick Start com Docker Compose

Pré-requisitos: Docker com Compose v2 e uma licença válida. O exemplo cria um PostgreSQL dedicado, preserva seus dados em volume e expõe o gateway somente em `127.0.0.1:8080`. Crie os dois arquivos abaixo em uma pasta nova, sem substituir os de uma instalação existente.

### 1. Configure `.env`

```dotenv
DOCKER_TAG=v2.4.2
LICENSE_KEY=SUBSTITUA_PELA_SUA_LICENCA
ZUCKZAPGO_ADMIN_TOKEN=SUBSTITUA_POR_UM_TOKEN_ALEATORIO
POSTGRES_PASSWORD=SUBSTITUA_POR_UMA_SENHA_ALEATORIA_HEXADECIMAL
```

Gere valores diferentes para o token administrativo e a senha, por exemplo com `openssl rand -hex 32`. A senha hexadecimal pode entrar na URI PostgreSQL sem escape adicional. Proteja o `.env` e mantenha-o fora do Git. Nunca use as strings de substituição como credenciais.

### 2. Salve como `compose.yaml`

```yaml
services:
  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?defina POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d app"]
      interval: 5s
      timeout: 5s
      retries: 10
  gateway:
    image: setupautomatizado/zuckzapgo-private:${DOCKER_TAG:?defina DOCKER_TAG}
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "127.0.0.1:8080:8080"
    environment:
      LICENSE_KEY: ${LICENSE_KEY:?defina LICENSE_KEY}
      ZUCKZAPGO_ADMIN_TOKEN: ${ZUCKZAPGO_ADMIN_TOKEN:?defina ZUCKZAPGO_ADMIN_TOKEN}
      ZUCKZAPGO_ADDRESS: http://localhost:8080
      ZUCKZAPGO_PORT: "8080"
      DATABASE_URL: postgres://app:${POSTGRES_PASSWORD:?defina POSTGRES_PASSWORD}@postgres:5432/app?sslmode=disable
      GLOBAL_EVENT_BUFFER_USE_DATABASE: "true"
volumes:
  postgres_data:
```

O `sslmode=disable` acima vale para a rede interna deste exemplo. Em produção, configure o banco e seu TLS, publique o gateway atrás de HTTPS e ajuste `ZUCKZAPGO_ADDRESS` para a URL que seus consumidores realmente acessam. Deixe `SESSION_DEVICE_NAME` sem configuração para herdar a identidade nativa do dispositivo.

### 3. Inicie e confira

```bash
docker compose pull
docker compose up -d
curl --fail-with-body http://localhost:8080/health
```

Abra o dashboard em `http://localhost:8080/dashboard/` e a referência da instância em `http://localhost:8080/api/`. Se o startup falhar, consulte `docker compose logs gateway`; licença, conexão com banco e migrações precisam estar válidas antes do pareamento.

O exemplo fixa a versão `v2.4.2`. Leia as notas da versão antes de atualizar; `latest` pode mudar. Os arquivos completos [`.env.sample`](.env.sample), [Compose](docker-compose.yml) e [Swarm](docker-compose-swarm.yaml) são referências que precisam de configuração para seu ambiente.

## Primeira sessão pela API

Os comandos abaixo usam Bash/Zsh, `curl` e `openssl`. Execute-os na pasta do `.env` criado acima, já preenchido, para reutilizar o mesmo token administrativo.

```bash
set -a
. ./.env
set +a
BASE_URL='http://localhost:8080'
USER_TOKEN="$(openssl rand -hex 32)"

curl --fail-with-body -X POST "$BASE_URL/admin/users" \
  -H "Authorization: $ZUCKZAPGO_ADMIN_TOKEN" \
  -H 'Content-Type: application/json' \
  --data "{\"name\":\"primeira-sessao\",\"token\":\"$USER_TOKEN\",\"events\":\"Message\"}"
```

Guarde o token de usuário em seu gerenciador de segredos. A criação devolve o ID e as configurações da sessão; ela não significa que o WhatsApp já está pareado.

```bash
curl --fail-with-body -X POST "$BASE_URL/session/connect" \
  -H "token: $USER_TOKEN" \
  -H 'Content-Type: application/json' \
  --data '{"Subscribe":["Message"],"Immediate":true}'

curl --fail-with-body "$BASE_URL/session/qr" -H "token: $USER_TOKEN"
curl --fail-with-body "$BASE_URL/session/status" -H "token: $USER_TOKEN"
```

Use o QR no dashboard ou renderize a imagem devolvida por `/session/qr`. O QR pode demorar a ficar disponível. `Immediate:true` retorna antes do término da conexão; confirme `connected` e `loggedIn` no status. Para código por telefone, consulte `POST /session/pairphone` no OpenAPI. Se a conta exigir passkey, siga o [guia de passkey](docs/passkey-integration.md).

Depois de parear, um envio de texto para **um destinatário autorizado** segue este formato. Substitua `DESTINO_E164` por país, DDD e número somente com dígitos:

```bash
DESTINO_E164='SUBSTITUA_PELO_NUMERO_AUTORIZADO'
curl --fail-with-body -X POST "$BASE_URL/chat/send/text" \
  -H "token: $USER_TOKEN" \
  -H 'Content-Type: application/json' \
  --data "{\"Phone\":\"$DESTINO_E164\",\"Body\":\"Olá! Mensagem de integração.\"}"
```

### Autenticação e respostas

| Superfície | Credencial |
|---|---|
| Gestão administrativa, como `/admin/users` | Header `Authorization: <ADMIN_TOKEN>`; também aceita `Bearer <ADMIN_TOKEN>` |
| Sessões, chat, grupos, negócios e chamadas | Header `token: <USER_TOKEN>` da sessão |
| Connector no navegador | Token efêmero `ct_…`, emitido pelo backend com o token real |
| SSE de monitoramento administrativo | Token de sessão de monitoramento emitido por `/admin/events/session`; consulte o OpenAPI |

Não use o admin token no header `token`. Em REST, prefira headers a parâmetros de URL. Clientes WebSocket/EventSource de navegador podem exigir `?token=…`; proteja esses URLs contra logs e compartilhamento.

As respostas JSON normalmente usam `{ "code": 200, "success": true, "data": {} }`; falhas trazem `success:false` e `error`. Confira o status HTTP e o schema da operação. Leia o payload em `data` quando houver esse envelope.

## Documentação, OpenAPI e LLMs

| Arquivo | Conteúdo |
|---|---|
| [docs/INDEX.md](docs/INDEX.md) | Índice dos guias públicos |
| [llms.txt](llms.txt) | Ponto de entrada para assistentes e descoberta dos contratos |
| [api/llm.txt](api/llm.txt) | Chamadas nativas: autenticação, controle, PCM/H.264, exemplos e limites |
| [api/connector-llm.txt](api/connector-llm.txt) | Connector: emissão de token, embed, pareamento e segurança |
| [api/network-route-llm.txt](api/network-route-llm.txt) | Rota móvel: provisionamento, versões, prontidão e recuperação |
| [api/spec.yml](api/spec.yml) | OpenAPI 3, referência para integração e geração de clientes |
| [api/swagger.json](api/swagger.json) / [api/swagger.yaml](api/swagger.yaml) | Contratos Swagger gerados |
| [ZuckZapGo.postman_collection.json](ZuckZapGo.postman_collection.json) | Collection Postman da marca |
| [ZuckZapGo.postman_environment.json](ZuckZapGo.postman_environment.json) | Environment Postman; preencha host, admin e token da sessão |

Os arquivos `api/*` deste repositório correspondem aos servidos em `/api/*` pelo gateway. Use os contratos da versão instalada; o conteúdo de `main` pode acompanhar documentação mais recente. Ao usar um LLM, forneça também os limites abaixo e confira os nomes e tipos dos campos no OpenAPI.

| Guia | Para que serve |
|---|---|
| [Instalação](docs/INSTALL.md) | Distribuição e configuração inicial |
| [Configuração](docs/CONFIGURATION.md) | Banco, variáveis, transportes e observabilidade |
| [Eventos e webhooks](docs/webhook-events.md) | Envelope, enriquecimento e eventos de domínio |
| [Connector](docs/connector.md) | Incorporar o pareamento no seu aplicativo |
| [Passkey](docs/passkey-integration.md) | Passo do titular no navegador e confirmação |
| [Importação de sessão](docs/session-import.md) | Alternativa BETA com snapshot sensível |
| [Rota móvel](docs/network-route.md) | Egresso por sessão, persistência e operação |
| [Áudio de chamadas](docs/call-audio-implementation-guide.md) | Controle, stream e gravação |
| [Vídeo de chamadas](docs/call-video-guide.md) | H.264, codecs, grupos e limitações |
| [Integração de chamadas no navegador](docs/whatsapp-web-call-integration.md) | Fluxos de integração com o gateway |

## Connector, passkey e importação

Seu backend chama `POST /session/connector/token` com o token real da sessão e entrega somente o token efêmero ao widget em `/connector.js`. Configure `CONNECTOR_CORS_ORIGINS` com as origens permitidas. Tokens efêmeros e estado de passkey são locais ao processo; mantenha afinidade de réplica durante o pareamento.

Passkey exige o autenticador do titular e a cerimônia WebAuthn em `https://web.whatsapp.com`. O bookmarklet servido em `/passkey-bookmarklet.html` encaminha a resposta ao gateway; inclua `https://web.whatsapp.com` nas origens permitidas em `CONNECTOR_CORS_ORIGINS`. O companion exige Chrome/Chromium e só deve ser usado quando seu executável estiver incluído no pacote da plataforma. Não há extensão passkey distribuída para instalar nem garantia de funcionamento sem interação do titular.

`POST /session/import` é **BETA**. O snapshot contém segredos equivalentes à sessão e depende da estrutura do WhatsApp Web; um dump incompleto pode retornar `422`. Prefira o pareamento normal/por passkey e use importação apenas como decisão explícita do operador.

## Chamadas: disponibilidade e limites

- O engine nativo roda junto ao gateway. Habilite `callsEnabled` em `PUT /call/config` e reconecte a sessão. Use `manual` para seu aplicativo controlar o atendimento e o áudio; `webhook` atende automaticamente e emite eventos.
- Saída com mídia usa `POST /call/dial`; `/call/initiate` responde `501` por padrão e só vira alias de dial com `GLOBAL_CALL_INITIATE_DIAL_ALIAS=true`.
- Áudio bidirecional: `/call/{call_id}/stream`, PCM **s16le, 16 kHz, mono**, quadros de **960 amostras / 1920 bytes / 60 ms**. O áudio começa após o atendimento; sinalização de chamada não prova fluxo de mídia.
- Vídeo: H.264 Annex-B no stream próprio, com codec no cliente. A API não converte automaticamente câmera, WebRTC, SDP ou SIP; confira o guia e valide sua combinação de cliente, conta e rede. Limites de participantes são impostos pelo WhatsApp.
- Os modos `bot`, `ivr` e `ai` são aceitos na configuração, mas o voice agent embutido está **indisponível**: nesses modos as chamadas recebidas são rejeitadas. Preencher URLs de STT/LLM/TTS não habilita o agente. Uma integração externa pode processar PCM em `manual`.
- Gravação exige `callRecord:true` e **S3 do usuário**. Gravação e stream PCM são mutuamente exclusivos na mesma chamada. O áudio fica em memória/S3; controle e partes ficam no banco. Pausas acima de 2 s podem não entrar no arquivo.
- Rotas móveis com `failClosed:true` e `tcpOnly:true` bloqueiam o engine nativo. A política permissiva não ativa esse guard, mas o SOCKS continua sendo TCP: não interprete `failClosed:false` como suporte a mídia UDP pela rota móvel nem como garantia de chamadas.

Servidor de mídia remoto, aplicativo desktop de telefonia, ponte SIP e seus novos instaladores não fazem parte desta distribuição pública. Consulte as notas de release para saber quais recursos estão disponíveis no pacote instalado.

## Eventos, armazenamento e backups

Configure o webhook e as assinaturas da sessão para receber os eventos necessários. Para entrega persistente, mantenha o buffer no banco e acompanhe filas, tentativas, DLQ e arquivo administrativo. Consumidores devem tolerar duplicatas e deduplicar pelos identificadores de evento; replay pode repetir efeitos. O envelope enriquecido permanece sob `data`, com extensões de domínio em `data.v1` quando aplicável.

S3 pode ser global ou por usuário para mídia comum; gravações de chamada exigem o S3 do usuário. Defina retenção e permissões do bucket. URLs assinadas expiram e não substituem a chave permanente do objeto.

Mantenha backup consistente do banco da aplicação **e do store de sessões**, das configurações/chaves e dos objetos S3 necessários. Inclua o buffer/arquivo persistente e, se usar armazenamento SQLite separado, seus arquivos de dados. O exemplo Compose mantém o PostgreSQL em `postgres_data`; recriar o container preserva esse volume, mas removê-lo apaga o banco.

O estado da rota móvel fica cifrado no banco. Preserve as tabelas de estado e a chave automática do banco ou `NETWORK_ROUTE_STATE_KEY`, caso configurada. Prefira `failClosed:true`, `tcpOnly:true` e só considere a rota pronta com `ready:true` e versões desejada/aplicada iguais. Remover uma rota muda o egresso da sessão e deve ser decisão explícita, nunca fallback automático.

Antes de atualizar, faça backup e ensaie restauração. Leia migrações e notas de versão; voltar somente a imagem não garante reversão do schema. Evite executar a mesma sessão restaurada simultaneamente em dois gateways.

## Binários, instaladores e integridade

Baixe o pacote correspondente ao seu sistema e arquitetura em [Releases](https://github.com/guilhermejansen/use-zuckzapgo/releases). Mantenha o binário e os assets `static/` do mesmo pacote para que dashboard, SDK e `/api/` permaneçam compatíveis.

As releases disponibilizam arquivos por plataforma e `checksums.txt`. Confira o SHA-256 do arquivo baixado contra a entrada correspondente, por exemplo com `sha256sum <arquivo>` no Linux, `shasum -a 256 <arquivo>` no macOS ou `Get-FileHash <arquivo> -Algorithm SHA256` no PowerShell.

Os auxiliares [install.sh](install.sh) (Linux/macOS) e [install.bat](install.bat) (Windows) pertencem ao gateway existente. Leia suas opções e as notas da release antes de executar; instalação, permissões de serviço e compatibilidade precisam ser verificadas no seu ambiente. Esses scripts não instalam um novo desktop, worker de mídia remota ou ponte SIP.

## Suporte

Para licença e suporte do **ZuckZapGo**, contate [suporte@setupautomatizado.com.br](mailto:suporte@setupautomatizado.com.br). Para problemas de documentação e reprodução sem dados privados, use as [issues do repositório público](https://github.com/guilhermejansen/use-zuckzapgo/issues).

Informe versão, sistema/arquitetura, endpoint, status HTTP e passos mínimos. Remova tokens, licença, telefone/JID, QR, dump de sessão, chaves, áudio e URLs assinadas dos anexos e logs compartilhados.
