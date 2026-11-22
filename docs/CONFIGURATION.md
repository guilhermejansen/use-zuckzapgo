# 🔧 Configuração Completa ZuckZapGo Private

> Exemplos de credenciais usam `SEU_*`: substitua-os por valores próprios antes de iniciar. Nenhum token, senha ou chave deste guia é uma credencial utilizável. Valores opcionais vazios continuam vazios; os exemplos não alteram defaults do servidor.

Referência completa de todas as opções de configuração do ZuckZapGo Private.

---

## 📋 Tabela de Conteúdos

1. [Ordem de Carregamento](#ordem-de-carregamento)
2. [Configuração de Banco de Dados](#configuração-de-banco-de-dados)
3. [Autenticação e Segurança](#autenticação-e-segurança)
4. [Servidor e Rede](#servidor-e-rede)
5. [Logs e Debug](#logs-e-debug)
6. [WhatsApp Client](#whatsapp-client)
7. [Transports Globais](#transports-globais)
8. [Storage S3](#storage-s3)
9. [Flags CLI](#flags-cli)
10. [Paths por Sistema Operacional](#paths-por-sistema-operacional)
11. [Exemplo Completo](#exemplo-completo)

---

## 📥 Ordem de Carregamento (Prioridade Crescente)

As configurações são carregadas na seguinte ordem:

1. **Defaults** (hardcoded no código)
2. **Arquivo .env** (se existir no diretório de execução)
3. **Variáveis de Ambiente** (ENV vars do sistema/shell)
4. **Flags CLI** (argumentos de linha de comando)

**Exemplo de Precedência**:
```bash
# Se você define no .env:
ZUCKZAPGO_PORT=9000

# E executa com flag:
./zuckzapgo --port=8080

# Resultado: Porta 8080 será usada (flag CLI tem maior prioridade)
```

---

## 💾 Configuração de Banco de Dados

### SQLite (Padrão - Zero Configuração)

**Recomendado para**: Desenvolvimento, testes, instâncias pequenas (< 10 usuários)

```bash
# Sintaxe
DATABASE_URL=sqlite://<caminho-do-arquivo>

# Exemplos
DATABASE_URL=sqlite://./data/zuckzapgo.db                                    # Linux/macOS (relativo)
DATABASE_URL=sqlite:///var/lib/zuckzapgo/db.sqlite                           # Linux (absoluto)
DATABASE_URL="sqlite:///Users/SEU_USUARIO/Library/Application Support/zuckzapgo/db.sqlite"  # macOS
DATABASE_URL=sqlite://C:/zuckzapgo/data/db.sqlite                            # Windows
```

**Características**:
- ✅ Sem instalação de servidor
- ✅ Arquivo criado automaticamente
- ✅ Ideal para desenvolvimento
- ⚠️ Não recomendado para produção com múltiplas instâncias
- ⚠️ Performance limitada para alto volume

### PostgreSQL (Recomendado para Produção)

**Recomendado para**: Produção, múltiplas instâncias, alto volume

```bash
# Sintaxe
DATABASE_URL=postgresql://SEU_DB_USER:SEU_DB_PASSWORD@SEU_DB_HOST:5432/SEU_DB_NAME?sslmode=require

# Exemplos
DATABASE_URL=postgresql://SEU_DB_USER:SEU_DB_PASSWORD@localhost:5432/zuckzapgo
DATABASE_URL=postgresql://SEU_DB_USER:SEU_DB_PASSWORD@prod-db.example.com:5432/zuckzapgo?sslmode=require
DATABASE_URL=postgresql://SEU_DB_USER:SEU_DB_PASSWORD@zuckzapgo.abc123.us-east-1.rds.amazonaws.com:5432/zuckzapgo?sslmode=require

# Pool: use as variáveis ENV abaixo; parâmetros pool_* na URI não são consumidos
DATABASE_URL=postgresql://SEU_DB_USER:SEU_DB_PASSWORD@localhost:5432/zuckzapgo?sslmode=require
```

**Parâmetros de Conexão**:
- `sslmode`: `disable`, `require`, `verify-ca`, `verify-full`; o gateway usa `require` quando a URI não informa o parâmetro.
- `search_path` (alias `schema`): schema PostgreSQL; o gateway usa `public` quando omitido.
- A conexão é reconstruída pelo gateway; não presuma que parâmetros arbitrários da URI, como `pool_max_conns`, `connect_timeout` ou `application_name`, sejam repassados. Configure o pool pelas ENV documentadas abaixo.

**Connection Pool** (variáveis ENV adicionais):
```bash
DB_MAX_OPEN_CONNS=100    # Máximo de conexões abertas
DB_MAX_IDLE_CONNS=10     # Máximo de conexões idle
DB_CONN_MAX_LIFETIME_MINUTES=60  # Exemplo: tempo de vida máximo da conexão (minutos)
```

### MySQL/MariaDB

**Recomendado para**: Compatibilidade com infraestrutura existente

```bash
# Sintaxe
DATABASE_URL=mysql://SEU_DB_USER:SEU_DB_PASSWORD@SEU_DB_HOST:3306/SEU_DB_NAME

# Exemplos
DATABASE_URL=mysql://SEU_DB_USER:SEU_DB_PASSWORD@localhost:3306/zuckzapgo
DATABASE_URL=mysql://SEU_DB_USER:SEU_DB_PASSWORD@prod-db.example.com:3306/zuckzapgo
DATABASE_URL=mysql://SEU_DB_USER:SEU_DB_PASSWORD@35.123.45.67:3306/zuckzapgo?charset=utf8mb4&parseTime=true

# Google Cloud SQL
DATABASE_URL=mysql://SEU_DB_USER:SEU_DB_PASSWORD@/zuckzapgo?unix_socket=/cloudsql/project:region:instance
```

**Parâmetros de Conexão**:
- `charset`: Charset da conexão (recomendado: `utf8mb4`)
- `parseTime`: Parse de TIME/DATETIME para Go time.Time (recomendado: `true`)
- `loc`: Timezone (exemplo: `loc=America%2FSao_Paulo`)

---

## 🔐 Autenticação e Segurança

### Admin Token

Token para autenticar endpoints administrativos (`/admin/*`).

```bash
ZUCKZAPGO_ADMIN_TOKEN=SEU_ADMIN_TOKEN
```

**Uso**:
```bash
# Header HTTP
Authorization: SEU_ADMIN_TOKEN

# Exemplo cURL
curl -H "Authorization: $ZUCKZAPGO_ADMIN_TOKEN" \
  http://localhost:8080/admin/users
```

**Endpoints Protegidos**:
- `POST /admin/users` - Criar usuário
- `GET /admin/users` - Listar usuários
- `DELETE /admin/users/{id}` - Deletar usuário
- `GET /admin/global/stats` - Estatísticas globais
- `POST /admin/global/test` - Testar configurações globais

Se nenhum token for informado por flag ou por `ZUCKZAPGO_ADMIN_TOKEN`, o startup gera um token aleatório; os endpoints continuam protegidos. Defina seu token explicitamente para poder operar a API e preserve-o como segredo.

### User Tokens

Na criação por `POST /admin/users`, forneça o campo `token` com um valor aleatório próprio. Esse token autentica apenas a sessão correspondente; ele é diferente do admin token e da licença. Veja o exemplo do [README](../README.md).

**Uso**:
```bash
# Header HTTP
token: SEU_USER_TOKEN

# Query Parameter
http://localhost:8080/session/status?token=SEU_USER_TOKEN

# Exemplo cURL
curl -H "token: SEU_USER_TOKEN" \
  http://localhost:8080/session/status
```

### License Key

```bash
LICENSE_KEY=SEU_LICENSE_KEY
# ou
LICENSE_KEY=SEU_LICENSE_KEY # Enterprise features
```

**Tipos de Licença**:
- **BASIC**: Recursos básicos (mensagens de texto, mídia, grupos)
- **ENTERPRISE** (contém `-ENT-`): Recursos avançados
  - Carrosséis (carousel messages)
  - Botões interativos (interactive buttons)
  - Flows (formulários interativos)

**Verificar Licença**:
```bash
curl http://localhost:8080/health
# Retorna informações sobre licença ativa
```

---

## 🌐 Servidor e Rede

### Endereço e Porta

```bash
# Flags CLI
./zuckzapgo --address=0.0.0.0 --port=8080

# Variáveis ENV
ZUCKZAPGO_ADDRESS=0.0.0.0
ZUCKZAPGO_PORT=8080
```

**Opções de Address**:
- `0.0.0.0`: Aceita conexões de qualquer IP (padrão)
- `127.0.0.1`: Apenas localhost (segurança extra)
- `192.168.1.100`: IP específico da interface

**Portas Comuns**:
- `8080`: Padrão (desenvolvimento)
- `80`: HTTP (requer root/sudo)
- `443`: HTTPS (requer root/sudo + certificados)
- `3000`, `5000`, `8000`: Alternativas

### Base URL (para Webhooks e Eventos)

```bash
ZUCKZAPGO_ADDRESS=https://api.seudominio.com
```

Esta URL será **incluída em TODOS os eventos** enviados via webhook, RabbitMQ, SQS, etc., permitindo que sistemas externos saibam exatamente de onde o evento está vindo.

**Exemplo de Evento**:
```json
{
  "event": "message",
  "instance_id": "user123",
  "from": "5511999999999@s.whatsapp.net",
  "message": {...},
  "zuckzapgo_address": "https://api.seudominio.com"  // ← Incluso automaticamente
}
```

### SSL/TLS

```bash
# Flags CLI
./zuckzapgo \
  --sslcertificate=/path/to/cert.pem \
  --sslprivatekey="${TLS_PRIVATE_KEY_PATH}"
```

**Recomendação**: Use reverse proxy (Nginx, Caddy, Traefik) para SSL:
```nginx
# Nginx
server {
    listen 443 ssl;
    server_name api.seudominio.com;
    
    ssl_certificate /etc/letsencrypt/live/api.seudominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.seudominio.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## 📊 Logs e Debug

### Nível de Log

```bash
# Flag CLI
./zuckzapgo --loglevel=info

# Variável ENV
ZUCKZAPGO_LOG_LEVEL=debug  # debug, info, warn, error
```

**Níveis**:
- `debug`: Máximo detalhamento (desenvolvimento)
- `info`: Informações operacionais (padrão)
- `warn`: Avisos não-críticos
- `error`: Apenas erros críticos (produção)

### Tipo de Log

```bash
# Flag CLI
./zuckzapgo --logtype=console  # ou json

# Variáveis ENV
LOG_TYPE=json         # json ou console
LOG_COLOR=true        # colorir output (apenas console)
```

**Formatos**:
- `console`: Logs legíveis para humanos (desenvolvimento)
  ```
  2025-11-07T10:30:15-03:00 INF Server started address=0.0.0.0 port=8080
  ```
- `json`: Logs estruturados para parsing (produção)
  ```json
  {"level":"info","time":"2025-11-07T10:30:15-03:00","message":"Server started","address":"0.0.0.0","port":"8080"}
  ```

### Debug WhatsApp (whatsmeow)

```bash
# Flag CLI
./zuckzapgo --wadebug=DEBUG  # ou INFO

# Variável ENV
ZUCKZAPGO_DEBUG=debug  # debug, info (vazio = desabilitado)
```

Habilita logs detalhados da biblioteca whatsmeow (conexão, protocolo WhatsApp, eventos).

**Quando usar**:
- ✅ Debugar problemas de conexão WhatsApp
- ✅ Investigar eventos não recebidos
- ✅ Troubleshooting de QR code
- ⚠️ **Não** usar em produção (muito verbose)

---

## 📱 WhatsApp Client

### Configuração de Dispositivo

```bash
# Nome do dispositivo (aparece no WhatsApp > Aparelhos conectados)
# DEIXE VAZIO: sem valor, a whatsmeow usa o default nativo dela
# (Os = "Mac OS 10", PlatformType = DESKTOP).
SESSION_DEVICE_NAME=

# OS Name (para detecção do WhatsApp)
# Flag CLI (equivalente a SESSION_DEVICE_NAME) — default já é "Mac OS 10":
./zuckzapgo --osname="Mac OS 10"
```

> 🚨 **Anti-ban — nunca coloque o nome do produto aqui.** `SESSION_DEVICE_NAME` sobrescreve
> o `osName` da whatsmeow e é **literalmente a string que o WhatsApp exibe** em
> "Aparelhos conectados". Com o nome do produto, cada sessão o anuncia à Meta a cada
> conexão: uma impressão digital que identifica a frota inteira de uma vez e serve de
> gatilho para banimento em massa.
> **Recomendado: não definir a variável.** O default nativo da whatsmeow
> (`Mac OS 10` + `DESKTOP`) já se apresenta como um **WhatsApp Desktop no macOS** —
> aparelho vinculado completamente legítimo — e ainda herda mudanças do upstream
> automaticamente. Se precisar mesmo customizar, use algo com cara de aparelho real
> (ex.: `WA_PLATFORM_TYPE=SAFARI`, navegador no macOS).

> ⚠️ **Só vale em novo pareamento.** `DeviceProps` são enviados no momento do pareamento.
> Sessões **já pareadas continuam exibindo o nome antigo** até serem desconectadas e
> pareadas novamente (novo QR / pair code).

### Configuração Avançada (ENV vars globais)

**Plataforma**:
```bash
WA_PLATFORM=WEB  # WEB, ANDROID, IOS, WINDOWS, MACOS, IPAD
```

**Versão do WhatsApp Web**:
```bash
WA_VERSION=2.3000.1028259376  # primary.secondary.tertiary
```

**Canal de Release**:
```bash
WA_RELEASE_CHANNEL=RELEASE  # RELEASE, BETA, ALPHA, DEBUG
```

**Sub-plataforma Web**:
```bash
WA_WEB_SUB_PLATFORM=WEB_BROWSER  # WEB_BROWSER, APP_STORE, WIN_STORE, DARWIN, WIN32
```

**Tipo de Conexão**:
```bash
WA_CONNECT_TYPE=WIFI_UNKNOWN  # CELLULAR_*, WIFI_UNKNOWN
```

**Tipo de Plataforma** (vazio = `DESKTOP`, default nativo da whatsmeow):
```bash
WA_PLATFORM_TYPE=  # UNKNOWN, CHROME, FIREFOX, SAFARI, EDGE, DESKTOP, IPAD, ANDROID_TABLET, IOS_PHONE, ANDROID_PHONE
```

⚠️ **Nota**: Configurações avançadas geralmente não precisam ser alteradas. Use apenas se souber o que está fazendo.

### Proxy (Firewall Corporativo)

O proxy **não é variável de ambiente**: é configuração por sessão, gravada pela API em
`POST /session/proxy`. Aceita HTTP e SOCKS5, e não pode ser trocado com a sessão conectada.

```bash
curl --fail-with-body -X POST "$BASE_URL/session/proxy" \
  -H "token: SEU_USER_TOKEN" \
  -H 'Content-Type: application/json' \
  --data '{"proxy_url":"socks5://proxy.empresa.com:1080","enable":true}'
```

`enable: false` desliga o proxy da sessão. O formato de `proxy_url` é
`http://host:porta` ou `socks5://host:porta`; o SOCKS5 aceita usuário e senha antes do
host, na forma usual de URL. Para egresso por sessão com endereço próprio, veja a rota
mobile nativa, abaixo.

### Rota Mobile Nativa por Sessão (Tailscale/tsnet)

```bash
# Todas opcionais.
# Origem da importação do estado legado (2.1.0). Vazio = <diretório-da-aplicação>/network-routes
NETWORK_ROUTE_STATE_DIR=/var/lib/zuckzapgo/network-routes
# Chave própria do estado do nó (texto com pelo menos 32 caracteres)
NETWORK_ROUTE_STATE_KEY=
# Valor anterior da chave, só durante a troca
NETWORK_ROUTE_STATE_KEY_PREVIOUS=
# Rotas restauradas em paralelo no boot (padrão 32, mínimo 1)
NETWORK_ROUTE_RESTORE_CONCURRENCY=32
```

`POST /session/network-route` cria um nó `tsnet.Server` isolado para a sessão e
seleciona um exit node pelo `StableNodeID`. O estado do nó (a identidade que
permite restaurar sem auth key nova) fica no banco da aplicação, na tabela
`network_route_node_state`, cifrado com AES-256-GCM; não é preciso volume. A API
nunca persiste nem retorna a auth key JIT, a senha SOCKS ou a URL interna do proxy.

| Variável | Padrão | Efeito |
|---|---|---|
| `NETWORK_ROUTE_STATE_DIR` | `<app>/network-routes` | Só leitura no boot: importa uma vez o `tailscaled.state` de rotas sem estado no banco e renomeia o arquivo para `.imported` |
| `NETWORK_ROUTE_STATE_KEY` | chave automática no banco | Chave de cifra própria (≥ 32 caracteres). Ao ser definida, o boot recifra o estado existente |
| `NETWORK_ROUTE_STATE_KEY_PREVIOUS` | — | Valor antigo durante a troca da chave; sem ele, trocar a chave leva as rotas a `restore_failed` |
| `NETWORK_ROUTE_RESTORE_CONCURRENCY` | `32` | Starts paralelos no boot; prazo do restore = 60 s × levas |

Sem `NETWORK_ROUTE_STATE_KEY`, a chave automática fica no mesmo banco do estado:
quem tem acesso ao banco inteiro consegue abrir o estado. Defina a variável para
separar os dois. Detalhes, troca de chave e deploy sem volume em
[`docs/network-route.md`](network-route.md).

Os arquivos `docker-compose.yml` e `docker-compose-swarm.yaml` ainda montam o
volume nomeado `network_route_state_zuckzapgo` em `/app/network-routes`, agora
opcional: ele só serve para importar o estado de uma instalação 2.1.0.

Rotas `mobile` exigem `tcpOnly=true`. Recomenda-se enviar `failClosed=true`
explicitamente: uma rota não pronta impede a sessão de conectar por outro egresso.
`failClosed=false` é suportado e a omissão também decodifica como falso; nesse
modo permissivo a sessão pode usar o proxy legado ou a saída direta enquanto a
rota está indisponível, mudando o IP visto pelo WhatsApp. Essa escolha deve ser
explícita do operador. O guard de chamadas nativas bloqueia o engine para rotas
mobile fail-closed TCP-only; a política permissiva não cria suporte a mídia UDP
pelo SOCKS TCP nem garante chamadas pela rota móvel.

Contrato, exemplos, fencing por versão e operação de restart/revogação:
[`docs/network-route.md`](network-route.md). Guia autocontido para LLMs e SDKs:
`/api/network-route-llm.txt`.

### Skip Flags (Otimização de Recursos)

```bash
# Global (aplicado a todos usuários se não configurado individualmente)
GLOBAL_SKIP_MEDIA_DOWNLOAD=false       # Pular download de mídia
GLOBAL_SKIP_GROUPS=false               # Ignorar mensagens de grupos
GLOBAL_SKIP_NEWSLETTERS=false          # Ignorar newsletters/canais
GLOBAL_SKIP_BROADCASTS=false           # Ignorar broadcasts
GLOBAL_SKIP_OWN_MESSAGES=true          # Ignorar mensagens próprias
GLOBAL_SKIP_CALLS=false                # Ignorar chamadas
```

### Mensagens que a sessão não conseguiu decifrar

```bash
# Desliga o pedido de reenvio ao celular principal.
GLOBAL_DISABLE_PHONE_REREQUEST=false
```

Com o padrão `false`, quando a sessão não consegue decifrar uma mensagem recebida ela pede ao
celular principal que a mande de novo; se o celular voltar a ficar online, a mensagem chega e o
evento é emitido normalmente. Deixe `true` apenas para parar de fazer esses pedidos.

Isso **não** recupera mídia de visualização única recebida. O WhatsApp não entrega esse
conteúdo a aparelhos vinculados, por decisão de privacidade dele, e nenhum pedido de reenvio
traz de volta. Uma mensagem de visualização única recebida aparece no webhook com
`data.event.IsViewOnce`, mas sem a mídia.

### Chamadas

**Chamadas exigem licença Enterprise em novas assinaturas.** Assinaturas e instalações que já
tinham direito mantêm o acesso. Quando a decisão do servidor de licenças nega chamadas para a
instalação, as rotas `/call/*` e `/session/skipcalls/config` respondem
`403 calls_enterprise_required`, e os eventos de chamada deixam de ser emitidos no webhook.
O `503 calls_license_unavailable` tem **uma causa só**: a verificação trouxe uma decisão sobre
chamadas que o gateway não conseguiu ler — agora, ou na última resposta guardada no cache. É
transitório se o servidor de licenças voltar a responder algo legível, e permanente enquanto
ele mandar um valor desconhecido; o que conferir é a resposta do servidor, não a sua
`LICENSE_KEY`. Uma verificação bem-sucedida que **não** fala de chamadas — campo ausente,
`null` ou vazio — não gera `503`: vale a última decisão que a instalação recebeu, guardada no
cache de licença; quem nunca recebeu nenhuma mantém as chamadas. Licença inválida ou expirada
também não gera `503`: o gateway não sobe, ou encerra, com o erro no log. As rotas `/calls/*`
e `/session/calls/*` **só existem** quando `GLOBAL_CALLS_API_CONFIG_FILE` está preenchido; sem
ele respondem `404`, qualquer que seja a licença. Nenhuma variável de ambiente libera o
recurso. Os dois modos de uso e a implantação de cada um estão em
[`docs/calls-overview.md`](calls-overview.md).

```bash
# Padrões da rejeição de chamadas recebidas. A rejeição em si é configurada por sessão;
# estas duas variáveis definem a mensagem e o tipo usados quando a sessão não os define.
GLOBAL_CALL_REJECT_MESSAGE=Sorry, I cannot take calls at the moment.
GLOBAL_CALL_REJECT_TYPE=busy           # busy (padrão), decline ou unavailable

# Quando true, a rota antiga POST /call/initiate passa a discar como POST /call/dial.
# Com false, o padrão, ela responde 501, como sempre.
GLOBAL_CALL_INITIATE_DIAL_ALIAS=false

# Liga o modo de chamadas com serviço de mídia separado, em que o áudio não passa pelo
# gateway. Vazio, o padrão, mantém as chamadas sendo atendidas pela própria API. Precisa ser
# um arquivo JSON privado, caminho absoluto e permissão 0600; preenchido e inválido impede a
# subida do gateway, de propósito.
GLOBAL_CALLS_API_CONFIG_FILE=
```

> `GLOBAL_AUTO_REJECT_CALL` e `GLOBAL_REJECT_CALL_MESSAGE` apareciam em versões anteriores
> deste guia e **nunca foram lidas pelo servidor**. Os nomes corretos são
> `GLOBAL_CALL_REJECT_MESSAGE` e `GLOBAL_CALL_REJECT_TYPE`, acima.

### Gravação de chamadas

A gravação só acontece com `callRecord: true` em `PUT /call/config` (desligado por padrão) e exige
S3 configurado na instância. O áudio vai para o S3 do próprio usuário durante a chamada e o controle
fica no banco: não há disco local nem volume.

```bash
# Cota de memória (MiB) para o áudio ainda não enviado ao S3, por processo.
# Vazio: 25% do limite de memória do container (cgroup) ou 256 MiB sem limite detectável.
GLOBAL_CALL_RECORDING_MEMORY_QUOTA_MB=
```

Com o S3 fora do ar durante a chamada, a gravação acumula em memória até 128 MiB ou até a cota; então
para (webhook `CallRecordingStopped`) sem derrubar a chamada. Detalhes em
`docs/call-audio-implementation-guide.md`.

---

## 🔄 Transports Globais

Sistemas de entrega de eventos para todos os usuários.

### Webhook Global

```bash
GLOBAL_WEBHOOK_ENABLED=true
GLOBAL_WEBHOOK_URL=https://seu-webhook.com/events
GLOBAL_WEBHOOK_EVENTS=Message,CallOffer,QR,Connected,Disconnected
GLOBAL_WEBHOOK_TIMEOUT=30s             # Timeout da requisição (padrão 30s)
GLOBAL_WEBHOOK_RETRY_COUNT=3           # Tentativas de retry (padrão 3)
GLOBAL_WEBHOOK_RETRY_DELAY=5s          # Delay base entre tentativas (padrão 5s)
GLOBAL_WEBHOOK_MAX_RETRY_DELAY=30s     # Teto do delay com backoff (padrão 30s)
GLOBAL_WEBHOOK_BACKOFF_FACTOR=2.0      # Fator de backoff exponencial (padrão 2.0)
GLOBAL_WEBHOOK_CONCURRENCY=50          # Requisições paralelas máximas (padrão 50)
```

> Variáveis de tempo usam unidade obrigatória (`30s`, `5s`, `750ms`, `2m`). Um número
> sem unidade é recusado pelo servidor, que registra um aviso e aplica o padrão.

**Eventos Disponíveis**:
- `Message`: Mensagens recebidas/enviadas
- `CallOffer`: Chamadas recebidas (voz/vídeo)
- `QR`: QR code gerado
- `Connected`: Cliente conectado
- `Disconnected`: Cliente desconectado
- `Presence`: Status de presença (online/offline/digitando)
- `Receipt`: Recibos de leitura
- `GroupInfo`: Eventos de grupo
- `LoggedOut`: Sessão encerrada/logout
- `All`: Todos os eventos

**Nota importante**:
- Os nomes dos eventos são **case-sensitive** e devem usar a nomenclatura canônica acima.
- Em filtros individuais (webhook/rabbitmq por instância), listas CSV com espaços são normalizadas automaticamente. Exemplo válido: `Message, Disconnected`.

### RabbitMQ Global

```bash
GLOBAL_RABBITMQ_ENABLED=true
GLOBAL_RABBITMQ_URL=amqp://SEU_RABBITMQ_USER:SEU_RABBITMQ_PASSWORD@localhost:5672/
GLOBAL_RABBITMQ_EVENTS=Message,CallOffer,QR
GLOBAL_RABBITMQ_EXCHANGE=zuckzapgo
GLOBAL_RABBITMQ_EXCHANGE_TYPE=topic     # topic, direct, fanout, headers
GLOBAL_RABBITMQ_QUEUE=zuckzapgo.events
GLOBAL_RABBITMQ_QUEUE_TYPE=classic      # classic, quorum
GLOBAL_RABBITMQ_ROUTING_KEY=whatsapp.#
GLOBAL_RABBITMQ_DURABLE=true
GLOBAL_RABBITMQ_AUTO_DELETE=false
GLOBAL_RABBITMQ_EXCLUSIVE=false
GLOBAL_RABBITMQ_NO_WAIT=false
GLOBAL_RABBITMQ_DELIVERY_MODE=2         # 1=non-persistent, 2=persistent

# High-throughput optimization
GLOBAL_RABBITMQ_CONNECTION_POOL_SIZE=50
GLOBAL_RABBITMQ_WORKER_COUNT=100
GLOBAL_RABBITMQ_QUEUE_BUFFER_SIZE=100000
GLOBAL_RABBITMQ_BATCH_SIZE=1000
GLOBAL_RABBITMQ_BATCH_TIMEOUT_MS=100    # ms, inteiro (padrão 100)

# Circuit breaker
GLOBAL_RABBITMQ_CIRCUIT_BREAKER_THRESHOLD=10
GLOBAL_RABBITMQ_CIRCUIT_BREAKER_TIMEOUT_S=30    # segundos

# Performance
GLOBAL_RABBITMQ_PUBLISH_TIMEOUT_MS=5000    # ms
GLOBAL_RABBITMQ_MAX_RETRIES=12
GLOBAL_RABBITMQ_RETRY_DELAY_MS=1000        # ms
GLOBAL_RABBITMQ_QOS_PREFETCH_COUNT=100

# Flags avançadas
GLOBAL_RABBITMQ_ENABLE_COMPRESSION=false
GLOBAL_RABBITMQ_ENABLE_BATCHING=true
GLOBAL_RABBITMQ_ENABLE_PERSISTENCE=true
GLOBAL_RABBITMQ_ENABLE_CONFIRMATION=true

# Logs e métricas
GLOBAL_RABBITMQ_METRICS_INTERVAL_S=10   # segundos, inteiro (padrão 10)
GLOBAL_RABBITMQ_ENABLE_DETAILED_LOGS=false
GLOBAL_RABBITMQ_ENABLE_METRICS_LOG=true
```

Com `GLOBAL_RABBITMQ_ENABLE_CONFIRMATION=true`, cada publicação aguarda a confirmação
do broker dentro de `GLOBAL_RABBITMQ_PUBLISH_TIMEOUT_MS`. Uma rejeição (`NACK`) ou
timeout retorna erro para o fluxo de retry existente. O `ACK` do broker confirma
a aceitação da publicação, não o processamento pelo consumidor. Um timeout pode
acontecer depois da aceitação pelo broker; portanto, retries podem produzir
duplicações. Com a opção `false`, a publicação não aguarda confirmação do broker.

### AWS SQS Global

```bash
GLOBAL_SQS_ENABLED=true
GLOBAL_SQS_REGION=us-east-1
GLOBAL_SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789012/zuckzapgo-events
GLOBAL_SQS_EVENTS=Message,ReadReceipt,CallOffer,QR

# Credenciais AWS
GLOBAL_SQS_ACCESS_KEY=SEU_SQS_ACCESS_KEY
GLOBAL_SQS_SECRET_KEY=SEU_SQS_SECRET_KEY
GLOBAL_SQS_SESSION_TOKEN=                    # Opcional (IAM roles)
GLOBAL_SQS_PROFILE=default                   # AWS CLI profile

# FIFO Queue (ordem garantida)
GLOBAL_SQS_FIFO=false                        # padrão false
GLOBAL_SQS_MESSAGE_GROUP=zuckzapgo           # Obrigatório com GLOBAL_SQS_FIFO=true (padrão zuckzapgo-global)

# Performance
GLOBAL_SQS_DELAY_SECONDS=0                   # Delay de entrega, inteiro (0-900, padrão 0)
GLOBAL_SQS_MAX_RETRIES=3                     # padrão 3
GLOBAL_SQS_RETRY_DELAY=1s                    # padrão 1s
GLOBAL_SQS_TIMEOUT=5s                        # padrão 5s
```

### Redis Streams Global

```bash
GLOBAL_REDIS_ENABLED=true
GLOBAL_REDIS_ADDRESS=localhost:6379
GLOBAL_REDIS_USERNAME=                       # Redis 6+
GLOBAL_REDIS_PASSWORD=SEU_REDIS_PASSWORD
GLOBAL_REDIS_TLS=false
GLOBAL_REDIS_STREAM=zuckzapgo.events         # padrão zuckzapgo.events
GLOBAL_REDIS_EVENTS=Message,ReadReceipt,CallOffer,QR
GLOBAL_REDIS_MAXLEN=100000                   # Máximo de eventos no stream (padrão 100000)
GLOBAL_REDIS_TRIM_APPROX=true                # Poda aproximada, mais rápida (padrão true)
GLOBAL_REDIS_MAX_RETRIES=3                   # padrão 3
GLOBAL_REDIS_RETRY_DELAY=750ms               # padrão 750ms
GLOBAL_REDIS_TIMEOUT=3s                      # padrão 3s
```

O gateway **publica** no stream (`XADD`); ele não consome. Não há grupo de consumidores,
nome de consumidor, tempo de bloqueio nem contagem por leitura para configurar: quem lê o
stream é o seu consumidor, e essas opções pertencem a ele, não ao gateway.

### WebSocket Global

Neste transporte **o gateway é o cliente**: ele conecta nos endereços que você listar e
escreve os eventos ali. Ele não abre um servidor WebSocket nem publica um caminho para o
seu cliente conectar. Quem hospeda o servidor é você.

```bash
GLOBAL_WEBSOCKET_ENABLED=true                        # padrão false
# Endereços do SEU servidor, separados por vírgula. Sem eles não há entrega.
GLOBAL_WEBSOCKET_ENDPOINTS=wss://eventos.seu-dominio.com/zuckzapgo
GLOBAL_WEBSOCKET_EVENTS=Message,ReadReceipt,CallOffer,QR
GLOBAL_WEBSOCKET_TIMEOUT=10s                         # Timeout do handshake (padrão 10s)
GLOBAL_WEBSOCKET_WRITE_TIMEOUT=5s                    # Timeout de escrita (padrão 5s)
GLOBAL_WEBSOCKET_RETRY_DELAY=2s                      # Delay entre tentativas (padrão 2s)
GLOBAL_WEBSOCKET_MAX_RETRIES=5                       # padrão 5
GLOBAL_WEBSOCKET_ENABLE_COMPRESSION=true             # padrão true
# Headers extras no handshake, no formato chave=valor separado por vírgula.
GLOBAL_WEBSOCKET_HEADERS=X-Tenant=acme,X-Source=zuckzapgo
```

**Receber os eventos**: suba um servidor WebSocket no endereço configurado e trate cada
mensagem recebida. Exemplo em Node, com a biblioteca `ws`:

```javascript
import { WebSocketServer } from 'ws';

const server = new WebSocketServer({ port: 8081, path: '/zuckzapgo' });
server.on('connection', (socket) => {
  socket.on('message', (raw) => {
    const envelope = JSON.parse(raw);
    console.log('Evento recebido:', envelope.payload);
  });
});
```

O exemplo escuta em `ws://` numa porta local, enquanto a variável aponta para `wss://`: o
TLS termina no proxy à frente do seu servidor, que repassa a conexão em texto claro na rede
interna. Sem proxy, sirva o próprio servidor em `wss://` com certificado e aponte a variável
para ele.

O envelope deste transporte usa `payload` e `createdAt` em nanossegundos Unix; o contrato
completo está em [`docs/webhook-events.md`](webhook-events.md). Escrita bem-sucedida no
socket não prova persistência do seu lado: o transporte não tem ACK de negócio.

---

## 📦 Storage S3

### Configuração S3 Global

```bash
GLOBAL_S3_ENABLED=true
GLOBAL_S3_BUCKET=zuckzapgo-media
GLOBAL_S3_REGION=us-east-1
GLOBAL_S3_ACCESS_KEY=SEU_S3_ACCESS_KEY
GLOBAL_S3_SECRET_KEY=SEU_S3_SECRET_KEY

# Endpoint customizado (MinIO, DigitalOcean Spaces, etc.)
GLOBAL_S3_ENDPOINT=https://s3.us-east-1.amazonaws.com
# MinIO:
GLOBAL_S3_ENDPOINT=http://minio:9000

# Path style (obrigatório para MinIO). Padrão true.
GLOBAL_S3_PATH_STYLE=true

# ACL (desabilitado por padrão)
GLOBAL_S3_DISABLE_ACL=true

# URL pública usada nos links, quando houver CDN ou domínio próprio
GLOBAL_S3_PUBLIC_URL=

# Entrega de mídia: base64 (padrão), s3, url (sinônimo de s3) ou both
GLOBAL_S3_MEDIA_DELIVERY=url

# Retenção dos objetos
GLOBAL_S3_RETENTION_DAYS=30              # inteiro, 0 = sem expiração (padrão 0)
```

A **estrutura das chaves é fixa** e não é configurável:
`global/{userID}/{inbox|outbox}/{contactType}/{contactJID}/{year}/{month}/{day}/{mediaType}/{filename}`.

A faxina dos objetos expirados é um processo próprio, com variáveis de prefixo diferente
(`S3_RETENTION_*`, lidas em `s3_retention.go`):

```bash
S3_RETENTION_ENABLED=true                # padrão true
S3_RETENTION_INTERVAL=1h                 # intervalo entre ciclos (padrão 1h)
S3_RETENTION_OPERATION_TIMEOUT=10m       # teto por operação (padrão 10m)
S3_RETENTION_MAX_CONCURRENCY=5           # padrão 5
S3_RETENTION_BATCH_SIZE=1000             # máximo 1000, limite do S3 (padrão 1000)
S3_RETENTION_OBJECTS_PER_CYCLE=10000     # padrão 10000
```

**Modos de entrega de mídia**:
- `base64` (padrão): Retorna o conteúdo em base64 no payload
- `s3`, ou `url`, que é sinônimo: Retorna a URL do objeto no S3
- `both`: Retorna URL + base64 (maior uso de banda)

**Exemplo de Chave S3**:
```
global/user123/inbox/individual/5511999999999@s.whatsapp.net/2025/11/07/image/photo-1699380000.jpg
```

---

## 🗂️ Retenção do histórico de grupos

O envio de histórico a novos membros (`POST /group/history/send` e a opção `send_history`
de `POST /group/updateparticipants`) só pode mandar **o original** de cada mensagem, como o
cliente oficial faz: texto reconstruído a partir do webhook não serve. Por isso o gateway
retém o protobuf original de cada mensagem de grupo que passa por ele — recebida ao vivo,
vinda de history sync ou enviada pela API — em `message_metadata`, e essas duas variáveis
limitam essa retenção:

| Variável | Padrão | Efeito |
|---|---|---|
| `GLOBAL_GROUP_HISTORY_RETENTION_DAYS` | `90` (também é o máximo) | Prazo de retenção. `0` desliga a retenção: nada novo é gravado e o pruner apaga o que existe. |
| `GLOBAL_GROUP_HISTORY_RETENTION_MAX_PER_USER` | `100000` | Teto de originais por número, removendo os mais antigos. |

**O que é guardado.** O protobuf original da mensagem (até 1 MiB por mensagem), com a
chave, o autor e o instante. **O conteúdo das mensagens de grupo fica no banco de dados de
quem hospeda o gateway** — quem opera a instalação consegue lê-lo. A **mídia não é copiada**:
o original guarda a referência do WhatsApp (direct path, chave de mídia, hashes), e o arquivo
continua nos servidores do WhatsApp. Uma mídia cuja referência expirou não volta.

**Tamanho típico, medido numa conta real** com 379 grupos ativos: 8.783 originais, 13 MB no
total; média de 1,6 KB por mensagem, mediana 571 bytes, 90% abaixo de 4 KB, maior 47 KB.

**Garantia por grupo.** O teto por número nunca remove as **200 mensagens mais recentes de
cada grupo** dentro do prazo. Sem isso, numa conta com centenas de grupos os grupos
movimentados empurrariam as mensagens de um grupo calmo para fora do teto, e um envio de
"últimas 200" entregaria menos do que promete. O piso é 200 porque esse é o maior envio que
a API aceita.

**Pior caso de armazenamento.** Como o piso por grupo pode valer mais que o teto, o limite
superior passa a ser `max(teto, 200 × grupos ativos)` originais, mais uma linha de índice de
cerca de 80 bytes por original. Com o teto padrão e a média medida acima:

| Grupos ativos | Originais | Espaço |
|---|---|---|
| até ~500 | até 100.000 (o teto manda) | ~160 MB + ~8 MB de índice |
| 1.000 | ~200.000 | ~320 MB + ~16 MB |
| 2.000 | ~400.000 | ~640 MB + ~32 MB |

O prazo continua valendo para tudo: grupo parado sai da retenção ao completar 90 dias, mesmo
protegido pelo piso.

**Índice por grupo.** O piso e a seleção de "últimas N" usam uma linha de índice por
original, na mesma tabela, sem coluna nem migração nova. Originais retidos por versões
anteriores ganham essa linha **no pruner horário**, em lotes de 500 e até 5.000 por número
por rodada — nada roda na subida do gateway. Uma conta com 100 mil originais converge em
cerca de 20 horas. Enquanto não converge, a resposta de um envio por `last_n` traz
`index_backfill_pending: true`, para quem integra não achar que faltou mensagem.

Em cada rodada o preenchimento roda **depois do prazo e antes do teto**: o piso já vale para
o que a rodada acabou de indexar, e original vencido não é indexado à toa. Quando todos os
números estão com o preenchimento concluído, o processo guarda isso em memória e as rodadas
seguintes pulam a varredura de usuários (`SELECT DISTINCT user_id`); ela volta na primeira
rodada depois de um reinício, quando aparece um número novo ou quando um número é excluído.

**Fixadas.** O envio por `last_n` inclui automaticamente as mensagens fixadas do grupo que
ficaram fora das últimas N, no mesmo campo que o cliente oficial usa. O gateway passou a
gravar a fixação de mensagem **a partir da versão 2.5.0**: uma mensagem fixada antes disso
não tem registro e não entra no pacote até ser fixada de novo. Quantas fixadas viajam segue
o limite de fixadas da conta, que o gateway pede ao servidor só quando o grupo tem fixada
vigente, guarda por 6 horas (1 minuto depois de uma falha) e lê de novo a cada conexão (AB prop `pinned_messages_m2_pin_max`; 1 quando o servidor não responde). Cada mensagem
do pacote que está entre essas fixações vigentes mais recentes leva a marcação de fixada, com a
hora do servidor e a duração gravadas na fixação, para o aparelho de quem recebe mostrá-la
fixada. A resposta informa quantas fixadas entraram
(`selection.pinned_included`), quantas mensagens foram marcadas (`selection.pinned_marked`) e o
limite usado (`selection.max_pins`).

**Exclusão de usuário.** `DELETE /admin/users/{id}` e `/full` apagam os originais, as linhas
de índice, o estado de fixação e o cursor do preenchimento desse número.

---

## 🩺 Saúde e encerramento

**Saúde**: a instância responde em `GET /health`, sem autenticação. É o endpoint que o
Compose e o Swarm usam no `healthcheck`. Não há endpoint de métricas: o gateway não expõe
`/metrics` nem exporta para Prometheus, e não há variável que ligue isso. Para acompanhar
eventos em tempo real existe o SSE administrativo em `/admin/events/stream`, descrito no
OpenAPI.

**Encerramento**: os prazos do encerramento gracioso são **fixos no binário**, não
configuráveis por variável de ambiente:

| Etapa | Prazo |
|---|---|
| Teto total antes da saída forçada | 45 s |
| Drenagem das gravações de chamada | até 40 s, sempre deixando 15 s para a fase final |
| Fechamento das rotas mobile nativas | 15 s |

Em orquestrador, o contêiner precisa de um prazo de parada **maior que 45 s** para que o
encerramento caiba inteiro. O padrão do Docker é 10 s, que cortaria o processo no meio, então
os stacks de exemplo desta distribuição já trazem `stop_grace_period: 60s` no serviço do
gateway: `docker-compose.yml`, `docker-compose-swarm.yaml` e o bloco de stack do README. Se
você escreveu o seu próprio, defina esse prazo.

---

## 🖥️ Flags CLI

Todas as flags de linha de comando disponíveis:

```bash
./zuckzapgo [flags]

Flags:
  --address string         Bind IP Address (default "0.0.0.0")
  --port string            Listen Port (default "8080")
  --wadebug string         Enable whatsmeow debug (INFO or DEBUG)
  --logtype string         Type of log output (console or json) (default "console")
  --loglevel string        Log level (debug, info, warn, error) (default "info")
  --color                  Enable colored output for console logs
  --skipmedia              Do not attempt to download media in messages
  --osname string          Connection OSName in Whatsapp (default "Mac OS 10")
  --sslcertificate string  SSL Certificate File
  --sslprivatekey string   SSL Certificate Private Key File
  --admintoken string      Security Token to authorize admin actions
  --version                Display version information and exit
```

**Exemplo de Uso Combinado**:
```bash
./zuckzapgo \
  --address=0.0.0.0 \
  --port=8080 \
  --logtype=json \
  --loglevel=info \
  --wadebug=INFO \
  --admintoken=SEU_ADMIN_TOKEN
```

---

## 📁 Paths por Sistema Operacional

### Linux

**Execução Local**:
```bash
# Relativo ao diretório do binário
./zuckzapgo
├── ./data/           # Database SQLite
├── ./logs/           # Log files
├── ./buffer/         # Event buffer
└── ./static/         # Web assets
```

**Instalação Systemd** (`/opt/zuckzapgo`):
```bash
/opt/zuckzapgo/
├── data/             # Database
├── logs/             # Logs
├── buffer/           # Event buffer
└── static/           # Web assets

/usr/local/bin/zuckzapgo  # Binário
/etc/systemd/system/zuckzapgo.service  # Service file
```

### Windows

**Execução Local**:
```powershell
C:\zuckzapgo\
├── data\             # Database
├── logs\             # Logs
├── buffer\           # Event buffer
├── static\           # Web assets
└── zuckzapgo-private-windows-amd64.exe
```

**Instalação NSSM**:
```
C:\zuckzapgo\         # Mesmo path acima
C:\Windows\System32\nssm.exe  # NSSM
```

### macOS

**Execução Local**:
```bash
./zuckzapgo
├── ./data/
├── ./logs/
├── ./buffer/
└── ./static/
```

**Instalação LaunchDaemon**:
```bash
/opt/zuckzapgo/       # Instalação
/usr/local/bin/zuckzapgo  # Binário
/Library/LaunchDaemons/com.zuckzapgo.plist  # Service plist
```

**Paths alternativos (macOS)** (não usados por padrão, mas comuns):
```bash
~/Library/Application Support/zuckzapgo/  # Dados do usuário
~/Library/Logs/zuckzapgo/                 # Logs
```

---

## 📄 Exemplo Completo de Configuração

Arquivo `.env` com todas as opções principais:

```bash
# =============================================================================
# ZUCKZAPGO PRIVATE - CONFIGURAÇÃO COMPLETA
# =============================================================================

# ========================================
# LICENÇA E IDENTIFICAÇÃO
# ========================================
LICENSE_KEY=SEU_LICENSE_KEY
INSTANCE_ID=producao-sp-01
SERVER_IP=203.0.113.50

APP_ENV=production
APP_REGION=sa-east-1
GIT_COMMIT=a59c1501

# ========================================
# SERVIDOR E REDE
# ========================================
ZUCKZAPGO_ADDRESS=https://api.seudominio.com
ZUCKZAPGO_PORT=8080

# ========================================
# BANCO DE DADOS
# ========================================
# PostgreSQL (produção)
DATABASE_URL=postgresql://SEU_DB_USER:SEU_DB_PASSWORD@postgres:5432/zuckzapgo?sslmode=require

# Connection pool
DB_MAX_OPEN_CONNS=100
DB_MAX_IDLE_CONNS=10
DB_CONN_MAX_LIFETIME_MINUTES=60

# ========================================
# AUTENTICAÇÃO
# ========================================
ZUCKZAPGO_ADMIN_TOKEN=SEU_ADMIN_TOKEN

# ========================================
# LOGS E DEBUG
# ========================================
ZUCKZAPGO_LOG_LEVEL=info
LOG_TYPE=json
LOG_COLOR=false
ZUCKZAPGO_DEBUG=

# ========================================
# TIMEZONE
# ========================================
TZ=America/Sao_Paulo

# ========================================
# WHATSAPP CLIENT
# ========================================
# Anti-ban: NUNCA anuncie o nome do produto ao WhatsApp. Deixe vazio para usar o
# default nativo da whatsmeow (Mac OS 10 / DESKTOP = WhatsApp Desktop no macOS).
# Só vale em NOVO pareamento (sessões já pareadas mantêm o nome antigo).
SESSION_DEVICE_NAME=

# Configurações avançadas (geralmente não precisam ser alteradas)
# WA_PLATFORM=WEB
# WA_VERSION=2.3000.1028259376
# WA_RELEASE_CHANNEL=RELEASE

# Skip flags (otimização de recursos)
GLOBAL_SKIP_MEDIA_DOWNLOAD=false
GLOBAL_SKIP_GROUPS=false
GLOBAL_SKIP_NEWSLETTERS=false
GLOBAL_SKIP_BROADCASTS=false
GLOBAL_SKIP_OWN_MESSAGES=true
GLOBAL_SKIP_CALLS=false

# Padrões da rejeição de chamadas recebidas
GLOBAL_CALL_REJECT_MESSAGE=Sorry, I cannot take calls at the moment.
GLOBAL_CALL_REJECT_TYPE=busy

# ========================================
# WEBHOOK GLOBAL
# ========================================
GLOBAL_WEBHOOK_ENABLED=true
GLOBAL_WEBHOOK_URL=https://webhook.seudominio.com/events
GLOBAL_WEBHOOK_EVENTS=Message,CallOffer,QR,Connected,Disconnected
GLOBAL_WEBHOOK_TIMEOUT=30s
GLOBAL_WEBHOOK_RETRY_COUNT=3
GLOBAL_WEBHOOK_CONCURRENCY=50

# ========================================
# RABBITMQ GLOBAL
# ========================================
GLOBAL_RABBITMQ_ENABLED=true
GLOBAL_RABBITMQ_URL=amqp://SEU_RABBITMQ_USER:SEU_RABBITMQ_PASSWORD@rabbitmq:5672/
GLOBAL_RABBITMQ_EVENTS=Message,CallOffer,QR
GLOBAL_RABBITMQ_EXCHANGE=zuckzapgo
GLOBAL_RABBITMQ_QUEUE=zuckzapgo.events
GLOBAL_RABBITMQ_ROUTING_KEY=whatsapp.#

# High-throughput optimization
GLOBAL_RABBITMQ_CONNECTION_POOL_SIZE=50
GLOBAL_RABBITMQ_WORKER_COUNT=100
GLOBAL_RABBITMQ_QUEUE_BUFFER_SIZE=100000
GLOBAL_RABBITMQ_BATCH_SIZE=1000
GLOBAL_RABBITMQ_ENABLE_BATCHING=true
GLOBAL_RABBITMQ_ENABLE_CONFIRMATION=true

# ========================================
# S3 GLOBAL
# ========================================
GLOBAL_S3_ENABLED=true
GLOBAL_S3_BUCKET=zuckzapgo-media
GLOBAL_S3_REGION=us-east-1
GLOBAL_S3_ACCESS_KEY=SEU_S3_ACCESS_KEY
GLOBAL_S3_SECRET_KEY=SEU_S3_SECRET_KEY
GLOBAL_S3_DISABLE_ACL=true
GLOBAL_S3_MEDIA_DELIVERY=url
GLOBAL_S3_RETENTION_DAYS=30

# ========================================
# AWS SQS GLOBAL (OPCIONAL)
# ========================================
GLOBAL_SQS_ENABLED=false
# GLOBAL_SQS_REGION=us-east-1
# GLOBAL_SQS_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789012/zuckzapgo-events

# ========================================
# REDIS STREAMS GLOBAL (OPCIONAL)
# ========================================
GLOBAL_REDIS_ENABLED=false
# GLOBAL_REDIS_ADDRESS=redis:6379
# GLOBAL_REDIS_PASSWORD=SEU_REDIS_PASSWORD
# GLOBAL_REDIS_STREAM=zuckzapgo.events

# ========================================
# WEBSOCKET GLOBAL (OPCIONAL)
# ========================================
GLOBAL_WEBSOCKET_ENABLED=true
GLOBAL_WEBSOCKET_ENDPOINTS=wss://eventos.seu-dominio.com/zuckzapgo

# =============================================================================
# FIM DA CONFIGURAÇÃO
# =============================================================================
```

---

## 🔍 Validação de Configuração

### Testar Configuração

```bash
# Ver configuração ativa
./zuckzapgo --help

# Testar startup (Ctrl+C para sair)
./zuckzapgo --loglevel=debug

# Verificar health endpoint
curl http://localhost:8080/health

# Verificar configuração de DB
curl http://localhost:8080/health | jq '.database'
```

### Verificar Logs

```bash
# Logs em tempo real (console)
./zuckzapgo --logtype=console --color=true --loglevel=debug

# Logs em arquivo
./zuckzapgo > logs/app.log 2>&1 &
tail -f logs/app.log

# Systemd (Linux)
sudo journalctl -u zuckzapgo -f

# LaunchDaemon (macOS)
tail -f /opt/zuckzapgo/logs/stdout.log

# Docker
docker logs -f zuckzapgo
```

### Debug de Problemas

```bash
# 1. Verificar nomes das ENV vars carregadas, sem imprimir seus valores
env | cut -d= -f1 | grep ZUCKZAPGO
env | cut -d= -f1 | grep GLOBAL

# 2. Testar conexão de banco de dados
# PostgreSQL:
psql $DATABASE_URL -c "SELECT version();"

# MySQL:
mysql --uri=$DATABASE_URL -e "SELECT VERSION();"

# SQLite:
sqlite3 ./data/zuckzapgo.db ".schema"

# 3. Testar webhooks
curl -X POST https://seu-webhook.com/events \
  -H "Content-Type: application/json" \
  -d '{"test": "evento de teste"}'

# 4. Testar RabbitMQ
# Ver filas:
rabbitmqadmin list queues

# Ver exchanges:
rabbitmqadmin list exchanges

# 5. Testar S3
aws s3 ls s3://zuckzapgo-media/
```

---

## 📚 Recursos Adicionais

- **Instalação**: [INSTALL.md](./INSTALL.md)
- **README**: [../README.md](../README.md)
- **API Docs**: `http://localhost:8080/api/`
- **Changelog**: [../CHANGELOG.md](../CHANGELOG.md)
- **Suporte**: suporte@setupautomatizado.com.br

---

**Versão do Guia**: 2.5.0 <!-- x-release-please-version -->

**Última Atualização**: 2026-11-21
