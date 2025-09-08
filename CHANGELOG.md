# 📋 Changelog

Todas as mudanças importantes neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [v1.2.4] - 2025-09-08

### ✨ Destaques da versão
- BaseURL em todos os eventos (Webhook + RabbitMQ) sem poluir o payload do usuário. Cabeçalhos e campos dedicados garantem rastreabilidade/end-to-end.
- S3 Global com modo “Owner enforced”: novo `GLOBAL_S3_DISABLE_ACL` (default: true). Semântica clara de entrega (`base64`, `url` ou `both`).
- Chamadas: rejeição automática com mensagem/tipo globais configuráveis e fallback robusto por usuário.
- Mídia: detecção MIME inteligente, link preview “clean” (og:image, favicon e YouTube), thumbnails de vídeo (ffmpeg) e PDFs (páginas + miniatura).
- LID (Link ID): novos endpoints para converter Phone/JID ↔ LID e listar mapeamentos. Store SQL entende `@lid` e `@s.whatsapp.net` no mesmo lookup.
- Grupos/Comunidades: criação com `context.Context` e flags (announcement/locked/ephemeral/approval); disappearing timer com timestamp.
- Whatsmeow (fork): pareamento híbrido (WhatsApp Business coexistente) e Presence sem PushName no contexto Messenger.

### 🔧 Mudanças de configuração
- Novas variáveis globais
  - `GLOBAL_CALL_REJECT_MESSAGE`: mensagem padrão de rejeição de chamadas.
  - `GLOBAL_CALL_REJECT_TYPE`: `busy` | `decline` | `unavailable` (default: `busy`).
  - `GLOBAL_S3_DISABLE_ACL`: `true` para buckets AWS com “Bucket owner enforced”; `false` para provedores legados (default: `true`).
- `WA_VERSION` atualizado para `2.3000.1026436087`.
- BaseURL passa a ser calculado e cacheado (carregando `.env` automaticamente quando presente). Variáveis úteis: `ZUCKZAPGO_ADDRESS` e `ZUCKZAPGO_PORT`.

### 🔌 API e Eventos
- BaseURL incorporado nos eventos
  - Cabeçalhos adicionais nos webhooks: `X-ZuckZapGo-BaseURL` (além de usuário/token/jid/eventType).
  - Envelope dos eventos inclui `baseURL` e `source` (p.ex. `zuckzapgo-global`).
- Novos endpoints LID
  - `GET/POST /user/lid/get` — Converte Phone/JID → LID.
  - `GET/POST /user/lid/from-lid` — Converte LID → Phone/JID.
  - `GET /user/lid/mappings` — Lista todos os mapeamentos LID ↔ Phone do usuário.
- Exemplo (curl) — obter LID a partir de JID
  ```bash
  curl -H "token: <USER_TOKEN>" \
       "https://<BASE_URL>/user/lid/get?phone=5521971532700@s.whatsapp.net"
  ```
- Exemplo (Webhook payload — campos relevantes)
  ```json
  {
    "userToken":"***",
    "userID":"***",
    "eventType":"message",
    "userName":"Alice",
    "userJID":"55219...@s.whatsapp.net",
    "baseURL":"https://api.seudominio.com",
    "timestamp": 1725750000,
    "source": "zuckzapgo-global",
    "data": { "...": "payload do evento sem poluição por metadados de S3" }
  }
  ```

### ☁️ S3 (Global e por usuário)
- Modo delivery global: `GLOBAL_S3_MEDIA_DELIVERY=base64|url|both`.
  - `url`: upload para S3 e remoção do campo `base64` do payload.
  - `both`: upload para S3 mantendo o `base64` no payload.
- `GLOBAL_S3_DISABLE_ACL=true` (AWS moderno) evita aplicar ACL no upload; quando `false`, ACL pública é aplicada (compatibilidade com provedores legados).
- Endpoints de S3 do usuário expostos com `disable_acl` no retorno e nos testes de conexão.

