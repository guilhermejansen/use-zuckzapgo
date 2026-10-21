# 📦 Guia de Instalação ZuckZapGo Private

> Exemplos de credenciais usam `SEU_*`: substitua-os por valores próprios antes de iniciar. Nenhum token, senha ou chave deste guia é uma credencial utilizável. Valores opcionais vazios continuam vazios; os exemplos não alteram defaults do servidor.

Guia de instalação do ZuckZapGo a partir dos pacotes do [repositório público](https://github.com/guilhermejansen/use-zuckzapgo/releases). Baixe o arquivo para seu sistema/arquitetura e o `checksums.txt` **da mesma release**. Copie o tag completo mostrado na release (incluindo `v`) para `SEU_TAG_DA_RELEASE` nos exemplos.

| Plataforma | Asset publicado |
|---|---|
| Linux AMD64 | `linux-amd64-<TAG>.tar.gz` |
| Linux ARM64 | `linux-arm64-<TAG>.tar.gz` |
| macOS Intel | `darwin-amd64-<TAG>.tar.gz` |
| macOS Apple Silicon | `darwin-arm64-<TAG>.tar.gz` |
| Windows AMD64 | `windows-amd64-<TAG>.zip` |

O pacote usa uma pasta com o nome da plataforma (`linux-amd64`, por exemplo). Mantenha o executável, `static/` e demais arquivos do mesmo pacote. Os auxiliares [install.sh](../install.sh) e [install.bat](../install.bat) são opcionais; leia-os antes de usar. Para uma primeira configuração com PostgreSQL, consulte o [Quick Start do README](../README.md#quick-start-com-docker-compose).

Este guia trata do gateway existente. Não instala o aplicativo desktop de telefonia, worker de mídia remota ou ponte SIP.

---

## 🐧 Linux (Ubuntu/Debian/CentOS/Fedora/RHEL)

### Instalação Rápida

```bash
VERSION='SEU_TAG_DA_RELEASE'
ASSET="linux-amd64-${VERSION}.tar.gz"
curl --fail --location --output "$ASSET" \
  "https://github.com/guilhermejansen/use-zuckzapgo/releases/download/${VERSION}/${ASSET}"
curl --fail --location --output checksums.txt \
  "https://github.com/guilhermejansen/use-zuckzapgo/releases/download/${VERSION}/checksums.txt"
sha256sum --check --ignore-missing checksums.txt
# Prossiga somente se o checksum do arquivo baixado estiver OK.
tar -xzf "$ASSET"
cd linux-amd64
ls -la
```

Para Linux ARM64, use `linux-arm64` no nome do asset e da pasta. O executável dentro desses pacotes é `zuckzapgo`; a pasta `static/` acompanha o binário.

### Configuração

```bash
# Copiar template de configuração
cp .env.sample .env

# Editar configuração
nano .env  # ou vim .env
```

**Configurações essenciais no `.env`**:
```bash
# Banco de Dados (escolha uma opção):

# SQLite (padrão, zero configuração, recomendado para desenvolvimento)
DATABASE_URL=sqlite://./data/zuckzapgo.db

# PostgreSQL (recomendado para produção)
# DATABASE_URL=postgresql://SEU_DB_USER:SEU_DB_PASSWORD@localhost:5432/zuckzapgo?sslmode=require

# MySQL/MariaDB
# DATABASE_URL=mysql://SEU_DB_USER:SEU_DB_PASSWORD@localhost:3306/zuckzapgo

# Token Admin (para gerenciar usuários via API)
ZUCKZAPGO_ADMIN_TOKEN=SEU_ADMIN_TOKEN

# License Key
LICENSE_KEY=SEU_LICENSE_KEY

# URL Base (para webhooks)
ZUCKZAPGO_ADDRESS=https://api.seudominio.com

# Porta
ZUCKZAPGO_PORT=8080
```

### Executar

```bash
# Tornar executável (se necessário)
chmod +x zuckzapgo

# Testar execução
./zuckzapgo --help

# Executar servidor
./zuckzapgo --address=0.0.0.0 --port=8080

# Acessar interface web
# http://localhost:8080
```

### Instalação como Serviço Systemd (Produção)

Use um usuário de serviço existente, substituindo `SEU_SERVICE_USER` e `SEU_SERVICE_GROUP`. O diretório de trabalho precisa conter o `.env` preenchido e os assets, além de permitir a escrita dos dados locais quando usar SQLite.

```bash
sudo mkdir -p /opt/zuckzapgo/data /opt/zuckzapgo/logs
sudo cp zuckzapgo .env /opt/zuckzapgo/
sudo cp -R static/ /opt/zuckzapgo/
sudo chmod 600 /opt/zuckzapgo/.env
sudo chown -R SEU_SERVICE_USER:SEU_SERVICE_GROUP /opt/zuckzapgo
sudo nano /etc/systemd/system/zuckzapgo.service
```

Salve uma unit com os paths correspondentes à instalação:

```ini
[Unit]
Description=ZuckZapGo WhatsApp API Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=SEU_SERVICE_USER
Group=SEU_SERVICE_GROUP
WorkingDirectory=/opt/zuckzapgo
ExecStart=/opt/zuckzapgo/zuckzapgo --address=127.0.0.1 --port=8080 --logtype=json
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Se aproveitar a unit incluída no pacote, revise `WorkingDirectory`, `ExecStart`, usuário e permissões: copiar o arquivo sem adaptar esses campos não o ajusta à pasta `/opt`.

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now zuckzapgo
sudo systemctl status zuckzapgo
sudo journalctl -u zuckzapgo -f
```

Publique o endpoint por HTTPS com um proxy reverso quando ele precisar ser acessado externamente.

---

## 🪟 Windows (PowerShell)

### Instalação Rápida

```powershell
$releaseTag = 'SEU_TAG_DA_RELEASE'
$asset = "windows-amd64-$releaseTag.zip"
Invoke-WebRequest -Uri "https://github.com/guilhermejansen/use-zuckzapgo/releases/download/$releaseTag/$asset" -OutFile $asset
Invoke-WebRequest -Uri "https://github.com/guilhermejansen/use-zuckzapgo/releases/download/$releaseTag/checksums.txt" -OutFile checksums.txt
Get-FileHash -Path $asset -Algorithm SHA256
Get-Content checksums.txt
# Compare o hash com a linha do mesmo asset antes de extrair.
Expand-Archive -Path $asset -DestinationPath .
Set-Location windows-amd64
Get-ChildItem
```

O binário é `zuckzapgo-private-windows-amd64.exe`. Verifique o checksum antes de executar e preserve `static/` junto do pacote.

### Configuração

```powershell
# Copiar template de configuração
Copy-Item .env.sample .env

# Editar com Notepad
notepad .env
```

**Configurações essenciais no `.env` (Windows)**:
```bash
# Banco de Dados (caminhos Windows):

# SQLite (padrão, recomendado)
DATABASE_URL=sqlite://C:/zuckzapgo/data/db.sqlite

# PostgreSQL
# DATABASE_URL=postgresql://SEU_DB_USER:SEU_DB_PASSWORD@localhost:5432/zuckzapgo

# MySQL
# DATABASE_URL=mysql://SEU_DB_USER:SEU_DB_PASSWORD@localhost:3306/zuckzapgo

# Token Admin
ZUCKZAPGO_ADMIN_TOKEN=SEU_ADMIN_TOKEN

# License Key
LICENSE_KEY=SEU_LICENSE_KEY

# Porta
ZUCKZAPGO_PORT=8080
```

### Executar

```powershell
# Executar servidor
.\zuckzapgo-private-windows-amd64.exe --help
.\zuckzapgo-private-windows-amd64.exe --address=0.0.0.0 --port=8080

# Acessar interface web
# http://localhost:8080
```

### Instalação como Serviço Windows (NSSM)

**NSSM (Non-Sucking Service Manager)** permite rodar ZuckZapGo como serviço Windows.

```powershell
# 1. Baixar NSSM
# https://nssm.cc/download
# Extrair nssm.exe para C:\Windows\System32\

# 2. Mover ZuckZapGo para C:\zuckzapgo
New-Item -Path "C:\zuckzapgo" -ItemType Directory -Force
Copy-Item -Path ".\zuckzapgo-private-windows-amd64.exe" -Destination "C:\zuckzapgo\"
Copy-Item -Path ".\static" -Destination "C:\zuckzapgo\" -Recurse
Copy-Item -Path ".\.env" -Destination "C:\zuckzapgo\"
New-Item -Path "C:\zuckzapgo\logs" -ItemType Directory -Force

# 3. Instalar serviço com NSSM
nssm install ZuckZapGo "C:\zuckzapgo\zuckzapgo-private-windows-amd64.exe"

# 4. Configurar serviço
nssm set ZuckZapGo AppDirectory "C:\zuckzapgo"
nssm set ZuckZapGo AppParameters "--address=0.0.0.0 --port=8080 --logtype=json"
nssm set ZuckZapGo DisplayName "ZuckZapGo WhatsApp API"
nssm set ZuckZapGo Description "WhatsApp Business API Gateway"
nssm set ZuckZapGo Start SERVICE_AUTO_START
nssm set ZuckZapGo ObjectName LocalSystem

# 5. Configurar logs
nssm set ZuckZapGo AppStdout "C:\zuckzapgo\logs\stdout.log"
nssm set ZuckZapGo AppStderr "C:\zuckzapgo\logs\stderr.log"

# 6. Iniciar serviço
nssm start ZuckZapGo

# 7. Verificar status
nssm status ZuckZapGo
sc query ZuckZapGo

# Comandos úteis:
# Parar: nssm stop ZuckZapGo
# Reiniciar: nssm restart ZuckZapGo
# Remover: nssm remove ZuckZapGo confirm
# Editar: nssm edit ZuckZapGo
```

### Alternativa: Task Scheduler (sem NSSM)

```powershell
# Criar tarefa agendada que inicia com o Windows
$action = New-ScheduledTaskAction -Execute "C:\zuckzapgo\zuckzapgo-private-windows-amd64.exe" -Argument "--address=0.0.0.0 --port=8080" -WorkingDirectory "C:\zuckzapgo"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "ZuckZapGo" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "ZuckZapGo WhatsApp API Gateway"

# Iniciar manualmente
Start-ScheduledTask -TaskName "ZuckZapGo"

# Ver status
Get-ScheduledTask -TaskName "ZuckZapGo"
```

---

## 🍎 macOS (Intel e Apple Silicon)

### Download

Escolha `darwin-arm64` para Apple Silicon ou `darwin-amd64` para Intel:

```bash
VERSION='SEU_TAG_DA_RELEASE'
PLATFORM='darwin-arm64'
ASSET="${PLATFORM}-${VERSION}.tar.gz"
curl --fail --location --output "$ASSET" \
  "https://github.com/guilhermejansen/use-zuckzapgo/releases/download/${VERSION}/${ASSET}"
curl --fail --location --output checksums.txt \
  "https://github.com/guilhermejansen/use-zuckzapgo/releases/download/${VERSION}/checksums.txt"
shasum -a 256 "$ASSET"
# Compare com a linha do mesmo asset em checksums.txt antes de extrair.
tar -xzf "$ASSET"
cd "$PLATFORM"
```

### Remover Quarentena (Gatekeeper)

```bash
# Permitir execução de aplicativo de desenvolvedor não identificado
xattr -d com.apple.quarantine zuckzapgo
chmod +x zuckzapgo

# Verificar
./zuckzapgo --version
```

### Configuração

```bash
# Copiar template
cp .env.sample .env

# Editar
vim .env  # ou nano .env, ou code .env
```

**Configurações essenciais no `.env` (macOS)**:
```bash
# Banco de Dados (caminhos macOS):

# SQLite (padrão)
DATABASE_URL=sqlite://./data/zuckzapgo.db
# ou em ~/Library/Application Support/
# DATABASE_URL="sqlite:///Users/SEU_USUARIO/Library/Application Support/zuckzapgo/db.sqlite"

# PostgreSQL (via Homebrew: brew install postgresql)
# DATABASE_URL=postgresql://SEU_DB_USER:SEU_DB_PASSWORD@localhost:5432/zuckzapgo

# MySQL (via Homebrew: brew install mysql)
# DATABASE_URL=mysql://SEU_DB_USER:SEU_DB_PASSWORD@localhost:3306/zuckzapgo

# Token Admin
ZUCKZAPGO_ADMIN_TOKEN=SEU_ADMIN_TOKEN

# License Key
LICENSE_KEY=SEU_LICENSE_KEY

# Porta
ZUCKZAPGO_PORT=8080
```

### Executar

```bash
./zuckzapgo --address=0.0.0.0 --port=8080

# Acessar: http://localhost:8080
```

### Instalação como LaunchDaemon (Produção)

```bash
# 1. Copiar binário para /usr/local/bin
sudo cp zuckzapgo /usr/local/bin/
sudo chmod +x /usr/local/bin/zuckzapgo

# 2. Criar diretório de instalação
sudo mkdir -p /opt/zuckzapgo
sudo cp -r static/ /opt/zuckzapgo/
sudo cp .env /opt/zuckzapgo/

# 3. Criar diretórios necessários
sudo mkdir -p /opt/zuckzapgo/data
sudo mkdir -p /opt/zuckzapgo/logs
sudo mkdir -p /opt/zuckzapgo/buffer

# 4. Criar arquivo plist (copiar do pacote)
sudo cp com.zuckzapgo.plist /Library/LaunchDaemons/

# Ou criar manualmente:
sudo tee /Library/LaunchDaemons/com.zuckzapgo.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zuckzapgo</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/zuckzapgo</string>
        <string>--address=0.0.0.0</string>
        <string>--port=8080</string>
        <string>--logtype=json</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/opt/zuckzapgo</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/opt/zuckzapgo/logs/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/opt/zuckzapgo/logs/stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

# 5. Ajustar permissões
sudo chown root:wheel /Library/LaunchDaemons/com.zuckzapgo.plist
sudo chmod 644 /Library/LaunchDaemons/com.zuckzapgo.plist

# 6. Carregar e iniciar serviço
sudo launchctl load /Library/LaunchDaemons/com.zuckzapgo.plist
sudo launchctl start com.zuckzapgo

# 7. Verificar status
sudo launchctl list | grep zuckzapgo

# Comandos úteis:
# Parar: sudo launchctl stop com.zuckzapgo
# Descarregar: sudo launchctl unload /Library/LaunchDaemons/com.zuckzapgo.plist
# Ver logs: tail -f /opt/zuckzapgo/logs/stdout.log
```

---

## 🐳 Docker

### Container com configuração explícita

Preencha o `.env` com `LICENSE_KEY` e `ZUCKZAPGO_ADMIN_TOKEN` próprios antes de executar. O exemplo fixa o tag escolhido e usa SQLite em volume para desenvolvimento; para PostgreSQL persistente com healthcheck, use o [Quick Start](../README.md#quick-start-com-docker-compose).

```bash
DOCKER_TAG='SEU_TAG_DA_RELEASE'
docker pull setupautomatizado/zuckzapgo-private:"$DOCKER_TAG"
docker run -d \
  --name zuckzapgo \
  --publish 127.0.0.1:8080:8080 \
  --env-file .env \
  --env DATABASE_URL=sqlite:///app/data/users.db \
  --volume zuckzapgo-data:/app/data \
  setupautomatizado/zuckzapgo-private:"$DOCKER_TAG"
```

O `--env DATABASE_URL` acima escolhe SQLite explicitamente. Para seu banco PostgreSQL/MySQL, remova esse override e configure uma URI alcançável **de dentro do container** no `.env`. `localhost` no container não aponta para o banco do host. Volume de dados precisa ser preservado; apagar o volume elimina o SQLite e as sessões nele armazenadas.

### Docker Compose

Use o exemplo completo do [README](../README.md#quick-start-com-docker-compose) ou baixe a configuração pública e adapte todas as credenciais, banco, endereço externo e portas antes de subir:

```bash
curl --fail --location --output docker-compose.yml \
  https://raw.githubusercontent.com/guilhermejansen/use-zuckzapgo/main/docker-compose.yml
# Edite os valores e confira a persistência antes de iniciar.
docker compose up -d
docker compose logs -f
```

Configure HTTPS para acesso externo. Atualizações exigem backup, leitura das notas da release e preservação do banco, chaves e S3; voltar a imagem não garante rollback do schema.

---

## ❓ Troubleshooting

### "Permission Denied" ao executar binário

**Linux/macOS**:
```bash
chmod +x zuckzapgo
```

**macOS (quarentena)**:
```bash
xattr -d com.apple.quarantine zuckzapgo
```

### "Failed to connect to database"

```bash
# Verificar DATABASE_URL no .env
sed -n 's/^[[:space:]]*DATABASE_URL=.*/DATABASE_URL=<definida>/p' .env

# SQLite (não precisa de servidor, cria automaticamente):
DATABASE_URL=sqlite://./data/db.sqlite

# PostgreSQL/MySQL precisam estar rodando
# Testar conexão:
psql $DATABASE_URL  # PostgreSQL
mysql --uri=$DATABASE_URL  # MySQL

# Verificar se porta está acessível:
telnet localhost 5432  # PostgreSQL
telnet localhost 3306  # MySQL
```

### Porta 8080 já em uso

```bash
# Verificar o que está usando a porta
# Linux:
sudo netstat -tlnp | grep 8080
sudo lsof -i :8080

# macOS:
lsof -i :8080

# Windows:
netstat -ano | findstr :8080

# Mudar porta via flag:
./zuckzapgo --port=8090

# Ou via ENV:
ZUCKZAPGO_PORT=8090 ./zuckzapgo
```

### Static files não encontrados

```bash
# Verificar que static/ está no diretório correto
ls -la static/

# Se executar de outro diretório, usar caminho absoluto ou
# cd para o diretório do binário:
cd /caminho/para/zuckzapgo-linux-amd64
./zuckzapgo

# Ou setar working directory no systemd/launchd
```

### "Database connection pool exhausted"

```bash
# Aumentar pool de conexões (PostgreSQL/MySQL)
# Editar .env ou ENV vars:
# DB_MAX_OPEN_CONNS=100
# DB_MAX_IDLE_CONNS=10

# Ou usar SQLite para instâncias pequenas
DATABASE_URL=sqlite://./data/db.sqlite
```

### Logs não aparecem

```bash
# Verificar nível de log
# .env ou flags:
ZUCKZAPGO_LOG_LEVEL=debug  # ou info, warn, error
./zuckzapgo --loglevel=debug

# Verificar tipo de log (console vs json)
LOG_TYPE=console
LOG_COLOR=true

# Ver logs do serviço:
# Linux: sudo journalctl -u zuckzapgo -f
# macOS: tail -f /opt/zuckzapgo/logs/stdout.log
# Windows: type C:\zuckzapgo\logs\stdout.log
```

### WhatsApp não conecta (QR code não aparece)

```bash
# Verificar logs do WhatsApp
ZUCKZAPGO_DEBUG=DEBUG ./zuckzapgo

# Verificar proxy (se atrás de firewall)
# .env:
WA_PROXY=http://proxy.empresa.com:8080

# Leia o estado pela API autenticada: GET /session/status.
# Confira licença, banco, rede, pareamento e eventual exigência de passkey.
# Não apague linhas do banco para diagnosticar o pareamento.
```

---

## 📚 Recursos Adicionais

- **Documentação Completa**: [README.md](../README.md)
- **Configuração Detalhada**: [CONFIGURATION.md](./CONFIGURATION.md)
- **API Swagger**: `http://localhost:8080/api/`
- **Changelog**: [CHANGELOG.md](../CHANGELOG.md)
- **Suporte**: suporte@setupautomatizado.com.br
- **GitHub Issues**: https://github.com/guilhermejansen/use-zuckzapgo/issues

---

## 🆘 Suporte

Se encontrar problemas:

1. Consulte a seção **Troubleshooting** acima
2. Veja logs detalhados com `--loglevel=debug`
3. Verifique [Issues no GitHub](https://github.com/guilhermejansen/use-zuckzapgo/issues)
4. Entre em contato: suporte@setupautomatizado.com.br

---

**Versão do Guia**: 1.0
**Última Atualização**: 2026-10-20
