# 🚀 ZuckZapGo Private

<p align="center">
  <img src="https://raw.githubusercontent.com/guilhermejansen/use-zuckzapgo/main/favicon.png" alt="ZuckZapGo Private" width="120" height="120">
</p>

<p align="center">
  <strong>🚀 WhatsApp API Gateway with Multi-Device Support, Dashboard, Webhooks, RabbitMQ, S3 Storage, N8N Nodes Community and Chatwoot Integration</strong>
</p>

<p align="center">
  <a href="https://hub.docker.com/r/setupautomatizado/zuckzapgo-private"><img src="https://img.shields.io/docker/pulls/setupautomatizado/zuckzapgo-private?style=flat-square&logo=docker&color=blue" alt="Docker Pulls"></a>
  <a href="https://hub.docker.com/r/setupautomatizado/zuckzapgo-private"><img src="https://img.shields.io/docker/image-size/setupautomatizado/zuckzapgo-private/latest?style=flat-square&logo=docker&color=blue" alt="Docker Image Size"></a>
  <a href="https://github.com/guilhermejansen/use-zuckzapgo"><img src="https://img.shields.io/github/stars/guilhermejansen/use-zuckzapgo?style=flat-square&logo=github&color=yellow" alt="GitHub Stars"></a>
  <a href="https://github.com/guilhermejansen/use-zuckzapgo/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-Commercial-red?style=flat-square" alt="License"></a>
  <a href="https://www.postman.com/setupautomatizado/"><img src="https://img.shields.io/badge/Postman-Collection-orange?style=flat-square&logo=postman" alt="Postman Collection"></a>
</p>

## 📝 Assine o ZuckZapGo

> Escolha o plano ideal para o seu negócio e desbloqueie todo o potencial do ZuckZapGo.

<p align="center">
  <img src="https://raw.githubusercontent.com/guilhermejansen/use-zuckzapgo/main/qrcode.svg" alt="Assine Agora ZuckZapGo Private" width="120" height="120">
</p>

