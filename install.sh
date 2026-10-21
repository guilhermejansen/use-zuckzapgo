#!/bin/bash
# =============================================================================
# ZuckZapGo Private - Instalador Automático (Linux/macOS)
# =============================================================================
# Este script baixa e instala automaticamente a última versão do ZuckZapGo
# Private do GitHub Releases.
#
# Uso:
#   curl -sSL https://install.zuckzapgo.com | bash
#   # ou
#   wget -qO- https://install.zuckzapgo.com | bash
#   # ou local:
#   ./scripts/install.sh
#
# Opções:
#   --version VERSION    Instalar versão específica (ex: v1.18.1)
#   --no-service         Não instalar como serviço do sistema
#   --path PATH          Diretório de instalação customizado
#
# =============================================================================

set -e  # Exit on error

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variáveis globais
REPO_OWNER="guilhermejansen"
REPO_NAME="use-zuckzapgo"
INSTALL_DIR=""
INSTALL_SERVICE=true
VERSION=""

# Funções de log
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Detectar sistema operacional e arquitetura
detect_os_arch() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="arm"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        *)
            log_error "Arquitetura não suportada: $ARCH"
            exit 1
            ;;
    esac

    case "$OS" in
        linux)
            OS="linux"
            ;;
        darwin)
            OS="darwin"
            ;;
        *)
            log_error "Sistema operacional não suportado: $OS"
            log_info "Use Windows? Baixe manualmente: https://github.com/${REPO_OWNER}/${REPO_NAME}/releases"
            exit 1
            ;;
    esac

    PLATFORM="${OS}-${ARCH}"
}