### 📞 Chamadas: rejeição automática
- Fallback global quando usuário não definiu mensagem/tipo:
  - `GLOBAL_CALL_REJECT_MESSAGE` e `GLOBAL_CALL_REJECT_TYPE`.
  - Validação de tipo — valores inválidos caem para `busy` com aviso em log.

### 🖼️ Mídia e Previews
- Detecção MIME inteligente — corrige `application/octet-stream` em áudios/documentos.
- PTT (voice note): força `audio/ogg; codecs=opus` quando necessário.
- Link preview “clean”: coleta metadados (OpenGraph/Twitter), baixa thumbnail e envia como `MediaLinkThumbnail`. Suporte expandido para YouTube via oEmbed e scraping.
- PDF: página inicial renderizada como thumbnail (com largura/altura reais) + `pageCount` no documento.
- Vídeo: thumbnail gerado em memória com fallback automático para imagem padrão quando `ffmpeg` ausente.

### 👥 Grupos/Comunidades
- `CreateGroup(context, req)` com suporte a `announcement`, `locked`, `ephemeral` e `membership_approval_mode`.
- `SetDisappearingTimer(..., settingTS)` grava timestamp de configuração para melhor compatibilidade com o cliente.

### 🔐 Whatsmeow (fork privado)
- Pareamento híbrido (coexistente): fallback de verificação de assinatura com tipo de conta oposto para lidar com inconsistências de detecção (Business/Hosted/regular).
- Presence: envia sem `PushName` quando em contexto Messenger E2EE.

### 🗃️ Migrações de banco
- Migração 15 — cache de avatar: adiciona `avatar_url` e `avatar_updated_at`.
- Migração 16 — S3 sem ACL: adiciona `s3_disable_acl` (default TRUE).
- Compatível com PostgreSQL e MySQL (SQLite auxilia desenvolvimento). Aplicadas automaticamente no startup.