| Plano | Instalações | Recursos | Link rápido |
| :-- | :--: | :-- | :-- |
| **Standard Mensal** | 1 IP | API completa, sem limite de instâncias | [Assinar Standard Mensal](https://go.hotmart.com/S101068222H?off=24s9oau4) |
| **Standard Anual** | 1 IP | API completa, sem limite de instâncias | [Assinar Standard Anual](https://go.hotmart.com/S101068222H?off=ml91nraz) |
| **Premium Mensal** | até 2 instalações | + Botões interativos, carousels e recursos Enterprise | [Assinar Premium Mensal](https://go.hotmart.com/S101068222H?off=pez6mwnh) |
| **Premium Anual** | até 2 instalações | + Botões interativos, carousels e recursos Enterprise | [Assinar Premium Anual](https://go.hotmart.com/S101068222H?off=p1q64goj) |

> 🔑 **Licenciamento**
> • Planos *Standard*: sem limite de instâncias; 1 licença por IP público.
> • Planos *Premium*: até 2 instalações simultâneas + botões interativos, carousels.

👉 [Torne-se um afiliado e venda a plataforma](https://app-vlc.hotmart.com/affiliate-recruiting/view/3115Z101068243)

---

## 🎥 Vídeos Úteis

**Licença sem limites:**
Ao assinar, você pode instalar o ZuckZapGo em sua própria máquina ou servidor, sem limites de uso, instâncias ou conexões. Total liberdade e controle para o seu negócio!

### Instalação Passo a Passo

[![Assista ao vídeo de instalação](https://img.youtube.com/vi/3pB2selupGg/0.jpg)](https://youtu.be/3pB2selupGg)

### Apresentação e Depoimento sobre a API (Início)

[![Assista à apresentação e depoimento](https://img.youtube.com/vi/I557BU3_3zE/0.jpg)](https://www.youtube.com/watch?v=I557BU3_3zE&t=5906s)

## 📋 Sobre o Projeto

**ZuckZapGo Private** é uma implementação profissional da biblioteca [@tulir/whatsmeow](https://github.com/tulir/whatsmeow) como um serviço de API RESTful completo com suporte a múltiplos dispositivos, sessões simultâneas e integração com diversas ferramentas empresariais.

### 🎯 Características Principais

- **🔥 Alto Performance**: Desenvolvido em Go para máxima eficiência
- **📱 Multi-Device Support**: Suporte completo a múltiplos dispositivos WhatsApp
- **🔄 Concurrent Sessions**: Múltiplas sessões simultâneas
- **💌 Rich Messages**: Suporte a mensagens de texto, imagens, vídeos, documentos e mais
- **🔗 Webhooks**: Sistema completo de webhooks para eventos em tempo real
- **✅ User Verification**: Verificação avançada de usuários
- **🔐 Authentication**: Sistema de autenticação robusto
- **🐰 RabbitMQ Integration**: Integração completa com RabbitMQ para mensageria
- **☁️ S3 Storage**: Armazenamento de mídia em S3 (AWS, MinIO, etc.)
- **🌐 Proxy Support**: Suporte a proxy para conexões WhatsApp
- **👥 Grupos e Comunidades**: Gerenciamento completo de grupos e comunidades WhatsApp
- **📢 Newsletter/Channels**: Suporte a newsletters, canais e comunidades WhatsApp
- **❤️ System Health**: Monitoramento de saúde do sistema

## 🚀 Quick Start

## 🧩 Docker Compose (Swarm) — v1.2.4

```yaml
# =================== ZUCKZAPGO STACK PARA PORTAINER ===================
# Stack completa do ZuckZapGo com todos os serviços necessários
# Configurada para uso em produção com Docker Swarm via Portainer

services:
  zuckzapgo_private:
    image: setupautomatizado/zuckzapgo-private:latest
    networks:
      - network_public
    environment:
      # =================== LICENCIAMENTO E IDENTIDADE ===================
      # LICENSE_KEY: Chave de licença emitida pela ZuckZapGo; habilita ou restringe recursos como botões e flows.
      - LICENSE_KEY=ZUCKZAPGO-BASIC-C231653DD4F34B20
      # INSTANCE_ID: Identificador opcional desta instância; use para rastrear ambientes multi-tenant ou clusters.
      - INSTANCE_ID=
      # SERVER_IP: Endereço IP público divulgado para integrações externas que exigem IP fixo; deixe vazio se usar DNS.
      - SERVER_IP=

      # =================== ENDEREÇOS DA APLICAÇÃO ===================
      # ZUCKZAPGO_ADDRESS: URL base publicada em todos os eventos (webhook, filas, sockets) indicando a origem da instância.
      - ZUCKZAPGO_ADDRESS=https://go.setupautomatizado.com
      # ZUCKZAPGO_PORT: Porta HTTP exposta pelo backend; precisa coincidir com o mapeamento de portas do container.
      - ZUCKZAPGO_PORT=8080

      # =================== OBSERVABILIDADE DE LOGS ===================
      # ZUCKZAPGO_LOG_LEVEL: Nível mínimo de log global (debug, info, warn, error) respeitado por todo o serviço.
      - ZUCKZAPGO_LOG_LEVEL=info
      # ZUCKZAPGO_DEBUG: Nível de log dedicado ao cliente WhatsMeow; vazio usa o padrão info.
      - ZUCKZAPGO_DEBUG=info
      # LOG_TYPE: Destino/formato do logger estruturado (ex.: console, json).
      - LOG_TYPE=console
      # LOG_COLOR: Quando true, habilita códigos ANSI para colorir logs no console.
      - LOG_COLOR=true

      # =================== AUTENTICAÇÃO INTERNA ===================
      # ZUCKZAPGO_ADMIN_TOKEN: Token estático exigido em endpoints administrativos protegidos da API.
      - ZUCKZAPGO_ADMIN_TOKEN=H4Zbhw72PBKdTIgS

      # =================== IDENTIDADE DA SESSÃO ===================
      # SESSION_DEVICE_NAME: Nome apresentado ao WhatsApp para identificar o dispositivo da sessão global.
      - SESSION_DEVICE_NAME=zuckzapgo
      # TZ: Timezone padrão utilizado por logs, agendadores e conversões de horário.
      - TZ=America/Sao_Paulo

      # ========== CONFIGURAÇÕES PADRÃO DE DISPOSITIVO WHATSAPP ==========
      # ========================================
      # NOTAS IMPORTANTES
      # ========================================
      #
      # 1. TODAS as configurações são OPCIONAIS
      # 2. Se não configuradas, usa padrões da whatsmeow
      # 3. Configurações por usuário sobrepõem globais
      # 4. Configurações aplicadas ANTES da conexão WhatsApp
      # 5. Para alterar configurações existentes, desconecte e reconecte o usuário
      # 6. Valores inválidos usam padrões com log de aviso
      #
      # ========================================
      # VALORES VÁLIDOS POR CAMPO
      # ========================================
      #
      # waPlatform:
      # ANDROID, IOS, WINDOWS_PHONE, BLACKBERRY, BLACKBERRYX, S40, S60,
      # PYTHON_CLIENT, TIZEN, ENTERPRISE, SMB_ANDROID, KAIOS, SMB_IOS,
      # WINDOWS, WEB, PORTAL, GREEN_ANDROID, GREEN_IPHONE, BLUE_ANDROID,
      # BLUE_IPHONE, FBLITE_ANDROID, MLITE_ANDROID, IGLITE_ANDROID, PAGE,
      # MACOS, OCULUS_MSG, OCULUS_CALL, MILAN, CAPI, WEAROS, ARDEVICE,
      # VRDEVICE, BLUE_WEB, IPAD, TEST, SMART_GLASSES, BLUE_VR
      #
      # waReleaseChannel:
      # RELEASE, BETA, ALPHA, DEBUG
      #
      # waWebSubPlatform:
      # WEB_BROWSER, APP_STORE, WIN_STORE, DARWIN, WIN32, WIN_HYBRID
      #
      # waConnectType:
      # CELLULAR_UNKNOWN, WIFI_UNKNOWN, CELLULAR_EDGE, CELLULAR_IDEN,
      # CELLULAR_UMTS, CELLULAR_EVDO, CELLULAR_GPRS, CELLULAR_HSDPA,
      # CELLULAR_HSUPA, CELLULAR_HSPA, CELLULAR_CDMA, CELLULAR_1XRTT,
      # CELLULAR_EHRPD, CELLULAR_LTE, CELLULAR_HSPAP
      #
      # waPlatformType:
      # UNKNOWN, CHROME, FIREFOX, IE, OPERA, SAFARI, EDGE, DESKTOP, IPAD,
      # ANDROID_TABLET, OHANA, ALOHA, CATALINA, TCL_TV, IOS_PHONE,
      # IOS_CATALYST, ANDROID_PHONE, ANDROID_AMBIGUOUS, WEAR_OS, AR_WRIST,
      # AR_DEVICE, UWP, VR, CLOUD_API, SMARTGLASSES

      # Este arquivo mostra como configurar as opções avançadas do WhatsApp
      # através de variáveis de ambiente (globais) ou via API (por usuário).
      #
      # IMPORTANTE: Estas configurações são OPCIONAIS. Se não definidas,
      # o ZuckZapGo usa os padrões da biblioteca whatsmeow.

      # ========================================
      # CONFIGURAÇÕES GLOBAIS (Variáveis de Ambiente)
      # ========================================
      # Aplicam-se a TODOS os usuários se não configuradas individualmente

      # Versão do WhatsApp Web (formato: primary.secondary.tertiary)
      # WA_VERSION=2.3000.1028259376

      # Plataforma do dispositivo
      # Opções: WEB, ANDROID, IOS, WINDOWS, MACOS, IPAD, etc.
      # WA_PLATFORM=WEB

      # Canal de release
      # Opções: RELEASE, BETA, ALPHA, DEBUG
      # WA_RELEASE_CHANNEL=RELEASE

      # Sub-plataforma para Web
      # Opções: WEB_BROWSER, APP_STORE, WIN_STORE, DARWIN, WIN32, WIN_HYBRID
      # WA_WEB_SUB_PLATFORM=WEB_BROWSER

      # Sistema operacional
      # WA_OS_NAME=Mac OS
      # WA_OS_VERSION=10.15.7

      # Informações do dispositivo
      # WA_DEVICE_NAME=SAFARI
      # WA_MANUFACTURER=Apple
      # WA_DEVICE_BOARD=

      # Configurações de localização
      # WA_LOCALE_LANGUAGE=en
      # WA_LOCALE_COUNTRY=US

      # Códigos de rede móvel
      # WA_MCC=000
      # WA_MNC=000

      # Tipo de conexão
      # Opções: WIFI_UNKNOWN, CELLULAR_UNKNOWN, CELLULAR_LTE, etc.
      # WA_CONNECT_TYPE=WIFI_UNKNOWN

      # Tipo de plataforma para DeviceProps
      # Opções: DESKTOP, CHROME, FIREFOX, SAFARI, EDGE, IPAD, etc.
      # WA_PLATFORM_TYPE=SAFARI

      # =================== CONFIGURAÇÕES DE WEBHOOK INDIVIDUAL ===================
      # WEBHOOK_FORMAT: Formato padrão do payload enviado para webhooks individuais (json ou form).
      - WEBHOOK_FORMAT=json
      # WEBHOOK_TIMEOUT: Tempo máximo de espera por resposta do webhook individual antes de considerar timeout.
      - WEBHOOK_TIMEOUT=30s
      # WEBHOOK_MAX_RETRIES: Número de tentativas adicionais após uma falha no webhook individual.
      - WEBHOOK_MAX_RETRIES=3
      # WEBHOOK_RETRY_DELAY: Intervalo inicial entre retentativas de webhook individual.
      - WEBHOOK_RETRY_DELAY=2s
      # WEBHOOK_MAX_RETRY_DELAY: Limite superior para o backoff exponencial de webhook individual.
      - WEBHOOK_MAX_RETRY_DELAY=30s
      # WEBHOOK_BACKOFF_FACTOR: Fator multiplicador aplicado ao delay a cada nova tentativa.
      - WEBHOOK_BACKOFF_FACTOR=2.0
      # WEBHOOK_MAX_CONCURRENCY: Quantidade máxima de entregas simultâneas de webhooks individuais.
      - WEBHOOK_MAX_CONCURRENCY=100

      # =================== BANCO DE DADOS ===================
      # DATABASE_URL: String de conexão completa para o banco primário (Postgres/MySQL) usada pela aplicação.
      - DATABASE_URL=postgres://zuckzapgo:zuckzapgo@localhost:5432/zuckzapgo?sslmode=disable&search_path=public
      # DB_TYPE: Driver relacional preferido (postgres ou mysql) quando utilizar variáveis isoladas.
      - DB_TYPE=postgres

      # =================== FILTROS GLOBAIS DE EVENTOS ===================
      # GLOBAL_SKIP_MEDIA_DOWNLOAD: Se true, desativa o download de mídias para todos os usuários.
      - GLOBAL_SKIP_MEDIA_DOWNLOAD=false
      # GLOBAL_SKIP_GROUPS: Se true, ignora eventos originados em conversas de grupo.
      - GLOBAL_SKIP_GROUPS=true
      # GLOBAL_SKIP_NEWSLETTERS: Se true, descarta eventos vindos de newsletters.
      - GLOBAL_SKIP_NEWSLETTERS=true
      # GLOBAL_SKIP_BROADCASTS: Se true, não processa mensagens de listas de transmissão e status.
      - GLOBAL_SKIP_BROADCASTS=true
      # GLOBAL_SKIP_OWN_MESSAGES: Se true, ignora mensagens enviadas pelo próprio usuário.
      - GLOBAL_SKIP_OWN_MESSAGES=true
      # GLOBAL_SKIP_CALLS: Se true, bloqueia o processamento de eventos de chamadas.
      - GLOBAL_SKIP_CALLS=true
      # GLOBAL_CALL_REJECT_MESSAGE: Mensagem fixa enviada ao rejeitar automaticamente chamadas recebidas.
      - GLOBAL_CALL_REJECT_MESSAGE=Sorry, I cannot take calls at the moment.
      # GLOBAL_CALL_REJECT_TYPE: Tipo de rejeição aplicado (busy, decline ou unavailable).
      - GLOBAL_CALL_REJECT_TYPE=busy

      # =================== COMPORTAMENTO DE API ===================
      # ECHO_API_MESSAGES_ENABLED: Quando true, gera eventos de confirmação para mensagens disparadas via API (echo).
      - ECHO_API_MESSAGES_ENABLED=false

      # =================== ARMAZENAMENTO GLOBAL S3 ===================
      # GLOBAL_S3_ENABLED: Controla se mídias globais serão persistidas em um bucket S3.
      - GLOBAL_S3_ENABLED=true
      # GLOBAL_S3_ENDPOINT: Endpoint HTTP(S) do provedor S3; deixe vazio para AWS padrão.
      - GLOBAL_S3_ENDPOINT=https://s3.setupautomatizado.com.br
      # GLOBAL_S3_REGION: Região S3 utilizada na autenticação e geração de URLs.
      - GLOBAL_S3_REGION=us-east-1
      # GLOBAL_S3_BUCKET: Nome do bucket onde as mídias globais serão guardadas.
      - GLOBAL_S3_BUCKET=zuckzapgo
      # GLOBAL_S3_ACCESS_KEY: Access key do provedor S3 (deixe vazio para perfis IAM).
      - GLOBAL_S3_ACCESS_KEY=
      # GLOBAL_S3_SECRET_KEY: Secret key do provedor S3 (deixe vazio para perfis IAM).
      - GLOBAL_S3_SECRET_KEY=
      # GLOBAL_S3_PATH_STYLE: Quando true, utiliza path-style URLs (compatível com MinIO/outros provedores).
      - GLOBAL_S3_PATH_STYLE=true
      # GLOBAL_S3_PUBLIC_URL: URL pública usada para montar links acessíveis externamente.
      - GLOBAL_S3_PUBLIC_URL=https://s3.setupautomatizado.com.br
      # GLOBAL_S3_MEDIA_DELIVERY: Modo de entrega das mídias nos eventos (base64, url ou both).
      - GLOBAL_S3_MEDIA_DELIVERY=url
      # GLOBAL_S3_RETENTION_DAYS: Quantidade de dias antes de expirar objetos armazenados (0 desativa expiração).
      - GLOBAL_S3_RETENTION_DAYS=1
      # GLOBAL_S3_DISABLE_ACL: Define se ACLs individuais serão suprimidos; true para buckets com Bucket Owner Enforced.
      - GLOBAL_S3_DISABLE_ACL=true

      # =================== DISTRIBUIÇÃO GLOBAL SQS ===================
      # GLOBAL_SQS_ENABLED: Ativa o fan-out de eventos para uma fila Amazon SQS.
      - GLOBAL_SQS_ENABLED=false
      # GLOBAL_SQS_REGION: Região AWS onde a fila SQS está provisionada.
      - GLOBAL_SQS_REGION=us-east-1
      # GLOBAL_SQS_QUEUE_URL: URL completa da fila SQS alvo.
      - GLOBAL_SQS_QUEUE_URL=
      # GLOBAL_SQS_PROFILE: Perfil AWS CLI usado localmente (opcional).
      - GLOBAL_SQS_PROFILE=
      # GLOBAL_SQS_ACCESS_KEY: Access key AWS dedicada ao uso da fila.
      - GLOBAL_SQS_ACCESS_KEY=
      # GLOBAL_SQS_SECRET_KEY: Secret key AWS correspondente.
      - GLOBAL_SQS_SECRET_KEY=
      # GLOBAL_SQS_SESSION_TOKEN: Token temporário (STS) quando utilizado.
      - GLOBAL_SQS_SESSION_TOKEN=
      # GLOBAL_SQS_ENDPOINT: Endpoint customizado para LocalStack ou provedores compatíveis.
      - GLOBAL_SQS_ENDPOINT=
      # GLOBAL_SQS_FIFO: Indica se a fila utiliza modo FIFO.
      - GLOBAL_SQS_FIFO=false
      # GLOBAL_SQS_MESSAGE_GROUP: Identificador do grupo de mensagens FIFO.
      - GLOBAL_SQS_MESSAGE_GROUP=zuckzapgo-global
      # GLOBAL_SQS_DELAY_SECONDS: Delay padrão aplicado a cada mensagem publicada.
      - GLOBAL_SQS_DELAY_SECONDS=0
      # GLOBAL_SQS_EVENTS: Eventos encaminhados para a fila (lista ou 'All').
      - GLOBAL_SQS_EVENTS=All
      # GLOBAL_SQS_TIMEOUT: Timeout das operações de publicação na fila.
      - GLOBAL_SQS_TIMEOUT=5s
      # GLOBAL_SQS_RETRY_DELAY: Intervalo entre retentativas em caso de falha.
      - GLOBAL_SQS_RETRY_DELAY=750ms
      # GLOBAL_SQS_MAX_RETRIES: Quantidade máxima de tentativas antes de desistir.
      - GLOBAL_SQS_MAX_RETRIES=3

      # =================== STREAMS REDIS GLOBAL ===================
      # GLOBAL_REDIS_ENABLED: Ativa distribuição de eventos em Redis Streams globais.
      - GLOBAL_REDIS_ENABLED=false
      # GLOBAL_REDIS_ADDRESS: Endereço host:porta do servidor Redis alvo.
      - GLOBAL_REDIS_ADDRESS=localhost:6379
      # GLOBAL_REDIS_USERNAME: Usuário opcional para autenticação Redis ACL.
      - GLOBAL_REDIS_USERNAME=
      # GLOBAL_REDIS_PASSWORD: Senha associada ao usuário Redis.
      - GLOBAL_REDIS_PASSWORD=
      # GLOBAL_REDIS_TLS: Quando true, estabelece a conexão Redis via TLS.
      - GLOBAL_REDIS_TLS=false
      # GLOBAL_REDIS_STREAM: Nome do stream onde os eventos serão escritos.
      - GLOBAL_REDIS_STREAM=zuckzapgo.events
      # GLOBAL_REDIS_EVENTS: Eventos elegíveis para publicação em Redis.
      - GLOBAL_REDIS_EVENTS=All
      # GLOBAL_REDIS_MAXLEN: Comprimento máximo do stream antes de truncar mensagens antigas.
      - GLOBAL_REDIS_MAXLEN=100000
      # GLOBAL_REDIS_TRIM_APPROX: Se true, a poda do stream é aproximada (mais rápida).
      - GLOBAL_REDIS_TRIM_APPROX=true
      # GLOBAL_REDIS_TIMEOUT: Timeout de operações com Redis.
      - GLOBAL_REDIS_TIMEOUT=2s
      # GLOBAL_REDIS_RETRY_DELAY: Delay entre retentativas ao falhar.
      - GLOBAL_REDIS_RETRY_DELAY=500ms
      # GLOBAL_REDIS_MAX_RETRIES: Quantidade máxima de tentativas antes de abortar.
      - GLOBAL_REDIS_MAX_RETRIES=3

      # =================== ENTREGAS VIA WEBSOCKET ===================
      # GLOBAL_WEBSOCKET_ENABLED: Habilita broadcast global de eventos via WebSocket.
      - GLOBAL_WEBSOCKET_ENABLED=false
      # GLOBAL_WEBSOCKET_ENDPOINTS: Lista de endpoints ws:// ou wss:// separados por vírgula.
      - GLOBAL_WEBSOCKET_ENDPOINTS=
      # GLOBAL_WEBSOCKET_EVENTS: Eventos encaminhados por WebSocket (lista ou 'All').
      - GLOBAL_WEBSOCKET_EVENTS=All
      # GLOBAL_WEBSOCKET_ENABLE_COMPRESSION: Quando true, ativa compressão no transporte WebSocket.
      - GLOBAL_WEBSOCKET_ENABLE_COMPRESSION=true
      # GLOBAL_WEBSOCKET_HEADERS: Cabeçalhos adicionais enviados na conexão WebSocket.
      - GLOBAL_WEBSOCKET_HEADERS=
      # GLOBAL_WEBSOCKET_TIMEOUT: Tempo limite para estabelecer a conexão.
      - GLOBAL_WEBSOCKET_TIMEOUT=10s
      # GLOBAL_WEBSOCKET_WRITE_TIMEOUT: Timeout aplicado durante o envio de mensagens.
      - GLOBAL_WEBSOCKET_WRITE_TIMEOUT=5s
      # GLOBAL_WEBSOCKET_RETRY_DELAY: Delay inicial para novas tentativas de conexão.
      - GLOBAL_WEBSOCKET_RETRY_DELAY=2s
      # GLOBAL_WEBSOCKET_MAX_RETRIES: Número máximo de tentativas de reconexão.
      - GLOBAL_WEBSOCKET_MAX_RETRIES=5

      # =================== WEBHOOK GLOBAL ===================
      # GLOBAL_WEBHOOK_ENABLED: Ativa entrega de eventos para um endpoint global.
      - GLOBAL_WEBHOOK_ENABLED=false
      # GLOBAL_WEBHOOK_URL: Endpoint HTTP que receberá todos os eventos globais.
      - GLOBAL_WEBHOOK_URL=https://hook.prod.setupautomatizado.com.br/webhook/debug-zuckzapgo
      # GLOBAL_WEBHOOK_EVENTS: Eventos filtrados e enviados ao webhook global.
      - GLOBAL_WEBHOOK_EVENTS=All
      # GLOBAL_WEBHOOK_TIMEOUT: Tempo máximo para resposta do webhook global.
      - GLOBAL_WEBHOOK_TIMEOUT=30s
      # GLOBAL_WEBHOOK_RETRY_COUNT: Total de retentativas em caso de falha.
      - GLOBAL_WEBHOOK_RETRY_COUNT=3
      # GLOBAL_WEBHOOK_RETRY_DELAY: Delay inicial entre retentativas.
      - GLOBAL_WEBHOOK_RETRY_DELAY=2s
      # GLOBAL_WEBHOOK_MAX_RETRY_DELAY: Teto do backoff exponencial nas retentativas.
      - GLOBAL_WEBHOOK_MAX_RETRY_DELAY=30s
      # GLOBAL_WEBHOOK_BACKOFF_FACTOR: Multiplicador aplicado ao delay a cada tentativa.
      - GLOBAL_WEBHOOK_BACKOFF_FACTOR=2.0
      # GLOBAL_WEBHOOK_CONCURRENCY: Quantidade máxima de envios simultâneos ao webhook global.
      - GLOBAL_WEBHOOK_CONCURRENCY=50

      # =================== RABBITMQ GLOBAL - HABILITAÇÃO ===================
      # GLOBAL_RABBITMQ_ENABLED: Habilita fan-out global de eventos através do RabbitMQ.
      - GLOBAL_RABBITMQ_ENABLED=false
      # GLOBAL_RABBITMQ_URL: URL AMQP com usuário, senha e vhost do cluster RabbitMQ.
      - GLOBAL_RABBITMQ_URL=amqp://zuckzapgo:zuckzapgo@localhost:5672/zuckzapgo
      # GLOBAL_RABBITMQ_EVENTS: Eventos roteados para o exchange global.
      - GLOBAL_RABBITMQ_EVENTS=Message
      # GLOBAL_RABBITMQ_EXCHANGE: Exchange destino para publicação dos eventos globais.
      - GLOBAL_RABBITMQ_EXCHANGE=zuckzapgo.global
      # GLOBAL_RABBITMQ_EXCHANGE_TYPE: Tipo de exchange (topic, fanout, direct, etc).
      - GLOBAL_RABBITMQ_EXCHANGE_TYPE=topic
      # GLOBAL_RABBITMQ_QUEUE: Template de nome das filas globais (aceita placeholders).
      - GLOBAL_RABBITMQ_QUEUE=zuckzapgo_{user_id}_{event_type}_events
      # GLOBAL_RABBITMQ_ROUTING_KEY: Template de routing key usada nos bindings.
      - GLOBAL_RABBITMQ_ROUTING_KEY=events.{user_id}.{event_type}
      # GLOBAL_RABBITMQ_QUEUE_TYPE: Tipo da fila declarada (classic, quorum, stream).
      - GLOBAL_RABBITMQ_QUEUE_TYPE=classic
      # GLOBAL_RABBITMQ_DURABLE: Define se filas/exchanges sobrevivem a reinícios do broker.
      - GLOBAL_RABBITMQ_DURABLE=true
      # GLOBAL_RABBITMQ_AUTO_DELETE: Remove filas/exchanges automaticamente quando não houver consumidores.
      - GLOBAL_RABBITMQ_AUTO_DELETE=false
      # GLOBAL_RABBITMQ_EXCLUSIVE: Se true, fila exclusiva para a conexão (não compartilhada).
      - GLOBAL_RABBITMQ_EXCLUSIVE=false
      # GLOBAL_RABBITMQ_NO_WAIT: Evita aguardar confirmações nas declarações AMQP.
      - GLOBAL_RABBITMQ_NO_WAIT=false
      # GLOBAL_RABBITMQ_DELIVERY_MODE: Modo de entrega: 1 não persistente, 2 persistente.
      - GLOBAL_RABBITMQ_DELIVERY_MODE=2

      # =================== RABBITMQ GLOBAL - PERFORMANCE E RESILIÊNCIA ===================
      # GLOBAL_RABBITMQ_CONNECTION_POOL_SIZE: Quantidade de conexões paralelas utilizadas para publicar eventos.
      - GLOBAL_RABBITMQ_CONNECTION_POOL_SIZE=50
      # GLOBAL_RABBITMQ_WORKER_COUNT: Número de workers dedicados ao processamento global.
      - GLOBAL_RABBITMQ_WORKER_COUNT=100
      # GLOBAL_RABBITMQ_QUEUE_BUFFER_SIZE: Buffer interno de mensagens aguardando publicação.
      - GLOBAL_RABBITMQ_QUEUE_BUFFER_SIZE=100000
      # GLOBAL_RABBITMQ_ENABLE_BATCHING: Quando true, agrupa mensagens em lotes para ganho de throughput.
      - GLOBAL_RABBITMQ_ENABLE_BATCHING=true
      # GLOBAL_RABBITMQ_BATCH_SIZE: Quantidade máxima de mensagens em cada lote.
      - GLOBAL_RABBITMQ_BATCH_SIZE=1000
      # GLOBAL_RABBITMQ_BATCH_TIMEOUT_MS: Tempo máximo (ms) aguardando completar um lote.
      - GLOBAL_RABBITMQ_BATCH_TIMEOUT_MS=100
      # GLOBAL_RABBITMQ_CIRCUIT_BREAKER_THRESHOLD: Falhas consecutivas necessárias para abrir o circuito.
      - GLOBAL_RABBITMQ_CIRCUIT_BREAKER_THRESHOLD=20
      # GLOBAL_RABBITMQ_CIRCUIT_BREAKER_TIMEOUT_S: Tempo de espera antes de testar reabertura do circuito.
      - GLOBAL_RABBITMQ_CIRCUIT_BREAKER_TIMEOUT_S=60
      # GLOBAL_RABBITMQ_PUBLISH_TIMEOUT_MS: Timeout por operação de publicação.
      - GLOBAL_RABBITMQ_PUBLISH_TIMEOUT_MS=5000
      # GLOBAL_RABBITMQ_MAX_RETRIES: Número máximo de retentativas por mensagem.
      - GLOBAL_RABBITMQ_MAX_RETRIES=5
      # GLOBAL_RABBITMQ_RETRY_DELAY_MS: Delay (ms) entre retentativas.
      - GLOBAL_RABBITMQ_RETRY_DELAY_MS=500
      # GLOBAL_RABBITMQ_METRICS_INTERVAL_S: Intervalo (s) de coleta e emissão de métricas do transporte.
      - GLOBAL_RABBITMQ_METRICS_INTERVAL_S=10

      # =================== RABBITMQ GLOBAL - OBSERVABILIDADE ===================
      # GLOBAL_RABBITMQ_ENABLE_DETAILED_LOGS: Quando true, habilita logs detalhados do transporte RabbitMQ.
      - GLOBAL_RABBITMQ_ENABLE_DETAILED_LOGS=false
      # GLOBAL_RABBITMQ_ENABLE_METRICS_LOG: Quando true, registra métricas periódicas no log.
      - GLOBAL_RABBITMQ_ENABLE_METRICS_LOG=true
      # GLOBAL_RABBITMQ_QOS_PREFETCH_COUNT: Quantidade de mensagens pré-buscadas por consumidor.
      - GLOBAL_RABBITMQ_QOS_PREFETCH_COUNT=100
      # GLOBAL_RABBITMQ_MANDATORY: Se true, exige roteamento obrigatório (mensagens não roteadas retornam).
      - GLOBAL_RABBITMQ_MANDATORY=false
      # GLOBAL_RABBITMQ_IMMEDIATE: Flag obsoleta do AMQP; mantenha false salvo compatibilidade legada.
      - GLOBAL_RABBITMQ_IMMEDIATE=false
      # GLOBAL_RABBITMQ_ENABLE_COMPRESSION: Comprime payloads antes de publicar para reduzir banda.
      - GLOBAL_RABBITMQ_ENABLE_COMPRESSION=false
      # GLOBAL_RABBITMQ_ENABLE_PERSISTENCE: Garante persistência em disco das mensagens publicadas.
      - GLOBAL_RABBITMQ_ENABLE_PERSISTENCE=true
      # GLOBAL_RABBITMQ_ENABLE_CONFIRMATION: Habilita publisher confirms para garantir recebimento pelo broker.
      - GLOBAL_RABBITMQ_ENABLE_CONFIRMATION=true

      # =================== RABBITMQ POR INSTÂNCIA ===================
      # RABBITMQ_CONNECTION_POOL_SIZE: Tamanho do pool de conexões dedicado a cada instância de cliente.
      - RABBITMQ_CONNECTION_POOL_SIZE=50
      # RABBITMQ_WORKER_COUNT: Total de workers concorrentes por instância.
      - RABBITMQ_WORKER_COUNT=100
      # RABBITMQ_QUEUE_BUFFER_SIZE: Buffer interno de mensagens por instância.
      - RABBITMQ_QUEUE_BUFFER_SIZE=100000
      # RABBITMQ_BATCH_SIZE: Quantidade de mensagens por lote em instâncias individuais.
      - RABBITMQ_BATCH_SIZE=1000
      # RABBITMQ_BATCH_TIMEOUT_MS: Timeout (ms) para completar lote individual.
      - RABBITMQ_BATCH_TIMEOUT_MS=100
      # RABBITMQ_PUBLISH_TIMEOUT_MS: Timeout de publicação por instância.
      - RABBITMQ_PUBLISH_TIMEOUT_MS=5000
      # RABBITMQ_MAX_RETRIES: Retentativas locais por mensagem.
      - RABBITMQ_MAX_RETRIES=5
      # RABBITMQ_RETRY_DELAY_MS: Delay (ms) entre retentativas locais.
      - RABBITMQ_RETRY_DELAY_MS=500

      # =================== TRACING DISTRIBUÍDO ===================
      # TRACING_ENABLED: Ativa a instrumentação OpenTelemetry na aplicação.
      - TRACING_ENABLED=false
      # JAEGER_ENDPOINT: Endpoint OTLP HTTP utilizado para enviar spans ao Jaeger.
      - JAEGER_ENDPOINT=http://localhost:14268/api/traces
      # JAEGER_SAMPLING_RATIO: Percentual de requisições amostradas (0.0 a 1.0).
      - JAEGER_SAMPLING_RATIO=0.1
      # TRACING_SERVICE_NAME: Nome lógico do serviço reportado ao tracer.
      - TRACING_SERVICE_NAME=zuckzapgo
      # TRACING_SERVICE_VERSION: Versão reportada nas tags de tracing.
      - TRACING_SERVICE_VERSION=v.1.2.5
      # TRACING_ENVIRONMENT: Identificador do ambiente (development, staging, production).
      - TRACING_ENVIRONMENT=development

      # =================== MONITORAMENTO DE ERROS (SENTRY) ===================
      # SENTRY_ENABLED: Liga/desliga a captura de exceções pela SDK do Sentry.
      - SENTRY_ENABLED=false
      # SENTRY_DSN: DSN fornecido pelo projeto Sentry para autenticação.
      - SENTRY_DSN=
      # SENTRY_ENVIRONMENT: Ambiente lógico usado para agrupar eventos no Sentry.
      - SENTRY_ENVIRONMENT=development
      # SENTRY_SAMPLE_RATE: Percentual de erros capturados (0.0 a 1.0).
      - SENTRY_SAMPLE_RATE=1.0
      # SENTRY_TRACES_SAMPLE_RATE: Percentual de transações de performance coletadas.
      - SENTRY_TRACES_SAMPLE_RATE=0.1
      # SENTRY_PROFILES_SAMPLE_RATE: Percentual de perfis de CPU/memória coletados.
      - SENTRY_PROFILES_SAMPLE_RATE=0.1

      # =================== MÉTRICAS PROMETHEUS ===================
      # PROMETHEUS_ENABLED: Ativa a exportação de métricas para Prometheus.
      - PROMETHEUS_ENABLED=false
      # PROMETHEUS_METRICS_PATH: Path HTTP exposto com as métricas.
      - PROMETHEUS_METRICS_PATH=/metrics
      # METRICS_COLLECTION_INTERVAL: Frequência de coleta interna de métricas.
      - METRICS_COLLECTION_INTERVAL=30s
      # BUFFER_METRICS_ENABLED: Quando true, inclui métricas específicas do buffer.
      - BUFFER_METRICS_ENABLED=true
      # TRANSPORT_METRICS_ENABLED: Quando true, inclui métricas das integrações (RabbitMQ, SQS, etc.).
      - TRANSPORT_METRICS_ENABLED=true

      # =================== PIPELINE GLOBAL DE EVENTOS ===================
      # GLOBAL_EVENT_BUFFER_USE_DATABASE: Se true, usa banco relacional como buffer persistente de eventos.
      - GLOBAL_EVENT_BUFFER_USE_DATABASE=true
      # GLOBAL_EVENT_BUFFER_VISIBILITY_TIMEOUT: Tempo de leasing antes de devolver o evento para a fila.
      - GLOBAL_EVENT_BUFFER_VISIBILITY_TIMEOUT=45s
      # GLOBAL_EVENT_BUFFER_RETRY_BASE: Delay base para cálculo de backoff exponencial.
      - GLOBAL_EVENT_BUFFER_RETRY_BASE=5s
      # GLOBAL_EVENT_BUFFER_RETRY_MAX: Limite máximo de delay entre tentativas.
      - GLOBAL_EVENT_BUFFER_RETRY_MAX=2m
      # GLOBAL_EVENT_BUFFER_MAX_ATTEMPTS: Número máximo de tentativas de entrega por evento.
      - GLOBAL_EVENT_BUFFER_MAX_ATTEMPTS=12
      # GLOBAL_EVENT_BUFFER_ARCHIVE_SUCCESS: Quando true, arquiva entregas bem-sucedidas além das falhas.
      - GLOBAL_EVENT_BUFFER_ARCHIVE_SUCCESS=false
      # GLOBAL_EVENT_DEDUP_WINDOW: Janela de tempo utilizada para deduplicar eventos idênticos.
      - GLOBAL_EVENT_DEDUP_WINDOW=2m
      # GLOBAL_EVENT_DEDUP_MAX_KEYS: Quantidade máxima de chaves armazenadas no cache de deduplicação.
      - GLOBAL_EVENT_DEDUP_MAX_KEYS=50000
      # GLOBAL_EVENT_BATCH_SIZE: Quantidade de eventos agrupados por envio.
      - GLOBAL_EVENT_BATCH_SIZE=1
      # GLOBAL_EVENT_BATCH_TIMEOUT: Tempo máximo aguardando completar um lote.
      - GLOBAL_EVENT_BATCH_TIMEOUT=25ms
      # GLOBAL_EVENT_CIRCUIT_MAX_FAILURES: Falhas consecutivas que disparam o circuito de proteção.
      - GLOBAL_EVENT_CIRCUIT_MAX_FAILURES=5
      # GLOBAL_EVENT_CIRCUIT_RESET: Intervalo antes de testar reabertura do circuito.
      - GLOBAL_EVENT_CIRCUIT_RESET=30s
      # GLOBAL_EVENT_CIRCUIT_COOLDOWN: Espera entre verificações enquanto o circuito está aberto.
      - GLOBAL_EVENT_CIRCUIT_COOLDOWN=1s
      # GLOBAL_SKIP_CACHE_TTL: TTL do cache que evita reprocessar eventos filtrados.
      - GLOBAL_SKIP_CACHE_TTL=30s
      # GLOBAL_EVENT_BUFFER_RETENTION_DAYS: Quantidade de dias mantendo registros ativos no buffer.
      - GLOBAL_EVENT_BUFFER_RETENTION_DAYS=7
      # GLOBAL_EVENT_BUFFER_ARCHIVE_RETENTION_DAYS: Dias de retenção dos registros arquivados.
      - GLOBAL_EVENT_BUFFER_ARCHIVE_RETENTION_DAYS=30
      # GLOBAL_EVENT_BUFFER_PRUNE_INTERVAL: Intervalo entre execuções de limpeza do buffer.
      - GLOBAL_EVENT_BUFFER_PRUNE_INTERVAL=1h
      # GLOBAL_EVENT_BUFFER_PRUNE_BATCH_SIZE: Número de registros processados por lote na limpeza.
      - GLOBAL_EVENT_BUFFER_PRUNE_BATCH_SIZE=1000
      # GLOBAL_EVENT_BUFFER_AUTO_PARTITION: Habilita criação automática de partições no banco do buffer.
      - GLOBAL_EVENT_BUFFER_AUTO_PARTITION=false
      # GLOBAL_EVENT_BUFFER_PARTITION_RETENTION_MONTHS: Meses mantidos por partição histórica do buffer.
      - GLOBAL_EVENT_BUFFER_PARTITION_RETENTION_MONTHS=6

      # =================== CONTROLE DE ENCERRAMENTO ===================
      # SHUTDOWN_GRACE_PERIOD: Tempo máximo aguardado para finalizar workers antes de encerrar o processo.
      - SHUTDOWN_GRACE_PERIOD=30s
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
      placement:
        constraints: [node.role == manager]
      resources:
        limits:
          cpus: "2" # Increased for RabbitMQ Global performance
          memory: 2GB # Increased for high-throughput message processing
        reservations:
          cpus: "1"
          memory: 1GB
      labels:
        - traefik.enable=true
        - traefik.http.routers.zuckzapgo_private.rule=Host(`api.zuckzapgo.app`)
        - traefik.http.routers.zuckzapgo_private.entrypoints=websecure
        - traefik.http.routers.zuckzapgo_private.priority=1
        - traefik.http.routers.zuckzapgo_private.tls.certresolver=letsencryptresolver
        - traefik.http.routers.zuckzapgo_private.service=zuckzapgo_private
        - traefik.http.services.zuckzapgo_private.loadbalancer.server.port=8080
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s

  # =================== BANCO DE DADOS POSTGRESQL ===================
  postgres_zuckzapgo:
    image: pgvector/pgvector:pg16
    environment:
      - POSTGRES_USER=zuckzapgo
      - POSTGRES_PASSWORD=zuckzapgo
      - POSTGRES_DB=zuckzapgo
    volumes:
      - postgres_data_zuckzapgo:/var/lib/postgresql/data
    networks:
      - network_public
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: "1"
          memory: 1GB
        reservations:
          cpus: "0.5"
          memory: 512MB
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "pg_isready -U ${POSTGRES_USER:-zuckzapgo} -d ${POSTGRES_DB:-zuckzapgo}",
        ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # =================== MYSQL DATABASE (OPCIONAL) ===================
  # Descomente as linhas abaixo para usar MySQL ao invés de PostgreSQL
  # zuckzapgo_mysql:
  #   image: mysql:8.0
  #   environment:
  #     MYSQL_ROOT_PASSWORD: root_password_super_seguro
  #     MYSQL_DATABASE: zuckzapgo
  #     MYSQL_USER: zuckzapgo
  #     MYSQL_PASSWORD: zuckzapgo_production_password
  #     MYSQL_ROOT_HOST: '%'
  #   networks:
  #     - network_public
  #   volumes:
  #     - mysql_data_zuckzapgo:/var/lib/mysql
  #   command: >
  #     --default-authentication-plugin=mysql_native_password
  #     --character-set-server=utf8mb4
  #     --collation-server=utf8mb4_unicode_ci
  #     --innodb-buffer-pool-size=1G
  #     --max-connections=500
  #     --innodb-log-file-size=256M
  #   deploy:
  #     replicas: 1
  #     restart_policy:
  #       condition: on-failure
  #       delay: 5s
  #       max_attempts: 3
  #       window: 120s
  #     placement:
  #       constraints:
  #         - node.role == manager

  # =================== RABBITMQ (MENSAGERIA) ===================
  # rabbitmq_zuckzapgo:
  #   image: rabbitmq:4-management
  #   environment:
  #     - RABBITMQ_DEFAULT_USER=zuckzapgo
  #     - RABBITMQ_DEFAULT_PASS=zuckzapgo
  #     - RABBITMQ_DEFAULT_VHOST=zuckzapgo
  #   volumes:
  #     - rabbitmq_data_zuckzapgo:/var/lib/rabbitmq
  #   networks:
  #     - network_public
  #   deploy:
  #     mode: replicated
  #     replicas: 1
  #     placement:
  #       constraints: [node.role == manager]
  #     restart_policy:
  #       condition: on-failure
  #       delay: 5s
  #       max_attempts: 3
  #     resources:
  #       limits:
  #         cpus: "1"
  #         memory: 1GB
  #       reservations:
  #         cpus: "0.5"
  #         memory: 512MB
  #     labels:
  #       - traefik.enable=true
  #       - traefik.http.routers.rabbitmq_zuckzapgo.rule=Host(`rabbitmq.zuckzapgo.app`)
  #       - traefik.http.routers.rabbitmq_zuckzapgo.entrypoints=websecure
  #       - traefik.http.routers.rabbitmq_zuckzapgo.tls.certresolver=letsencryptresolver
  #       - traefik.http.routers.rabbitmq_zuckzapgo.service=rabbitmq_zuckzapgo
  #       - traefik.http.services.rabbitmq_zuckzapgo.loadbalancer.server.port=15672
  #   healthcheck:
  #     test: ["CMD", "rabbitmq-diagnostics", "ping"]
  #     interval: 30s
  #     timeout: 10s
  #     retries: 3
  #     start_period: 60s

  # =================== REDIS STREAMS ===================
  # redis_streams_zuckzapgo:
  #   image: redis:7
  #   networks:
  #     - network_public
  #   ports:
  #     - target: 6379
  #       published: 6379
  #       protocol: tcp
  #       mode: ingress
  #   volumes:
  #     - redis_streams_data_zuckzapgo:/data
  #   deploy:
  #     mode: replicated
  #     replicas: 1
  #     placement:
  #       constraints: [node.role == manager]
  #     restart_policy:
  #       condition: on-failure
  #       delay: 5s
  #       max_attempts: 3
  #   healthcheck:
  #     test: ["CMD", "redis-cli", "PING"]
  #     interval: 10s
  #     timeout: 5s
  #     retries: 5
  #     start_period: 15s

  # =================== JAEGER TRACING (OBSERVABILITY) ===================
  # jaeger_zuckzapgo:
  #   image: jaegertracing/all-in-one:latest
  #   deploy:
  #     replicas: 1
  #     placement:
  #       constraints:
  #         - node.role == manager
  #     restart_policy:
  #       condition: on-failure
  #       delay: 5s
  #       max_attempts: 3
  #     resources:
  #       limits:
  #         cpus: "1"
  #         memory: 1G
  #       reservations:
  #         cpus: "0.25"
  #         memory: 256M
  #   environment:
  # Enable OTLP collector (required for OpenTelemetry)
  # - COLLECTOR_OTLP_ENABLED=true
  # Storage configuration for production
  # For development: use memory
  # For production: configure external storage (Elasticsearch, Cassandra, etc)
  # - SPAN_STORAGE_TYPE=memory
  # - MEMORY_MAX_TRACES=50000
  # Sampling configuration
  #   - SAMPLING_STRATEGIES_FILE=/etc/jaeger/sampling_strategies.json
  # ports:
  # Jaeger UI - Web interface to view traces
  # - target: 16686
  #   published: 16686
  #   protocol: tcp
  #   mode: ingress
  # OTLP HTTP receiver - used by ZuckZapGo to send traces
  # - target: 4318
  #   published: 4318
  #   protocol: tcp
  #   mode: ingress
  # OTLP gRPC receiver (optional)
  # - target: 4317
  #   published: 4317
  #   protocol: tcp
  #   mode: ingress
  # Jaeger Collector HTTP (legacy - for compatibility)
  # - target: 14268
  #   published: 14268
  #   protocol: tcp
  #   mode: ingress
  # Admin port for health checks
  #   - target: 14269
  #     published: 14269
  #     protocol: tcp
  #     mode: host
  # networks:
  #   - network_public
  # healthcheck:
  #   test: ["CMD", "wget", "--spider", "-q", "http://localhost:14269/"]
  #   interval: 30s
  #   timeout: 10s
  #   retries: 3
  #   start_period: 20s
  # volumes:
  #   - jaeger_data_zuckzapgo:/tmp/jaeger

volumes:
  postgres_data_zuckzapgo:
    name: postgres_data_zuckzapgo
    external: true
  # rabbitmq_data_zuckzapgo:
  #   name: rabbitmq_data_zuckzapgo
  #   external: true
  # redis_streams_data_zuckzapgo:
  #   name: redis_streams_data
  # mysql_data_zuckzapgo:  # Descomente para MySQL
  #   name: mysql_data_zuckzapgo
  #   external: true
  # jaeger_data_zuckzapgo:
  #   name: jaeger_data_zuckzapgo
  #   external: true

networks:
  network_public:
    name: network_public
    external: true

```

## 🔧 Integrações

### N8N

Integração oficial via node comunitário para automação de fluxos WhatsApp no [n8n](https://n8n.io/), utilizando o ZuckZapGo como backend robusto multi-dispositivo.

#### 📦 Instalação

No painel do n8n:
1. Acesse **Settings** > **Community Nodes**
2. Clique em **Install a community node**
3. Procure por `n8n-nodes-zuckzapgo` e instale

Ou via terminal:
```bash
npm install n8n-nodes-zuckzapgo
```

Mais detalhes: [npmjs.com/package/n8n-nodes-zuckzapgo](https://www.npmjs.com/package/n8n-nodes-zuckzapgo)

#### 🧩 Modular Design

Este pacote segue um design modular, onde cada node foca em uma funcionalidade específica:

- **Gerenciamento de Sessão:** Conexão, autenticação e configuração
- **Mensageria:** Todas as operações de envio de mensagens
- **Operações de Chat:** Gerenciamento e interação com mensagens
- **Operações de Usuário:** Informações e presença do usuário
- **Gerenciamento de Grupos:** Funcionalidade completa de grupos
- **Configuração de Webhook:** Gerenciamento de assinaturas de eventos
- **Administração:** Gerenciamento de usuários (apenas admin)
- **Event Trigger:** Recepção de eventos em tempo real
- **Send and Wait:** Workflows interativos de aprovação
- **Integração com IA:** Node otimizado para ferramentas e fluxos de IA

#### ⚙️ Operações Suportadas

- **Sessão:** conectar, desconectar, QR code, status, proxy, S3, etc.
- **Mensagens:** texto, imagem, áudio, vídeo, documento, sticker, localização, contato, template, botões, listas, enquetes
- **Chats:** deletar, editar, baixar mídia, marcar como lida, reagir, presença
- **Usuário:** checar usuários, obter info, avatar, contatos, status, LID, privacidade
- **Grupos e Comunidades:** criar, listar, info, convite, entrar, sair, admins, foto, descrição, participantes, comunidades, permissões, etc.
- **Webhooks:** configurar, atualizar, remover webhooks
- **Admin:** listar/criar/deletar usuários (requer token admin)
- **Trigger:** receber eventos em tempo real (mensagens, recibos, presença, etc.)
- **AI:** envio de mensagens otimizadas para fluxos de IA, suporte a mídia, botões, listas, enquetes, etc.

#### 🚀 Exemplo de Uso

- Crie um novo workflow no n8n
- Adicione um node “ZuckZapGo Trigger” para receber eventos do WhatsApp em tempo real
- Adicione nodes “ZuckZapGo Message” para enviar mensagens, imagens, áudios, etc.
- Combine com outros nodes do n8n para automações, integrações com bancos de dados, APIs, IA, etc.

Mais exemplos e detalhes: [Documentação do pacote](https://www.npmjs.com/package/n8n-nodes-zuckzapgo)

#### 📚 Links Úteis

- [n8n-nodes-zuckzapgo (npm)](https://www.npmjs.com/package/n8n-nodes-zuckzapgo)
- [Repositório GitHub](https://github.com/guilhermejansen/n8n-nodes-zuckzapgo)
- [Documentação n8n Community Nodes](https://docs.n8n.io/integrations/community-nodes/)

#### 💡 Observações

- Compatível com todas as versões do ZuckZapGo
- Requer n8n v1.19.3+ e Node.js 20.15+
- Suporte a todos os tipos de mídia e mensagens do WhatsApp
- Suporte a automações avançadas, IA, e integrações empresariais

### Chatwoot
Integração completa com Chatwoot para atendimento ao cliente:
- Sincronização bidirecional de mensagens
- Criação automática de conversas
- Suporte a anexos e mídias
- Status de leitura e entrega

### RabbitMQ
Sistema de mensageria assíncrona:
- Eventos em tempo real
- Filas dinâmicas por usuário
- Retry automático
- Dead letter queues

### S3 Compatible Storage
Armazenamento de mídia flexível:
- AWS S3
- MinIO
- BlackBlazer
- DigitalOcean Spaces
- Google Cloud Storage

## 📊 Dashboard

Acesse o dashboard completo em `http://localhost:8080/dashboard` para:
- Monitoramento em tempo real
- Gerenciamento de usuários
- Configuração de webhooks
- Análise de mensagens
- Logs do sistema

## 🔐 Segurança

- Validação de entrada
- Sanitização de dados
- Logs de auditoria
- Criptografia de sessões

## 🌐 Suporte Multi-Arch

Esta imagem suporta múltiplas arquiteturas:
- `linux/amd64` (x86_64)
- `linux/arm64` (ARM 64-bit)

## 📋 Requisitos

- **RAM**: Mínimo 512MB, Recomendado 1GB+
- **Storage**: Mínimo 1GB livre
- **Network**: Conexão estável com internet
- **Database**: PostgreSQL 12+

## 🆘 Suporte

Para suporte técnico e comercial:
- **Email**: [contato@setupautomatizado.com.br](mailto:contato@setupautomatizado.com.br)
- **Website**: [https://zuckzapgo.com](https://zuckzapgo.com)
- **GitHub**: [https://github.com/guilhermejansen/use-zuckzapgo](https://github.com/guilhermejansen/use-zuckzapgo)

## 📄 Licença

Este projeto está sob licença comercial. Para mais informações sobre licenciamento, entre em contato conosco.

## 🤝 Contribuindo

Este é um projeto privado/comercial. Para contribuições, entre em contato através dos canais de suporte.

---

<p align="center">
  <strong>🚀 Desenvolvido com ❤️ por Setup Automatizado</strong>
</p>

<p align="center">
  <a href="https://setupautomatizado.com.br">Website</a> •
  <a href="mailto:contato@setupautomatizado.com.br">Email</a> •
  <a href="https://github.com/guilhermejansen">GitHub</a>
</p>
