@echo off
REM ===========================================================================
REM ZuckZapGo Private - Instalador Automático (Windows)
REM ===========================================================================
REM Este script auxilia na instalação do ZuckZapGo Private no Windows
REM
REM Uso:
REM   install.bat
REM
REM Nota: Download manual ainda é necessário
REM ===========================================================================

setlocal enabledelayedexpansion

echo.
echo ==========================================
echo ZuckZapGo Private - Instalador Windows
echo ==========================================
echo.

REM Detectar arquitetura
set ARCH=unknown
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set ARCH=amd64
if "%PROCESSOR_ARCHITECTURE%"=="x86" set ARCH=386
if "%PROCESSOR_ARCHITEW6432%"=="AMD64" set ARCH=amd64

if "%ARCH%"=="unknown" (
    echo [ERRO] Arquitetura não suportada: %PROCESSOR_ARCHITECTURE%
    goto :error
)

echo [OK] Arquitetura detectada: windows-%ARCH%
echo.

REM Verificar se executando como Administrador (para instalação como serviço)
net session >nul 2>&1
if %errorLevel% == 0 (
    set ISADMIN=1
    echo [OK] Executando como Administrador
) else (
    set ISADMIN=0
    echo [AVISO] Não está executando como Administrador
    echo         Instalação como serviço Windows requer privilégios de administrador
)
echo.

REM Variáveis
set REPO_OWNER=guilhermejansen
set REPO_NAME=use-zuckzapgo
set INSTALL_DIR=C:\zuckzapgo
set GITHUB_URL=https://github.com/%REPO_OWNER%/%REPO_NAME%/releases/latest

echo ==========================================
echo Opções de Instalação
echo ==========================================
echo.
echo 1. Instalação Manual (Recomendado)
echo    - Baixe manualmente do GitHub Releases
echo    - Descompacte onde desejar
echo    - Execute zuckzapgo-private-windows-amd64.exe
echo.
echo 2. Instalação Automática (Experimental)
echo    - Download automático da última versão
echo    - Instalação em C:\zuckzapgo
echo    - Opcional: Configuração como serviço Windows
echo.

set /p CHOICE="Escolha uma opção (1 ou 2): "

if "%CHOICE%"=="1" goto :manual
if "%CHOICE%"=="2" goto :auto
echo [ERRO] Opção inválida
goto :error

:manual
echo.
echo ==========================================
echo Instalação Manual
echo ==========================================
echo.
echo Siga os passos abaixo:
echo.
echo 1. Abra: %GITHUB_URL%
echo.
echo 2. Baixe: zuckzapgo-private-windows-amd64-vX.X.X.zip
echo.
echo 3. Descompacte em um diretório (ex: C:\zuckzapgo)
echo.
echo 4. Configure:
echo    - Copie .env.sample para .env
echo    - Edite .env com suas configurações
echo.
echo 5. Execute:
echo    - zuckzapgo-private-windows-amd64.exe
echo.
echo 6. Acesse: http://localhost:8080
echo.
echo.
echo Pressione qualquer tecla para abrir o navegador no GitHub Releases...
pause >nul
start "" "%GITHUB_URL%"
goto :end

:auto
echo.
echo ==========================================
echo Instalação Automática
echo ==========================================
echo.

REM Verificar dependências
where curl >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] curl não encontrado
    echo.
    echo Instale curl para continuar:
    echo - Windows 10/11: curl já vem instalado
    echo - Versões antigas: baixe de https://curl.se/windows/
    echo.
    echo Ou use a opção 1 (Instalação Manual^)
    goto :error
)

where tar >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] tar não encontrado
    echo.
    echo tar vem com Windows 10 build 17063+
    echo Atualize seu Windows ou use a opção 1 (Instalação Manual^)
    goto :error
)

echo [OK] Dependências verificadas
echo.

REM Obter última versão
echo [INFO] Obtendo última versão...
for /f "tokens=2 delims=:," %%a in ('curl -s https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest ^| findstr "tag_name"') do (
    set VERSION=%%a
    set VERSION=!VERSION:"=!
    set VERSION=!VERSION: =!
)

if "!VERSION!"=="" (
    echo [ERRO] Não foi possível obter a versão
    echo Verifique sua conexão com a internet
    goto :error
)

echo [OK] Versão: !VERSION!
echo.

REM Download
set DOWNLOAD_URL=https://github.com/%REPO_OWNER%/%REPO_NAME%/releases/download/!VERSION!/windows-amd64-!VERSION!.zip
set TEMP_FILE=%TEMP%\zuckzapgo-!VERSION!.zip

echo [INFO] Baixando de: !DOWNLOAD_URL!
echo.

curl -L -o "!TEMP_FILE!" "!DOWNLOAD_URL!"
if %errorLevel% neq 0 (
    echo [ERRO] Falha no download
    goto :error
)

echo.
echo [OK] Download concluído
echo.

REM Criar diretório de instalação
echo [INFO] Criando diretório: %INSTALL_DIR%
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Extrair
echo [INFO] Extraindo arquivos...
tar -xf "!TEMP_FILE!" -C "%INSTALL_DIR%" --strip-components=1
if %errorLevel% neq 0 (
    echo [ERRO] Falha na extração
    goto :error
)

