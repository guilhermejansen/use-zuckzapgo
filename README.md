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
</p>

## 📝 Assine o ZuckZapGo

Para adquirir sua licença e acessar todos os recursos premium, faça sua assinatura de forma rápida e segura:

👉 [Assinar agora via Hotmart](https://go.hotmart.com/S101068222H?dp=1)

<p align="center">
  <img src="https://raw.githubusercontent.com/guilhermejansen/use-zuckzapgo/main/qrcode.svg" alt="Assine Agora ZuckZapGo Private" width="120" height="120">
</p>

👉 [Seja um afiliado agora via Hotmart](https://app-vlc.hotmart.com/affiliate-recruiting/view/3115Z101068243)

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

### Docker (Recomendado)

```yml
# =================== ZUCKZAPGO STACK PARA PORTAINER ===================
# Stack completa do ZuckZapGo com todos os serviços necessários
# Configurada para uso em produção com Docker Swarm via Portainer

services:
  zuckzapgo_private:
    # IMAGEM DISPONÍVEL: https://hub.docker.com/r/setupautomatizado/zuckzapgo-private
    image: setupautomatizado/zuckzapgo-private:latest # ou a versão que você deseja usar (exemplo: setupautomatizado/zuckzapgo-private:v1.0.0)
    networks:
      - network_public
    environment:
      # =================== ADMIN & AUTHENTICATION ===================
      - ZUCKZAPGO_ADMIN_TOKEN=SEU_TOKEN_AQUI_DO_ADMIN
      - ZUCKZAPGO_ADDRESS=api.seudominio.com # Adicione seu dominio
      - ZUCKZAPGO_PORT=8080

      - SERVER_IP=SEU_IP_AQUI #exemplo: 192.168.1.100
      - LICENSE_KEY=SUA_LICENÇA_AQUI_DA_ZUCKZAPGO
      - INSTANCE_ID=SUA_INSTANCE_NAME_AQUI #exemplo: zuckzapgo-1

      - LOG_TYPE=console # "console" ou "json"
      - LOG_COLOR=true # true ou false
      
      # =================== DATABASE CONFIGURATION ===================
      # Option 1: Individual database variables (current method)
      # - DB_USER=zuckzapgo
      # - DB_PASSWORD=SUA_SENHA_DO_BANCO_DE_DADOS # SENHA DO BANCO DE DADOS
      # - DB_NAME=zuckzapgo # NOME DO BANCO DE DADOS
      # - DB_HOST=postgres_zuckzapgo # NOME DO SERVIÇO DO BANCO DE DADOS
      # - DB_PORT=5432
      # - DB_SSLMODE=disable
      # - DB_SCHEMA=public

      # Option 2: Single database connection string (production method)
      # Uncomment the line below and comment out the individual variables above
      - DATABASE_URL=postgres://zuckzapgo:SUA_SENHA_DO_BANCO_DE_DADOS@postgres_zuckzapgo:5432/zuckzapgo?sslmode=disable&search_path=public
      # For managed databases: DATABASE_URL=postgres://user:pass@managed-db.example.com:5432/zuckzapgo?sslmode=require
      # For MySQL: DATABASE_URL=mysql://zuckzapgo:zuckzapgo_production_password@zuckzapgo_mysql:3306/zuckzapgo?charset=utf8mb4&parseTime=True&loc=Local

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
      - WA_VERSION=2.3000.1025465267
      #2.3000.1024995419

      # Plataforma do dispositivo
      # Opções: WEB, ANDROID, IOS, WINDOWS, MACOS, IPAD, etc.
      - WA_PLATFORM=WEB

      # Canal de release
      # Opções: RELEASE, BETA, ALPHA, DEBUG
      - WA_RELEASE_CHANNEL=BETA

      # Sub-plataforma para Web
      # Opções: WEB_BROWSER, APP_STORE, WIN_STORE, DARWIN, WIN32, WIN_HYBRID
      - WA_WEB_SUB_PLATFORM=WEB_BROWSER

      # Sistema operacional
      - WA_OS_NAME=Mac OS X
      - WA_OS_VERSION=10.15.7

      # Informações do dispositivo
      - WA_DEVICE_NAME=MacBook Pro
      - WA_MANUFACTURER=Apple
      - WA_DEVICE_BOARD=Mac

      # Configurações de localização
      - WA_LOCALE_LANGUAGE=en
      - WA_LOCALE_COUNTRY=US

      # Códigos de rede móvel
      - WA_MCC=000
      - WA_MNC=000

      # Tipo de conexão
      # Opções: WIFI_UNKNOWN, CELLULAR_UNKNOWN, CELLULAR_LTE, etc.
      - WA_CONNECT_TYPE=WIFI_UNKNOWN

      # Tipo de plataforma para DeviceProps
      # Opções: DESKTOP, CHROME, FIREFOX, SAFARI, EDGE, IPAD, etc.
      - WA_PLATFORM_TYPE=DESKTOP

      # =================== SESSION & TIMEZONE ===================
      - TZ=America/Sao_Paulo
      - SESSION_DEVICE_NAME=ZuckZapGo # NOME DO DISPOSITIVO

      # =================== WEBHOOK INDIVIDUAL POR INSTANICA CONFIGURATIONS ===================
      # "json" or "form" for the default
      - WEBHOOK_FORMAT=json 

      # Timeout principal da requisição HTTP
      - WEBHOOK_TIMEOUT=30s

      # Número máximo de tentativas de retry
      - WEBHOOK_MAX_RETRIES=3

      # Delay inicial entre tentativas
      - WEBHOOK_RETRY_DELAY=2s

      # Delay máximo entre tentativas (cap do backoff exponencial)
      - WEBHOOK_MAX_RETRY_DELAY=30s

      # Fator de multiplicação para backoff exponencial
      - WEBHOOK_BACKOFF_FACTOR=2.0

      # Número máximo de requisições simultâneas
      - WEBHOOK_MAX_CONCURRENCY=100

      # =================== GLOBAL SKIP MEDIA DOWNLOAD ===================
      # Enable/disable global skip media download for all users
      - GLOBAL_SKIP_MEDIA_DOWNLOAD=false
      # Skip events from WhatsApp groups
      - GLOBAL_SKIP_GROUPS=false
      # Skip events from WhatsApp newsletters
      - GLOBAL_SKIP_NEWSLETTERS=false
      # Skip events from WhatsApp broadcasts and status updates
      - GLOBAL_SKIP_BROADCASTS=false
      # Skip user's own messages (sent messages)
      - GLOBAL_SKIP_OWN_MESSAGES=false
      # Skip call events (offers, accepts, terminates)
      - GLOBAL_SKIP_CALLS=false

      # =================== GLOBAL S3 CONFIGURATION ===================
      # Enable/disable global S3 for media processing
      - GLOBAL_S3_ENABLED=false
      # S3 endpoint (leave empty for AWS S3)
      - GLOBAL_S3_ENDPOINT=
      # S3 region
      - GLOBAL_S3_REGION=us-east-1
      # S3 bucket name for global media
      - GLOBAL_S3_BUCKET=
      # S3 access key
      - GLOBAL_S3_ACCESS_KEY=
      # S3 secret key
      - GLOBAL_S3_SECRET_KEY=
      # Use path-style URLs (true for MinIO/compatible)
      - GLOBAL_S3_PATH_STYLE=true
      # Custom public URL for S3 objects (Adicione o mesmo do S3_ENDPOINT para seguir a URL nos eventos)
      - GLOBAL_S3_PUBLIC_URL=
      # Media delivery method: base64, url, or both
      - GLOBAL_S3_MEDIA_DELIVERY=base64
      # Retention days for media (0 = no expiration)
      - GLOBAL_S3_RETENTION_DAYS=0

      # =================== GLOBAL WEBHOOK CONFIGURATION ===================
      # Enable/disable global webhook for all users
      - GLOBAL_WEBHOOK_ENABLED=false 
      # URL endpoint to receive all global events
      - GLOBAL_WEBHOOK_URL=https://hook.prod.setupautomatizado.com/webhook/global-events
      # Event types to capture (comma-separated or "All")
      - GLOBAL_WEBHOOK_EVENTS=All
      # HTTP request timeout for webhook calls
      - GLOBAL_WEBHOOK_TIMEOUT=30s
      # Number of retry attempts for failed webhook calls
      - GLOBAL_WEBHOOK_RETRY_COUNT=3
      # Initial delay between retries
      - GLOBAL_WEBHOOK_RETRY_DELAY=2s
      # Maximum delay between retries (exponential backoff cap)
      - GLOBAL_WEBHOOK_MAX_RETRY_DELAY=30s
      # Exponential backoff multiplier for retry delays
      - GLOBAL_WEBHOOK_BACKOFF_FACTOR=2.0
      # Maximum concurrent webhook requests (production ready)
      - GLOBAL_WEBHOOK_CONCURRENCY=100

      # =================== GLOBAL RABBITMQ BASIC CONFIGURATION ===================
      # Enable/disable global RabbitMQ for all users
      - GLOBAL_RABBITMQ_ENABLED=false
      # RabbitMQ connection URL (production cluster)
      - GLOBAL_RABBITMQ_URL=amqp://zuckzapgo:SUA_SENHA_DO_RABBITMQ@rabbitmq_zuckzapgo:5672/zuckzapgo
      # Event types to publish (comma-separated or "All")
      - GLOBAL_RABBITMQ_EVENTS=All
      # Exchange name for global events
      - GLOBAL_RABBITMQ_EXCHANGE=zuckzapgo.global.prod
      - GLOBAL_RABBITMQ_EXCHANGE_TYPE=topic
      # Queue name for global events
      # ===== OPÇÃO 1: FILA ÚNICA (ATUAL) =====
      # GLOBAL_RABBITMQ_QUEUE=zuckzapgo.events
      # GLOBAL_RABBITMQ_ROUTING_KEY=events.#
      # ===== OPÇÃO 2: FILAS POR EVENTO (NOVO) =====
      - GLOBAL_RABBITMQ_QUEUE=zuckzapgo_{event_type}_events
      - GLOBAL_RABBITMQ_ROUTING_KEY=events.{event_type}.#
      # - GLOBAL_RABBITMQ_QUEUE=zuckzapgo.events.prod
      - GLOBAL_RABBITMQ_QUEUE_TYPE=classic
      # Routing key pattern for message routing
      - GLOBAL_RABBITMQ_ROUTING_KEY=events.#
      # Make exchange and queue durable (survive broker restart)
      - GLOBAL_RABBITMQ_DURABLE=true
      # Auto-delete exchange/queue when not in use
      - GLOBAL_RABBITMQ_AUTO_DELETE=false
      # Message delivery mode (2=persistent for production)
      - GLOBAL_RABBITMQ_DELIVERY_MODE=2
      # Exclusive queue for production stability
      - GLOBAL_RABBITMQ_EXCLUSIVE=false
      # No wait for queue creation
      - GLOBAL_RABBITMQ_NO_WAIT=false

      # =================== GLOBAL RABBITMQ PERFORMANCE TUNING (PRODUCTION) ===================
      # High-performance connection pool for production load
      - GLOBAL_RABBITMQ_CONNECTION_POOL_SIZE=50
      # High worker count for concurrent message processing
      - GLOBAL_RABBITMQ_WORKER_COUNT=100
      # Large buffer for high-volume message handling
      - GLOBAL_RABBITMQ_QUEUE_BUFFER_SIZE=100000
      # Enable message batching for maximum throughput
      - GLOBAL_RABBITMQ_ENABLE_BATCHING=true
      # Large batch size for production efficiency
      - GLOBAL_RABBITMQ_BATCH_SIZE=1000
      # Fast batch timeout for low latency
      - GLOBAL_RABBITMQ_BATCH_TIMEOUT_MS=100

      # =================== GLOBAL RABBITMQ RELIABILITY & RESILIENCE ===================
      # Circuit breaker: failures before opening circuit (production settings)
      - GLOBAL_RABBITMQ_CIRCUIT_BREAKER_THRESHOLD=20
      # Circuit breaker: longer timeout for production stability
      - GLOBAL_RABBITMQ_CIRCUIT_BREAKER_TIMEOUT_S=60
      # Extended timeout for individual publish operations
      - GLOBAL_RABBITMQ_PUBLISH_TIMEOUT_MS=10000
      # More retry attempts for production reliability
      - GLOBAL_RABBITMQ_MAX_RETRIES=5
      # Shorter delay between retries for faster recovery
      - GLOBAL_RABBITMQ_RETRY_DELAY_MS=500

      # =================== GLOBAL RABBITMQ MONITORING & LOGGING ===================
      # Frequent metrics collection for production monitoring
      - GLOBAL_RABBITMQ_METRICS_INTERVAL_S=5
      # Enable detailed logging for production troubleshooting
      - GLOBAL_RABBITMQ_ENABLE_DETAILED_LOGS=true
      # Enable metrics logging for production monitoring
      - GLOBAL_RABBITMQ_ENABLE_METRICS_LOG=true

      # =================== GLOBAL RABBITMQ QOS & MESSAGE SETTINGS ===================
      # High QoS prefetch for optimal message distribution
      - GLOBAL_RABBITMQ_QOS_PREFETCH_COUNT=200
      # Mandatory delivery for production reliability
      - GLOBAL_RABBITMQ_MANDATORY=false
      # No immediate flag for production stability
      - GLOBAL_RABBITMQ_IMMEDIATE=false

      # =================== GLOBAL RABBITMQ ADVANCED FEATURES (PRODUCTION) ===================
      # Enable compression for bandwidth optimization in production
      - GLOBAL_RABBITMQ_ENABLE_COMPRESSION=true
      # Enable persistence for production data durability
      - GLOBAL_RABBITMQ_ENABLE_PERSISTENCE=true
      # Enable confirmations for production reliability
      - GLOBAL_RABBITMQ_ENABLE_CONFIRMATION=true

    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
      placement:
        constraints: [node.role == manager]
      resources:
        limits:
          cpus: "1" # QUANTIDADE DE CPU
          memory: 512MB # QUANTIDADE DE MEMÓRIA
      labels:
        - traefik.enable=true
        - traefik.http.routers.zuckzapgo_private.rule=Host(`api.seudominio.com`) # DOMINIO DA API
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
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=zuckzapgo # USUÁRIO DO BANCO DE DADOS
      - POSTGRES_PASSWORD=SUA_SENHA_DO_BANCO_DE_DADOS # SENHA DO BANCO DE DADOS
      - POSTGRES_DB=zuckzapgo # NOME DO BANCO DE DADOS
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
          cpus: '0.5' # QUANTIDADE DE CPU
          memory: 512MB # QUANTIDADE DE MEMÓRIA
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-zuckzapgo} -d ${POSTGRES_DB:-zuckzapgo}"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # =================== RABBITMQ (MENSAGERIA) ===================
  rabbitmq_zuckzapgo:
    image: rabbitmq:4-management-alpine
    environment:
      - RABBITMQ_DEFAULT_USER=zuckzapgo # USUÁRIO DO RABBITMQ
      - RABBITMQ_DEFAULT_PASS=SUA_SENHA_DO_RABBITMQ # SENHA DO RABBITMQ
      - RABBITMQ_DEFAULT_VHOST=zuckzapgo # VHOST DO RABBITMQ
    volumes:
      - rabbitmq_data_zuckzapgo:/var/lib/rabbitmq
    networks:
      - network_public
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: '0.5' # QUANTIDADE DE CPU
          memory: 512MB # QUANTIDADE DE MEMÓRIA
      labels:
        - traefik.enable=true
        - traefik.http.routers.rabbitmq_zuckzapgo.rule=Host(`rabbitmq.seudominio.com`) # DOMINIO DO RABBITMQ
        - traefik.http.routers.rabbitmq_zuckzapgo.entrypoints=websecure
        - traefik.http.routers.rabbitmq_zuckzapgo.tls.certresolver=letsencryptresolver
        - traefik.http.routers.rabbitmq_zuckzapgo.service=rabbitmq_zuckzapgo
        - traefik.http.services.rabbitmq_zuckzapgo.loadbalancer.server.port=15672
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

volumes:
  postgres_data_zuckzapgo:
    name: postgres_data_zuckzapgo
    external: true
  rabbitmq_data_zuckzapgo:
    name: rabbitmq_data_zuckzapgo
    external: true

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
## 🧩 Docker Compose (Swarm) — v1.2.4

\`\`\`yaml
version: '3.7'

# =================== ZUCKZAPGO STACK PARA PORTAINER ===================
# Stack completa do ZuckZapGo com todos os serviços necessários
# Configurada para uso em produção com Docker Swarm via Portainer

services:
  zuckzapgo_private:
    image: setupautomatizado/zuckzapgo-private:latest
    networks:
      - network_public
    environment:
      # =================== ADMIN & AUTHENTICATION ===================
      - ZUCKZAPGO_ADMIN_TOKEN=H4Zbhw72PBKdTIgS
      # ZUCKZAPGO_ADDRESS: Define o endereço base para a API ZuckZapGo
      # Esta URL será incluída em TODOS os eventos (webhook + RabbitMQ)
      # tanto globais quanto individuais, permitindo que sistemas externos 
      # saibam exatamente de onde o evento está vindo
      - ZUCKZAPGO_ADDRESS=https://api.zuckzapgo.app
      - ZUCKZAPGO_PORT=8080

      - SERVER_IP=
      - LICENSE_KEY=
      - INSTANCE_ID=

      - LOG_TYPE=console
      - LOG_COLOR=true
      # =================== DATABASE CONFIGURATION ===================
      # Option 1: Individual database variables (current method)
      # - DB_TYPE=postgres
      # - DB_USER=zuckzapgo
      # - DB_PASSWORD=senha-super-segura-aqui
      # - DB_NAME=zuckzapgo
      # - DB_HOST=db
      # - DB_PORT=5432
      # - DB_SSLMODE=disable
      # - DB_SCHEMA=public

      # Option 2: Single database connection string (production method)
      # Uncomment the line below and comment out the individual variables above
      - DATABASE_URL=postgres://zuckzapgo:zuckzapgo@postgres_zuckzapgo:5432/zuckzapgo?sslmode=disable&search_path=public
      # For managed databases: DATABASE_URL=postgres://user:pass@managed-db.example.com:5432/zuckzapgo?sslmode=require
      # For MySQL: DATABASE_URL=mysql://zuckzapgo:zuckzapgo_production_password@zuckzapgo_mysql:3306/zuckzapgo?charset=utf8mb4&parseTime=True&loc=Local

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
      - WA_VERSION=2.3000.1026436087
      #2.3000.1024995419

      # Plataforma do dispositivo
      # Opções: WEB, ANDROID, IOS, WINDOWS, MACOS, IPAD, etc.
      - WA_PLATFORM=WEB

      # Canal de release
      # Opções: RELEASE, BETA, ALPHA, DEBUG
      - WA_RELEASE_CHANNEL=BETA

      # Sub-plataforma para Web
      # Opções: WEB_BROWSER, APP_STORE, WIN_STORE, DARWIN, WIN32, WIN_HYBRID
      - WA_WEB_SUB_PLATFORM=WEB_BROWSER

      # Sistema operacional
      - WA_OS_NAME=Mac OS X
      - WA_OS_VERSION=10.15.7

      # Informações do dispositivo
      - WA_DEVICE_NAME=MacBook Pro
      - WA_MANUFACTURER=Apple
      - WA_DEVICE_BOARD=Mac

      # Configurações de localização
      - WA_LOCALE_LANGUAGE=en
      - WA_LOCALE_COUNTRY=US

      # Códigos de rede móvel
      - WA_MCC=000
      - WA_MNC=000

      # Tipo de conexão
      # Opções: WIFI_UNKNOWN, CELLULAR_UNKNOWN, CELLULAR_LTE, etc.
      - WA_CONNECT_TYPE=WIFI_UNKNOWN

      # Tipo de plataforma para DeviceProps
      # Opções: DESKTOP, CHROME, FIREFOX, SAFARI, EDGE, IPAD, etc.
      - WA_PLATFORM_TYPE=DESKTOP

      # =================== SESSION & TIMEZONE ===================
      - TZ=America/Sao_Paulo
      - SESSION_DEVICE_NAME=ZuckZapGo

      # =================== WEBHOOK INDIVIDUAL POR INSTANICA CONFIGURATIONS ===================
      # "json" or "form" for the default
      - WEBHOOK_FORMAT=json

      # Timeout principal da requisição HTTP
      - WEBHOOK_TIMEOUT=30s

      # Número máximo de tentativas de retry
      - WEBHOOK_MAX_RETRIES=3

      # Delay inicial entre tentativas
      - WEBHOOK_RETRY_DELAY=2s

      # Delay máximo entre tentativas (cap do backoff exponencial)
      - WEBHOOK_MAX_RETRY_DELAY=30s

      # Fator de multiplicação para backoff exponencial
      - WEBHOOK_BACKOFF_FACTOR=2.0

      # Número máximo de requisições simultâneas
      - WEBHOOK_MAX_CONCURRENCY=100

      # =================== GLOBAL SKIP MEDIA DOWNLOAD ===================
      # Enable/disable global skip media download for all users
      - GLOBAL_SKIP_MEDIA_DOWNLOAD=false
      # Skip events from WhatsApp groups
      - GLOBAL_SKIP_GROUPS=false
      # Skip events from WhatsApp newsletters
      - GLOBAL_SKIP_NEWSLETTERS=false
      # Skip events from WhatsApp broadcasts and status updates
      - GLOBAL_SKIP_BROADCASTS=false
      # Skip user's own messages (sent messages)
      - GLOBAL_SKIP_OWN_MESSAGES=false
      # Skip call events (offers, accepts, terminates)
      - GLOBAL_SKIP_CALLS=false
      # Global default message for call rejection (default: 'Sorry, I cannot take calls at the moment.')
      - GLOBAL_CALL_REJECT_MESSAGE=Sorry, I cannot take calls at the moment.
      # Global default call rejection type: 'busy', 'decline', or 'unavailable' (default: 'busy')
      - GLOBAL_CALL_REJECT_TYPE=busy  

      # =================== GLOBAL S3 CONFIGURATION ===================
      # Enable/disable global S3 for media processing
      - GLOBAL_S3_ENABLED=false
      # S3 endpoint (leave empty for AWS S3)
      - GLOBAL_S3_ENDPOINT=https://s3.example.com
      # S3 region
      - GLOBAL_S3_REGION=us-east-1
      # S3 bucket name for global media
      - GLOBAL_S3_BUCKET=
      # S3 access key
      - GLOBAL_S3_ACCESS_KEY=
      # S3 secret key
      - GLOBAL_S3_SECRET_KEY=
      # Use path-style URLs (true for MinIO/compatible)
      - GLOBAL_S3_PATH_STYLE=true
      # Custom public URL for S3 objects (obrigatório)
      - GLOBAL_S3_PUBLIC_URL=https://s3.example.com
      # Media delivery method: base64, url, or both
      - GLOBAL_S3_MEDIA_DELIVERY=url
      # Retention days for media (0 = no expiration)
      - GLOBAL_S3_RETENTION_DAYS=0
      # S3 ACL Configuration
      # Set to true for AWS S3 buckets with "Bucket owner enforced" Object Ownership
      # Set to false for legacy buckets or other S3-compatible providers that support ACLs
      - GLOBAL_S3_DISABLE_ACL=true

      # =================== GLOBAL WEBHOOK CONFIGURATION ===================
      # Enable/disable global webhook for all users
      - GLOBAL_WEBHOOK_ENABLED=false
      # URL endpoint to receive all global events
      - GLOBAL_WEBHOOK_URL=https://hook.prod.setupautomatizado.com/webhook/global-events
      # Event types to capture (comma-separated or "All")
      - GLOBAL_WEBHOOK_EVENTS=All
      # HTTP request timeout for webhook calls
      - GLOBAL_WEBHOOK_TIMEOUT=30s
      # Number of retry attempts for failed webhook calls
      - GLOBAL_WEBHOOK_RETRY_COUNT=3
      # Initial delay between retries
      - GLOBAL_WEBHOOK_RETRY_DELAY=2s
      # Maximum delay between retries (exponential backoff cap)
      - GLOBAL_WEBHOOK_MAX_RETRY_DELAY=30s
      # Exponential backoff multiplier for retry delays
      - GLOBAL_WEBHOOK_BACKOFF_FACTOR=2.0
      # Maximum concurrent webhook requests (production ready)
      - GLOBAL_WEBHOOK_CONCURRENCY=100

      # =================== GLOBAL RABBITMQ BASIC CONFIGURATION ===================
      # Enable/disable global RabbitMQ for all users
      - GLOBAL_RABBITMQ_ENABLED=true
      # RabbitMQ connection URL (production cluster)
      - GLOBAL_RABBITMQ_URL=amqp://zuckzapgo:zuckzapgo@rabbitmq_zuckzapgo:5672/zuckzapgo
      # Event types to publish (comma-separated or "All")
      - GLOBAL_RABBITMQ_EVENTS=All
      # Exchange name for global events
      - GLOBAL_RABBITMQ_EXCHANGE=zuckzapgo.global.prod
      - GLOBAL_RABBITMQ_EXCHANGE_TYPE=topic
      # Queue name for global events
      # ===== OPÇÃO 1: FILA ÚNICA (ATUAL) =====
      # GLOBAL_RABBITMQ_QUEUE=zuckzapgo.events
      # GLOBAL_RABBITMQ_ROUTING_KEY=events.#
      # ===== OPÇÃO 2: FILAS POR EVENTO (NOVO) =====
      # Exemplo alternativo (filas por evento) — comente as duas linhas abaixo se não for usar
      # - GLOBAL_RABBITMQ_QUEUE=zuckzapgo_{event_type}_events
      # - GLOBAL_RABBITMQ_ROUTING_KEY=events.{event_type}.#
      # Exemplo de fila única dedicada
      # - GLOBAL_RABBITMQ_QUEUE=zuckzapgo.events.prod
      - GLOBAL_RABBITMQ_QUEUE_TYPE=classic
      # Routing key pattern for message routing (padrão)
      - GLOBAL_RABBITMQ_ROUTING_KEY=events.#
      # Make exchange and queue durable (survive broker restart)
      - GLOBAL_RABBITMQ_DURABLE=true
      # Auto-delete exchange/queue when not in use
      - GLOBAL_RABBITMQ_AUTO_DELETE=false
      # Message delivery mode (2=persistent for production)
      - GLOBAL_RABBITMQ_DELIVERY_MODE=2
      # Exclusive queue for production stability
      - GLOBAL_RABBITMQ_EXCLUSIVE=false
      # No wait for queue creation
      - GLOBAL_RABBITMQ_NO_WAIT=false

      # =================== GLOBAL RABBITMQ PERFORMANCE TUNING (PRODUCTION) ===================
      # High-performance connection pool for production load
      - GLOBAL_RABBITMQ_CONNECTION_POOL_SIZE=50
      # High worker count for concurrent message processing
      - GLOBAL_RABBITMQ_WORKER_COUNT=100
      # Large buffer for high-volume message handling
      - GLOBAL_RABBITMQ_QUEUE_BUFFER_SIZE=100000
      # Enable message batching for maximum throughput
      - GLOBAL_RABBITMQ_ENABLE_BATCHING=true
      # Large batch size for production efficiency
      - GLOBAL_RABBITMQ_BATCH_SIZE=1000
      # Fast batch timeout for low latency
      - GLOBAL_RABBITMQ_BATCH_TIMEOUT_MS=100

      # =================== GLOBAL RABBITMQ RELIABILITY & RESILIENCE ===================
      # Circuit breaker: failures before opening circuit (production settings)
      - GLOBAL_RABBITMQ_CIRCUIT_BREAKER_THRESHOLD=20
      # Circuit breaker: longer timeout for production stability
      - GLOBAL_RABBITMQ_CIRCUIT_BREAKER_TIMEOUT_S=60
      # Extended timeout for individual publish operations
      - GLOBAL_RABBITMQ_PUBLISH_TIMEOUT_MS=10000
      # More retry attempts for production reliability
      - GLOBAL_RABBITMQ_MAX_RETRIES=5
      # Shorter delay between retries for faster recovery
      - GLOBAL_RABBITMQ_RETRY_DELAY_MS=500

      # =================== GLOBAL RABBITMQ MONITORING & LOGGING ===================
      # Frequent metrics collection for production monitoring
      - GLOBAL_RABBITMQ_METRICS_INTERVAL_S=5
      # Enable detailed logging for production troubleshooting
      - GLOBAL_RABBITMQ_ENABLE_DETAILED_LOGS=true
      # Enable metrics logging for production monitoring
      - GLOBAL_RABBITMQ_ENABLE_METRICS_LOG=true

      # =================== GLOBAL RABBITMQ QOS & MESSAGE SETTINGS ===================
      # High QoS prefetch for optimal message distribution
      - GLOBAL_RABBITMQ_QOS_PREFETCH_COUNT=200
      # Mandatory delivery for production reliability
      - GLOBAL_RABBITMQ_MANDATORY=false
      # No immediate flag for production stability
      - GLOBAL_RABBITMQ_IMMEDIATE=false

      # =================== GLOBAL RABBITMQ ADVANCED FEATURES (PRODUCTION) ===================
      # Enable compression for bandwidth optimization in production
      - GLOBAL_RABBITMQ_ENABLE_COMPRESSION=true
      # Enable persistence for production data durability
      - GLOBAL_RABBITMQ_ENABLE_PERSISTENCE=true
      # Enable confirmations for production reliability
      - GLOBAL_RABBITMQ_ENABLE_CONFIRMATION=true

    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
      placement:
        constraints: [node.role == manager]
      resources:
        limits:
          cpus: "2"      # Increased for RabbitMQ Global performance
          memory: 2GB    # Increased for high-throughput message processing
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
    image: postgres:16-alpine
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
          cpus: '1'
          memory: 1GB
        reservations:
          cpus: '0.5'
          memory: 512MB
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-zuckzapgo} -d ${POSTGRES_DB:-zuckzapgo}"]
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
  rabbitmq_zuckzapgo:
    image: rabbitmq:4-management-alpine
    environment:
      - RABBITMQ_DEFAULT_USER=zuckzapgo
      - RABBITMQ_DEFAULT_PASS=zuckzapgo
      - RABBITMQ_DEFAULT_VHOST=zuckzapgo
    volumes:
      - rabbitmq_data_zuckzapgo:/var/lib/rabbitmq
    networks:
      - network_public
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      resources:
        limits:
          cpus: '1'
          memory: 1GB
        reservations:
          cpus: '0.5'
          memory: 512MB
      labels:
        - traefik.enable=true
        - traefik.http.routers.rabbitmq_zuckzapgo.rule=Host(`rabbitmq.zuckzapgo.app`)
        - traefik.http.routers.rabbitmq_zuckzapgo.entrypoints=websecure
        - traefik.http.routers.rabbitmq_zuckzapgo.tls.certresolver=letsencryptresolver
        - traefik.http.routers.rabbitmq_zuckzapgo.service=rabbitmq_zuckzapgo
        - traefik.http.services.rabbitmq_zuckzapgo.loadbalancer.server.port=15672
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

volumes:
  postgres_data_zuckzapgo:
    name: postgres_data_zuckzapgo
    external: true
  rabbitmq_data_zuckzapgo:
    name: rabbitmq_data_zuckzapgo
    external: true
  # mysql_data_zuckzapgo:  # Descomente para MySQL
  #   name: mysql_data_zuckzapgo
  #   external: true

networks:
  network_public:
    name: network_public
    external: true
\`\`\`