# Obter última versão do GitHub
get_latest_version() {
    log_info "Obtendo última versão do GitHub..."

    LATEST_VERSION=$(curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$LATEST_VERSION" ]; then
        log_error "Não foi possível obter a última versão"
        log_info "Verifique sua conexão com a internet e tente novamente"
        exit 1
    fi

    log_success "Última versão: $LATEST_VERSION"
}

# Download e extração
download_and_extract() {
    local DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${PLATFORM}-${VERSION}.tar.gz"
    local TEMP_DIR=$(mktemp -d)
    local ARCHIVE_NAME="${PLATFORM}-${VERSION}.tar.gz"

    log_info "Baixando de: $DOWNLOAD_URL"

    if ! curl -L -o "${TEMP_DIR}/${ARCHIVE_NAME}" "$DOWNLOAD_URL"; then
        log_error "Falha ao baixar release"
        log_info "Verifique se a versão ${VERSION} existe para ${PLATFORM}"
        log_info "Releases disponíveis: https://github.com/${REPO_OWNER}/${REPO_NAME}/releases"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    log_success "Download concluído"

    log_info "Extraindo arquivos..."
    tar -xzf "${TEMP_DIR}/${ARCHIVE_NAME}" -C "$TEMP_DIR"

    # Encontrar diretório extraído
    EXTRACTED_DIR="${TEMP_DIR}/${PLATFORM}"

    if [ ! -d "$EXTRACTED_DIR" ]; then
        log_error "Diretório extraído não encontrado: $EXTRACTED_DIR"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    log_success "Extração concluída"

    echo "$EXTRACTED_DIR"
}

# Instalação local (sem serviço)
install_local() {
    local SOURCE_DIR=$1
    local TARGET_DIR=${INSTALL_DIR:-"$HOME/zuckzapgo"}

    log_info "Instalando em: $TARGET_DIR"

    # Criar diretório
    mkdir -p "$TARGET_DIR"

    # Copiar arquivos
    cp -r "$SOURCE_DIR"/* "$TARGET_DIR/"

    # Tornar binário executável
    if [ "$OS" = "darwin" ]; then
        chmod +x "$TARGET_DIR/zuckzapgo"
        # Remover quarentena do macOS
        xattr -d com.apple.quarantine "$TARGET_DIR/zuckzapgo" 2>/dev/null || true
    else
        chmod +x "$TARGET_DIR/zuckzapgo"
    fi

    log_success "Instalação local concluída!"
    echo ""
    log_info "Próximos passos:"
    echo "  1. Configure: cd $TARGET_DIR && cp .env.sample .env && nano .env"
    echo "  2. Execute: cd $TARGET_DIR && ./zuckzapgo"
    echo "  3. Acesse: http://localhost:8080"
    echo ""
}

# Instalação como serviço systemd (Linux)
install_systemd() {
    local SOURCE_DIR=$1

    log_info "Instalando como serviço systemd..."

    # Verificar se é root/sudo
    if [ "$EUID" -ne 0 ]; then
        log_error "Instalação como serviço requer privilégios sudo"
        log_info "Execute: sudo ./install.sh"
        exit 1
    fi

    # Copiar binário
    cp "$SOURCE_DIR/zuckzapgo" /usr/local/bin/
    chmod +x /usr/local/bin/zuckzapgo

    # Criar diretório de instalação
    mkdir -p /opt/zuckzapgo
    cp -r "$SOURCE_DIR/static" /opt/zuckzapgo/

    # Copiar .env se não existir
    if [ ! -f /opt/zuckzapgo/.env ]; then
        cp "$SOURCE_DIR/.env.sample" /opt/zuckzapgo/.env
        log_warning "Configure /opt/zuckzapgo/.env antes de iniciar o serviço"
    fi

    # Criar diretórios de dados
    mkdir -p /opt/zuckzapgo/data
    mkdir -p /opt/zuckzapgo/logs
    mkdir -p /opt/zuckzapgo/buffer

    # Copiar arquivo de serviço
    if [ -f "$SOURCE_DIR/zuckzapgo.service" ]; then
        cp "$SOURCE_DIR/zuckzapgo.service" /etc/systemd/system/
        systemctl daemon-reload
        systemctl enable zuckzapgo

        log_success "Serviço systemd instalado!"
        echo ""
        log_info "Próximos passos:"
        echo "  1. Configure: sudo nano /opt/zuckzapgo/.env"
        echo "  2. Inicie: sudo systemctl start zuckzapgo"
        echo "  3. Status: sudo systemctl status zuckzapgo"
        echo "  4. Logs: sudo journalctl -u zuckzapgo -f"
        echo ""
    else
        log_warning "Arquivo zuckzapgo.service não encontrado no pacote"
        log_info "Instalação manual: https://github.com/${REPO_OWNER}/${REPO_NAME}/blob/main/docs/INSTALL.md"
    fi
}

# Instalação como LaunchDaemon (macOS)
install_launchd() {
    local SOURCE_DIR=$1

    log_info "Instalando como LaunchDaemon (macOS)..."

    # Verificar se é root/sudo
    if [ "$EUID" -ne 0 ]; then
        log_error "Instalação como serviço requer privilégios sudo"
        log_info "Execute: sudo ./install.sh"
        exit 1
    fi

    # Copiar binário
    cp "$SOURCE_DIR/zuckzapgo" /usr/local/bin/
    chmod +x /usr/local/bin/zuckzapgo

    # Remover quarentena
    xattr -d com.apple.quarantine /usr/local/bin/zuckzapgo 2>/dev/null || true

    # Criar diretório de instalação
    mkdir -p /opt/zuckzapgo
    cp -r "$SOURCE_DIR/static" /opt/zuckzapgo/

    # Copiar .env se não existir
    if [ ! -f /opt/zuckzapgo/.env ]; then
        cp "$SOURCE_DIR/.env.sample" /opt/zuckzapgo/.env
        log_warning "Configure /opt/zuckzapgo/.env antes de carregar o serviço"
    fi

    # Criar diretórios de dados
    mkdir -p /opt/zuckzapgo/data
    mkdir -p /opt/zuckzapgo/logs
    mkdir -p /opt/zuckzapgo/buffer

    # Copiar plist se existir
    if [ -f "$SOURCE_DIR/com.zuckzapgo.plist" ]; then
        cp "$SOURCE_DIR/com.zuckzapgo.plist" /Library/LaunchDaemons/
        chown root:wheel /Library/LaunchDaemons/com.zuckzapgo.plist
        chmod 644 /Library/LaunchDaemons/com.zuckzapgo.plist

        log_success "LaunchDaemon instalado!"
        echo ""
        log_info "Próximos passos:"
        echo "  1. Configure: sudo nano /opt/zuckzapgo/.env"
        echo "  2. Carregue: sudo launchctl load /Library/LaunchDaemons/com.zuckzapgo.plist"
        echo "  3. Inicie: sudo launchctl start com.zuckzapgo"
        echo "  4. Status: sudo launchctl list | grep zuckzapgo"
        echo "  5. Logs: tail -f /opt/zuckzapgo/logs/stdout.log"
        echo ""
    else
        log_warning "Arquivo com.zuckzapgo.plist não encontrado no pacote"
        log_info "Instalação manual: https://github.com/${REPO_OWNER}/${REPO_NAME}/blob/main/docs/INSTALL.md"
    fi
}

# Parse de argumentos
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                VERSION="$2"
                shift 2
                ;;
            --no-service)
                INSTALL_SERVICE=false
                shift
                ;;
            --path)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -h|--help)
                echo "Uso: $0 [opções]"
                echo ""
                echo "Opções:"
                echo "  --version VERSION    Instalar versão específica (ex: v1.18.1)"
                echo "  --no-service         Não instalar como serviço do sistema"
                echo "  --path PATH          Diretório de instalação customizado"
                echo "  -h, --help           Exibir esta ajuda"
                echo ""
                exit 0
                ;;
            *)
                log_error "Opção desconhecida: $1"
                echo "Use --help para ver opções disponíveis"
                exit 1
                ;;
        esac
    done
}

# Main
main() {
    echo ""
    log_info "=========================================="
    log_info "ZuckZapGo Private - Instalador Automático"
    log_info "=========================================="
    echo ""

    # Parse argumentos
    parse_args "$@"

    # Detectar OS e arquitetura
    detect_os_arch
    log_success "Sistema detectado: $PLATFORM"

    # Obter versão se não especificada
    if [ -z "$VERSION" ]; then
        get_latest_version
        VERSION="$LATEST_VERSION"
    else
        log_info "Versão solicitada: $VERSION"
    fi

    # Download e extração
    EXTRACTED_DIR=$(download_and_extract)

    # Perguntar sobre instalação como serviço (se não especificado via flag)
    if [ "$INSTALL_SERVICE" = true ]; then
        echo ""
        read -p "Instalar como serviço do sistema? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            INSTALL_SERVICE=false
        fi
    fi

    # Instalação
    echo ""
    if [ "$INSTALL_SERVICE" = true ]; then
        if [ "$OS" = "linux" ]; then
            install_systemd "$EXTRACTED_DIR"
        elif [ "$OS" = "darwin" ]; then
            install_launchd "$EXTRACTED_DIR"
        fi
    else
        install_local "$EXTRACTED_DIR"
    fi

    # Limpeza
    rm -rf "$(dirname "$EXTRACTED_DIR")"

    log_success "=========================================="
    log_success "Instalação Concluída!"
    log_success "=========================================="
    echo ""
    log_info "Documentação: https://github.com/${REPO_OWNER}/${REPO_NAME}"
    log_info "Suporte: suporte@setupautomatizado.com.br"
    echo ""
}

# Verificar dependências
check_dependencies() {
    local missing_deps=()

    for cmd in curl tar; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências e tente novamente"

        if [ "$OS" = "linux" ]; then
            log_info "  Ubuntu/Debian: sudo apt install curl tar"
            log_info "  CentOS/RHEL: sudo yum install curl tar"
        elif [ "$OS" = "darwin" ]; then
            log_info "  macOS: brew install curl" # tar já vem no macOS
        fi

        exit 1
    fi
}

# Executar
check_dependencies
main "$@"