echo [OK] Extração concluída
echo.

REM Copiar .env
if not exist "%INSTALL_DIR%\.env" (
    echo [INFO] Copiando .env.sample para .env
    copy "%INSTALL_DIR%\.env.sample" "%INSTALL_DIR%\.env" >nul
    echo [AVISO] Configure %INSTALL_DIR%\.env antes de executar
    echo.
)

REM Criar diretórios de dados
if not exist "%INSTALL_DIR%\data" mkdir "%INSTALL_DIR%\data"
if not exist "%INSTALL_DIR%\logs" mkdir "%INSTALL_DIR%\logs"
if not exist "%INSTALL_DIR%\buffer" mkdir "%INSTALL_DIR%\buffer"

REM Perguntar sobre instalação como serviço
if %ISADMIN%==1 (
    echo.
    set /p SERVICE="Instalar como serviço Windows? (s/n): "
    if /i "!SERVICE!"=="s" goto :install_service
)

REM Instalação local concluída
echo.
echo ==========================================
echo Instalação Local Concluída!
echo ==========================================
echo.
echo Diretório: %INSTALL_DIR%
echo.
echo Próximos passos:
echo.
echo 1. Configure:
echo    notepad %INSTALL_DIR%\.env
echo.
echo 2. Execute:
echo    cd %INSTALL_DIR%
echo    zuckzapgo-private-windows-amd64.exe
echo.
echo 3. Acesse:
echo    http://localhost:8080
echo.

REM Abrir pasta de instalação
set /p OPEN="Abrir pasta de instalação? (s/n): "
if /i "%OPEN%"=="s" (
    explorer "%INSTALL_DIR%"
)

goto :cleanup

:install_service
echo.
echo ==========================================
echo Instalando como Serviço Windows (NSSM)
echo ==========================================
echo.

REM Verificar se NSSM está instalado
where nssm >nul 2>&1
if %errorLevel% neq 0 (
    echo [AVISO] NSSM não encontrado
    echo.
    echo Para instalar como serviço Windows, você precisa do NSSM:
    echo.
    echo 1. Baixe: https://nssm.cc/download
    echo 2. Extraia nssm.exe para C:\Windows\System32\
    echo 3. Execute novamente este instalador
    echo.
    echo Ou siga o guia manual em:
    echo https://github.com/%REPO_OWNER%/%REPO_NAME%/blob/main/docs/INSTALL.md
    echo.
    pause
    goto :cleanup
)

echo [OK] NSSM encontrado
echo.

REM Parar serviço se existir
nssm stop ZuckZapGo >nul 2>&1
nssm remove ZuckZapGo confirm >nul 2>&1

REM Instalar serviço
echo [INFO] Instalando serviço...
nssm install ZuckZapGo "%INSTALL_DIR%\zuckzapgo-private-windows-amd64.exe"
nssm set ZuckZapGo AppDirectory "%INSTALL_DIR%"
nssm set ZuckZapGo AppParameters "--address=0.0.0.0 --port=8080 --logtype=json"
nssm set ZuckZapGo DisplayName "ZuckZapGo WhatsApp API"
nssm set ZuckZapGo Description "WhatsApp Business API Gateway"
nssm set ZuckZapGo Start SERVICE_AUTO_START
nssm set ZuckZapGo ObjectName LocalSystem
nssm set ZuckZapGo AppStdout "%INSTALL_DIR%\logs\stdout.log"
nssm set ZuckZapGo AppStderr "%INSTALL_DIR%\logs\stderr.log"

echo [OK] Serviço instalado
echo.

echo ==========================================
echo Instalação como Serviço Concluída!
echo ==========================================
echo.
echo Próximos passos:
echo.
echo 1. Configure:
echo    notepad %INSTALL_DIR%\.env
echo.
echo 2. Inicie o serviço:
echo    nssm start ZuckZapGo
echo.
echo 3. Verifique status:
echo    nssm status ZuckZapGo
echo    sc query ZuckZapGo
echo.
echo 4. Acesse:
echo    http://localhost:8080
echo.
echo Comandos úteis:
echo - Parar: nssm stop ZuckZapGo
echo - Reiniciar: nssm restart ZuckZapGo
echo - Remover: nssm remove ZuckZapGo confirm
echo.

goto :cleanup

:cleanup
REM Limpar arquivo temporário
if exist "!TEMP_FILE!" del "!TEMP_FILE!"
goto :end

:error
echo.
echo [ERRO] Instalação falhou
echo.
echo Para instalação manual, visite:
echo %GITHUB_URL%
echo.
echo Documentação completa:
echo https://github.com/%REPO_OWNER%/%REPO_NAME%/blob/main/docs/INSTALL.md
echo.
pause
exit /b 1

:end
echo.
echo Documentação: https://github.com/%REPO_OWNER%/%REPO_NAME%
echo Suporte: suporte@setupautomatizado.com.br
echo.
pause
exit /b 0