### 📦 Dependências e Tooling
- Go toolchain 1.24.x, bibliotecas atualizadas (protobuf, goquery, unipdf, x/*, etc.).
- CI: matriz Go 1.24/1.25; pre-commit atualizado.
- Protobufs WhatsApp atualizados (E2E/Wa6/SyncAction/HistorySync/StatusAttributions/CompanionReg/Armadillo) e migração de `WAWebProtobufsBotMetadata` → `WABotMetadata`.


## [v1.2.3] - 2025-08-15

### 🚀 Novos Recursos

#### 📚 Swagger/OpenAPI Nativo

- ✅ **Documentação Automática**: Geração automática de specs com UI embutida
  - Endpoint `/api/` para interface interativa
  - Artefatos em `static/api/swagger.json|yaml|docs.go`
  - Anotações nos handlers principais
  - Metadados centralizados em `main.go`
- ✅ **Domains Documentados**: Admin/Global, Session, Chat, Group, Community, Newsletter, Privacy, Business, Device, Webhook
- ✅ **Sem Breaking Changes**: Compatibilidade total com APIs existentes

#### 🗄️ Suporte Completo a MySQL

- ✅ **Novo Provedor MySQL**: Suporte nativo com migrações dedicadas
  - DSN: `mysql://user:pass@host:3306/db?charset=utf8mb4&parseTime=True&loc=Local`
  - Conversão automática de placeholders ($1 → ?) via `DatabaseWrapper`
  - `initialSchemaMySQLSQL` e migrações condicionais por driver
- ✅ **Compatibilidade Mantida**: SQLite e PostgreSQL continuam funcionando
- ✅ **Docker Compose**: Serviço MySQL opcional com tuning e healthcheck

#### 📱 Novos Endpoints de Chat

- ✅ **Envio de PTV**: `POST /chat/send/ptv`
  - Pre-Recorded Transfer Video por link ou base64
  - Suporte a headers de mídia
  ```json
  {
    "Phone": "5511999999999",
    "Video": "https://example.com/video.mp4"
  }
  ```
- ✅ **Retry de Mensagens**: `POST /chat/retry/message`
  - Reprocessamento/recuperação de mensagens recebidas
  - Estratégia: BuildUnavailableMessageRequest + envio ao próprio dispositivo
  ```json
  {
    "MessageID": "ABCD1234...",
    "ChatJID": "5511999999999@s.whatsapp.net",
    "SenderJID": "5511888888888@s.whatsapp.net",
    "RetryType": "incoming",
    "ForceRetry": true
  }
  ```

#### 🌐 Proxy Configurável por Usuário

- ✅ **Endpoint de Proxy**: `POST /session/proxy`
  - Suporte a `http://`, `https://` e `socks5://`
  - Configuração individual por usuário
  - Indicação de necessidade de reconexão
  ```json
  {
    "enable": true,
    "proxy_url": "socks5://user:pass@proxy.example.com:1080"
  }
  ```

#### ⚙️ Configurações Avançadas de Dispositivo WhatsApp (Alpha)

- ✅ **Configurações Globais e por Instância**: Controle total sobre parâmetros do dispositivo
  - Aplicadas ANTES da conexão
  - Configurações por usuário sobrepõem globais
  - Valores inválidos geram warn e usam defaults
- ✅ **Enums Suportados**:
  - **waPlatform**: ANDROID, IOS, WINDOWS_PHONE, WEB, MACOS, etc.
  - **waReleaseChannel**: RELEASE, BETA, ALPHA, DEBUG
  - **waWebSubPlatform**: WEB_BROWSER, APP_STORE, WIN_STORE, DARWIN
  - **waConnectType**: WIFI_UNKNOWN, CELLULAR_LTE, CELLULAR_UMTS, etc.
  - **waPlatformType**: CHROME, FIREFOX, SAFARI, ANDROID_PHONE, IOS_PHONE, etc.
- ✅ **Variáveis de Ambiente**:
  ```bash
  WA_VERSION=2.2413.51
  WA_PLATFORM=WEB
  WA_RELEASE_CHANNEL=RELEASE
  WA_OS_NAME=Mac OS
  WA_DEVICE_NAME=MacBook Pro
  WA_LOCALE_LANGUAGE=pt
  WA_LOCALE_COUNTRY=BR
  ```

### 🛠️ Melhorias Técnicas

#### 🔄 Atualizações do whatsmeow-private

- ✅ **Compatibilidade Recente**: Recursos mais recentes do WhatsApp
- ✅ **Otimizações de Performance**: Melhorias no core da biblioteca
- ✅ **Estabilidade**: Correções e melhorias de conectividade

#### ⚡ Otimizações de Performance

- ✅ **RabbitMQ**: Configurações globais e individuais
- ✅ **Skips Configuráveis**: Otimizações de processamento
- ✅ **Processamento Assíncrono**: Melhor handling de mensagens

#### 🏗️ Refatoração de Tipos

- ✅ **Organização por Domínio**: Tipos reorganizados em `types/*`
- ✅ **Remoção de `types/index.go`**: Estrutura mais limpa
- ✅ **Imports Ajustados**: Melhor organização do código
- ✅ **Payloads Padronizados**: Compatibilidade com Swagger

### 📦 Exemplos de Uso

#### Enviar PTV

```bash
curl -X POST "http://localhost:8080/chat/send/ptv" \
  -H "token: <USER_TOKEN>" -H "Content-Type: application/json" \
  -d '{
    "Phone": "5511999999999",
    "Video": "https://example.com/video.mp4"
  }'
```

#### Configurar Proxy

```bash
curl -X POST "http://localhost:8080/session/proxy" \
  -H "token: <USER_TOKEN>" -H "Content-Type: application/json" \
  -d '{
    "enable": true,
    "proxy_url": "socks5://user:pass@proxy.example.com:1080"
  }'
```

#### Retry de Mensagem

```bash
curl -X POST "http://localhost:8080/chat/retry/message" \
  -H "token: <USER_TOKEN>" -H "Content-Type: application/json" \
  -d '{
    "MessageID": "ABCD1234...",
    "ChatJID": "5511999999999@s.whatsapp.net",
    "SenderJID": "5511888888888@s.whatsapp.net",
    "RetryType": "incoming",
    "ForceRetry": true
  }'
```

### 📈 Estatísticas da Versão

| Categoria            | Quantidade             |
| -------------------- | ---------------------- |
| **Novos Endpoints**  | 3 rotas                |
| **Banco de Dados**   | MySQL + migrações      |
| **Documentação**     | Swagger nativo         |
| **Configurações WA** | 20+ parâmetros         |
| **Otimizações**      | Performance + RabbitMQ |

### 🔄 Compatibilidade

- ✅ **Sem Breaking Changes**: Total compatibilidade com versões anteriores
- ✅ **APIs Existentes**: Todas as funcionalidades anteriores mantidas
- ✅ **Bancos de Dados**: SQLite, PostgreSQL e MySQL suportados
- ✅ **Configurações**: Migração automática e transparente

### 🔧 Migração/Upgrade

- **Banco de Dados**: Drivers mantidos; MySQL plugável; migrações condicionadas por driver
- **Documentação**: Acessar `/api/` para interface Swagger
- **Dispositivo**: Variáveis WA\_\* opcionais; configurações por instância (alpha) requerem reconexão
- **Proxy**: Configuração individual por usuário sem impacto em outros

### 🔒 Segurança e Observabilidade

- ✅ **Logs Estruturados**: Melhor rastreabilidade
- ✅ **Métricas Globais**: Estatísticas expostas por endpoints Admin/Global
- ✅ **Validações**: Mensagens claras para proxy, retry e configurações WA inválidas
- ✅ **Fallbacks**: Configurações inválidas usam defaults seguros

---

## [v1.2.2] - 2025-07-27

### 🚀 Novos Recursos

#### 🎯 Mensagens Interativas

- ✅ **Botões Interativos**: Suporte completo para mensagens com botões
  - Quick reply (resposta rápida)
  - Copy (copiar código/texto)
  - URL (links externos)
  - Call (ligação)
  - PIX (pagamentos)
- ✅ **Mensagens de Lista**: Suporte para single select
- ✅ **Novos Endpoints**: `/chat/send/buttons`, `/chat/send/list`

#### 💬 Gerenciamento Avançado de Chat

- ✅ **Pin/Unpin**: Fixar e desfixar conversas importantes
- ✅ **Arquivamento**: Arquivar e desarquivar conversas
- ✅ **Silenciamento**: Silenciar chats por períodos (8h, 1 semana, sempre)
- ✅ **Favoritos**: Marcar/desmarcar mensagens com estrela
- ✅ **Sistema de Labels**: Gerenciamento completo de etiquetas
  - Editar labels existentes
  - Aplicar em chats e mensagens
  - Organização inteligente

#### 🔒 Privacidade e Segurança

- ✅ **Configurações de Privacidade**: Controle total sobre visibilidade
- ✅ **Timer de Mensagens**: Configurar mensagens temporárias
- ✅ **Lista de Bloqueados**: Gerenciar contatos bloqueados
- ✅ **Privacidade de Status**: Controlar quem vê seus status
- ✅ **Configurações Avançadas**: Todas as opções de privacidade do WhatsApp

#### 👥 Comunidades WhatsApp

- ✅ **Criação de Comunidades**: Criar e gerenciar comunidades
- ✅ **Vinculação de Grupos**: Conectar grupos às comunidades
- ✅ **Anúncios**: Enviar anúncios para toda a comunidade
- ✅ **Administração**: Sistema completo de moderação
- ✅ **Solicitações**: Gerenciar pedidos de entrada

#### 💼 Recursos Business

- ✅ **Links Business**: Resolver links de mensagens business
- ✅ **QR Code de Contato**: Gerar QR codes para contatos
- ✅ **Gerenciamento de Bots**: Listar e configurar bots
- ✅ **Perfis de Bots**: Informações detalhadas de bots
- ✅ **Mensagens de Pedido**: Enviar mensagens de pedido (order message)

#### 📱 Gerenciamento de Dispositivos

- ✅ **Listagem de Dispositivos**: Ver todos os dispositivos conectados
- ✅ **Dispositivos Vinculados**: Identificar dispositivos do usuário
- ✅ **Identificação de Plataforma**: Detectar sistema operacional
- ✅ **Consultas Contextuais**: Buscas avançadas com contexto

### 🛠️ Melhorias Técnicas

#### 🔧 Painel Administrativo

- ✅ **Avatares de Usuários**: Exibição de fotos de perfil
- ✅ **Método Interno**: `getAvatarInternal()` para busca eficiente
- ✅ **Informações Completas**: Listagem aprimorada de usuários
- ✅ **Status de Conexão**: Indicadores visuais de conectividade

#### 📊 Constantes e Validações

- ✅ **Tipos de Eventos**: Novos eventos suportados
- ✅ **Mapa de Eventos**: Validação rápida e eficiente
- ✅ **Função de Validação**: `isValidEventType()` para verificações

#### 🔗 Helpers e Utilitários

- ✅ **Processamento de Mídia**: Novos helpers para mídia
- ✅ **Mensagens Interativas**: Funções auxiliares especializadas
- ✅ **Sistema de Callbacks**: Melhorias nos webhooks

#### 🛣️ Rotas e Endpoints

- ✅ **35+ Novas Rotas**: Endpoints RESTful adicionados
- ✅ **Organização por Domínio**: Estrutura clara e lógica
  - `/chat/*` - Operações de chat
  - `/privacy/*` - Configurações de privacidade
  - `/community/*` - Gerenciamento de comunidades
  - `/business/*` - Recursos business
  - `/device/*` - Gerenciamento de dispositivos

#### 📤 Handlers de Envio

- ✅ **SendButtonsMessage()**: Implementação completa
- ✅ **SendListMessage()**: Suporte total para listas
- ✅ **SendCarouselMessage()**: Mensagens em carrossel
- ✅ **Validações Robustas**: Tratamento de erros aprimorado

### 📦 Novos Serviços

#### 🏭 Factory de Mensagens

- ✅ **create_buttons_message_service.go**

  - Factory pattern para criação de botões
  - Suporte para 6 tipos diferentes
  - Validações de limites e formatos
  - Suporte para mídia no header

- ✅ **create_list_message_service.go**
  - Factory para mensagens de lista
  - Múltiplas seções suportadas
  - Validações de tamanho e conteúdo

### 📈 Estatísticas da Versão

| Categoria             | Quantidade   |
| --------------------- | ------------ |
| **Novos Handlers**    | 9 arquivos   |
| **Novos Endpoints**   | 35+ rotas    |
| **Novos Serviços**    | 3 serviços   |
| **Novas Funções**     | 100+ funções |
| **Recursos WhatsApp** | Completo     |

### 🔄 Compatibilidade

- ✅ **Sem Breaking Changes**: Total compatibilidade com versões anteriores
- ✅ **APIs Existentes**: Todas as funcionalidades anteriores mantidas
- ✅ **Configurações**: Compatibilidade total com configurações existentes

### 📚 Documentação

- ✅ **CHANGELOG.md**: Atualizado com todas as mudanças
- ✅ **Dockerfile**: Melhorias na imagem Docker
- ✅ **docker-compose**: Configurações atualizadas
- ✅ **API Spec**: Documentação da API atualizada
- ✅ **Postman**: Coleção atualizada
- ✅ **Dashboard**: Interface HTML melhorada

## 📊 Estatísticas

- **Total de commits**: 64
- **Período**: 2025-06-11 até 2025-07-13

### 👥 Principais Contribuidores

- **Guilherme Jansen**: 52 commit(s)
- **GitHub Action**: 10 commit(s)
- **GitHub Actions Bot**: 2 commit(s)

### 🔗 Links Úteis

- [🚀 GitHub Repository](https://github.com/guilhermejansen/use-zuckzapgo)
- [🐳 Docker Hub](https://hub.docker.com/r/setupautomatizado/zuckzapgo-private)
- [📖 Documentação](https://github.com/guilhermejansen/use-zuckzapgo/blob/main/README.md)
- [🆘 Suporte](mailto:contato@setupautomatizado.com.br)
