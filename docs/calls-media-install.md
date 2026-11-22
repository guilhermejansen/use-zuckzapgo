# Chamadas com serviço de mídia: da instalação à primeira ligação

Este guia leva você do zero até a primeira ligação no **modo com serviço de mídia**: pessoas
atendem pelo aplicativo do atendente, e o áudio vai direto do aplicativo para um serviço de
mídia seu, sem passar pela API.

> **Beta.** Chamadas são Beta nesta versão, em todas as partes deste guia: serviço de mídia,
> aplicativo do atendente e SDK, no macOS e no Windows. O aplicativo para Windows, além disso,
> ainda não foi testado numa máquina Windows. Se algo não funcionar como este guia descreve,
> avise o suporte. Se você ainda não escolheu o modo, leia antes
[Chamadas: modos de uso, licença e implantação](calls-overview.md). Para controlar chamadas pelo
seu próprio software, você não precisa de nada deste guia: use o modo na API.

São quatro partes, e cada uma depende da anterior:

1. **Preparar a API:** gerar as chaves e a configuração, criar o banco de autoridade e preparar
   os bancos.
2. **Instalar o serviço de mídia** de uma sessão e registrá-lo na API.
3. **Instalar o aplicativo do atendente** e vincular o aparelho.
4. **Fazer a primeira ligação.** O SDK, para quem quer construir o próprio aplicativo, vem no
   fim.

## O que você vai baixar

| O que é | Onde |
|---|---|
| API | imagem `setupautomatizado/zuckzapgo-private:v2.5.0`, que também traz a ferramenta de provisão (`/app/callsprovision`) |
| Serviço de mídia | imagem `setupautomatizado/zuckzapgo-callworker:v2.5.0`, para `amd64` e `arm64` |
| Aplicativo do atendente, macOS 14 ou mais novo | `calls-desktop-2.5.0-macos-universal.dmg` (Apple Silicon e Intel) |
| Aplicativo do atendente, Windows 10/11 64 bits | `calls-desktop-2.5.0-windows-x64-setup.exe` |
| SDK de chamadas (`@conversalabs/calls-sdk`) | `calls-sdk-2.5.0.tgz` |

As duas imagens estão no Docker Hub, com as mesmas tags (`v2.5.0`, `2.5.0`, `2.5`, `2` e
`latest`) e assinadas com cosign. Os três arquivos ficam na
[release v2.5.0 do repositório de apoio](https://github.com/guilhermejansen/use-zuckzapgo/releases/tag/v2.5.0),
junto com os pacotes da API e o `checksums.txt` de todos eles.

## O que você precisa antes de começar

- **Licença com Chamadas.** Chamadas exigem licença Enterprise em novas assinaturas; veja a
  regra completa em [calls-overview.md](calls-overview.md#licença-de-chamadas).
- **A API na versão 2.5.0, atrás de HTTPS público**, rodando em Docker. O endereço HTTPS que
  os atendentes usam para chegar à API é o **issuer** deste guia, por exemplo
  `https://api.seudominio.com`. O TLS termina no seu proxy ou balanceador.
- **Um banco de autoridade separado**, PostgreSQL ou MySQL, distinto do banco da aplicação.
  Usar o mesmo endereço do banco da aplicação é recusado. Para produção, use PostgreSQL também
  no banco da aplicação.
- **Uma máquina Linux para o serviço de mídia**, com Docker, alcançável pelos atendentes:
  - um nome DNS próprio, por exemplo `media.seudominio.com`, com um certificado TLS público
    válido para esse nome (Let's Encrypt ou outro). Certificado de autoridade privada é
    recusado pelo aplicativo e pelos navegadores;
  - a porta TCP `9443` aberta para entrada, para os atendentes;
  - a faixa UDP `40000-40100` aberta para entrada e saída;
  - saída TCP até a porta de controle da API, a `9444`.
- **Um computador por atendente**, com macOS 14 ou mais novo ou Windows 10/11 de 64 bits,
  microfone e fone.
- **Uma sessão do WhatsApp já pareada** na API. Cada sessão que vai atender pelo aplicativo
  tem **um serviço de mídia só dela**.

Os comandos de preparação das máquinas (`install`, `chown`, `docker`) rodam como root, ou com
`sudo`. Nos exemplos, troque pelos seus valores:

| Exemplo | O que é |
|---|---|
| `https://api.seudominio.com` | o issuer: endereço HTTPS público da API |
| `calls-control.seudominio.com` | o nome pelo qual o serviço de mídia chega à porta de controle da API; na máquina do serviço de mídia, ele resolve para `IP_PRIVADO_DA_API` |
| `IP_PRIVADO_DA_API` | o IP do host da API na rede privada entre as duas máquinas, onde a porta de controle fica publicada |
| `https://media.seudominio.com:9443` | o endereço HTTPS público do serviço de mídia |
| `ID_DA_SESSAO` | o `id` da sessão em `GET /admin/users` (não é o token) |
| `REDE_DA_API` | a rede Docker da API, a mesma que alcança os dois bancos |

## Parte 1 — Preparar a API

### 1.1 Gerar a configuração e as chaves

A API conversa com o serviço de mídia por uma **porta de controle** própria, em TLS, com uma
autoridade certificadora só sua. A ferramenta de provisão gera esse material, os segredos da API
e o arquivo de configuração completo, num diretório vazio.

A API roda com o usuário `1001` dentro do contêiner. Crie o diretório com esse dono:

```bash
install -d -m 0700 -o 1001 -g 1001 /srv/zuckzapgo-calls
```

Gere os arquivos:

```bash
docker run --rm -v /srv/zuckzapgo-calls:/private/calls \
  setupautomatizado/zuckzapgo-private:v2.5.0 \
  /app/callsprovision -init-files /private/calls \
    -control-host calls-control.seudominio.com \
    -issuer https://api.seudominio.com \
    -worker-origin https://media.seudominio.com:9443
```

| Opção | O que pôr |
|---|---|
| `-init-files` | o diretório de saída, **dentro do contêiner**. Use sempre `/private/calls`: a API e a provisão montam o diretório nesse mesmo caminho, porque é ele que fica escrito na configuração |
| `-control-host` | o nome ou o IP pelo qual o serviço de mídia alcança a porta de controle da API. O certificado da porta sai em nome dele (ou para o IP, se você passar um IP) |
| `-issuer` | o endereço HTTPS público da API, exatamente como o atendente vai digitá-lo no aplicativo: em minúsculas, sem barra no fim, sem caminho e sem `:443` |
| `-worker-origin` | o endereço HTTPS público do serviço de mídia |
| `-worker-id` | opcional: o identificador do serviço de mídia. Padrão: `worker-1` |
| `-authority-driver` | opcional: `pgx` (PostgreSQL, o padrão) ou `mysql` |
| `-control-listen` | opcional: onde a porta de controle escuta. Padrão: `0.0.0.0:9444` |

O `-control-host` tem de resolver, **na máquina do serviço de mídia**, para o
`IP_PRIVADO_DA_API` do passo 1.5, porque a porta de controle só escuta nesse endereço. Um nome que
resolve para o IP público da API faz o registro falhar com `enrollment_unavailable`. Se não houver
DNS interno, use o próprio IP privado em `-control-host` e, no passo 2.1, em `control_target`,
`enrollment_url` e `server_name`: o certificado sai para o IP, e funciona igual.

A saída lista os arquivos e os identificadores gerados; nenhum segredo aparece nela.

**Use sempre um diretório do host preparado com o `install` acima**, montado com `-v` como no
comando. A ferramenta só aceita um diretório do usuário `1001` em que nem o grupo nem outros possam
escrever. Um volume nomeado do Docker (`-v nome-do-volume:/private/calls`) nasce do root e é
recusado, assim como um diretório do host criado sem `-o 1001 -g 1001`:
`callsprovision: init-files: /private/calls is owned by uid 0, not by uid 1001 that runs this command; …`.
Se o diretório não estiver vazio, ela recusa e não toca em nada:
`callsprovision: init-files: /private/calls is not empty; refusing to overwrite existing calls material (if it only holds files of an interrupted -init-files run that were never used, delete them and run again)`.

O diretório fica assim:

| Arquivo | Para quê | Permissão |
|---|---|---|
| `calls-api.json` | a configuração de chamadas da API | `0600` |
| `control-ca.pem` | o certificado da autoridade da porta de controle. Uma cópia vai para o serviço de mídia | `0600` |
| `control-ca-key.pem` | a chave dessa autoridade. **Nunca sai do host da API** | `0600` |
| `control-server.pem`, `control-server-key.pem` | o certificado e a chave da porta de controle | `0600` |
| `signing-seed` | a semente de assinatura da API (32 bytes) | `0600` |
| `cursor-key` | a chave de cursor da API (32 bytes) | `0600` |
| `api-verification-key` | a chave pública da API (32 bytes). Uma cópia vai para o serviço de mídia | `0644` |

Inclua esse diretório no seu backup e mantenha o acesso restrito. A autoridade e o certificado
da porta de controle valem 10 anos; não há renovação automática nem comando de renovação nesta
versão.

### 1.2 Escrever os endereços dos dois bancos

O gerador não escreve endereços de banco: você cria dois arquivos, de uma linha cada, com
permissão `0600` e dono `1001`.

Crie um banco vazio para a autoridade, separado do banco da aplicação, com um usuário que possa
criar tabelas nele. O endereço vai em `authority-dsn`, que o `calls-api.json` já espera:

```bash
cd /srv/zuckzapgo-calls
install -m 0600 -o 1001 -g 1001 /dev/null authority-dsn
printf '%s\n' 'postgres://calls:SUA_SENHA@db:5432/calls_authority?sslmode=require' > authority-dsn
```

O endereço do **banco da aplicação**, o mesmo `DATABASE_URL` da API, vai em `calls-dsn`. Só a
provisão usa este arquivo:

```bash
install -m 0600 -o 1001 -g 1001 /dev/null calls-dsn
printf '%s\n' 'postgres://app:SUA_SENHA@db:5432/app?sslmode=require' > calls-dsn
```

### 1.3 Conferir a configuração gerada

O `calls-api.json` sai completo. Normalmente você não precisa mudar nada; confira:

| Campo | O que é |
|---|---|
| `issuer` | o valor de `-issuer` |
| `origins` | quem pode falar com as rotas de chamadas. Vem com as duas origens do aplicativo: `tauri://localhost` (macOS) e `https://tauri.localhost` (Windows). **Sem a segunda, o aplicativo no Windows não conecta.** Se você usar o SDK numa página sua, acrescente a origem HTTPS exata dela, por exemplo `https://atendimento.seudominio.com`. Até 32 origens, sem curinga |
| `deployment_id`, `controller_id`, `admission_epoch`, `signing_key_id` | identificadores gerados (`signing_key_id` é `key-1`). **Não mude depois de preparar os bancos**: eles ficam gravados lá |
| `authority_driver`, `authority_dsn_file` | o banco de autoridade e o arquivo do passo 1.2 |
| `control.listen` | a porta de controle, `0.0.0.0:9444` |
| `control.worker_origins` | o identificador e o endereço público de cada serviço de mídia: `{"worker-1": "https://media.seudominio.com:9443"}` |
| `control.ice_policy` | `all`. Use `relay` só com servidor TURN configurado no serviço de mídia |
| `control.max_calls` | máximo de chamadas simultâneas da instância (padrão 8). Na prática, cada sessão segura no máximo 8 chamadas e cada atendente 2; veja [Cuidados de operação](#cuidados-de-operação) |
| `migrate_api` | `false`: a provisão cria o schema |

As origens são comparadas literalmente: não há curinga, `null`, troca de porta nem
redirecionamento.

> **Atenção à ordem.** Prepare os bancos (passo 1.4) **antes** de mexer no compose da API (passo
> 1.5). A provisão roda num contêiner à parte e não depende da API, que continua no ar como está.
> Se você apontar a configuração e recriar a API antes, ela não sobe com os bancos vazios, de
> propósito, e as sessões do WhatsApp caem até os bancos ficarem prontos.

### 1.4 Preparar os bancos e vincular a sessão

A provisão cria o schema do banco de autoridade e o do banco da aplicação, registra o
controlador, abre a época configurada e vincula a sessão. Ela roda uma única vez, na rede da
API:

```bash
docker run --rm --network REDE_DA_API -v /srv/zuckzapgo-calls:/private/calls \
  setupautomatizado/zuckzapgo-private:v2.5.0 \
  /app/callsprovision -config /private/calls/calls-api.json \
    -calls-driver pgx -calls-dsn-file /private/calls/calls-dsn \
    -bind-user ID_DA_SESSAO -bind-profile production
```

- `-calls-driver` é o banco da aplicação: `pgx` (PostgreSQL) ou `mysql`.
- `-bind-profile` é só um rótulo.
- Uma segunda execução sobre os mesmos bancos é recusada, de propósito. Para vincular outra
  sessão depois, repita o comando com `-bind-only`, o `-bind-user` dela e o mesmo
  `-bind-profile production`.

### 1.5 Ligar a configuração na API e reiniciar uma vez

Com os bancos prontos, monte o diretório na API em `/private/calls`, aponte a variável para o
arquivo e publique a porta de controle **presa ao IP da rede privada** do host da API:

```yaml
services:
  gateway:
    image: setupautomatizado/zuckzapgo-private:v2.5.0
    environment:
      GLOBAL_CALLS_API_CONFIG_FILE: /private/calls/calls-api.json
      # ...as demais variáveis da sua instalação
    volumes:
      - /srv/zuckzapgo-calls:/private/calls:ro
    ports:
      - "8080:8080"
      - "IP_PRIVADO_DA_API:9444:9444"   # porta de controle: só na rede privada
```

Aplique (`docker compose up -d`) e confira que a API subiu (`docker compose logs gateway`).

**Sobre a porta `9444`.** Ela atende o serviço de mídia com certificado de cliente e também o
primeiro registro dele, no mesmo número; o registro é protegido pela credencial de uso único,
não por certificado. Não a exponha para a Internet. Uma porta publicada pelo Docker como
`"9444:9444"` escuta em todas as interfaces, e o Docker passa por cima de regras do `ufw` e do
`firewalld`. Por isso, prenda a publicação a um IP privado, como acima, ou filtre o acesso na
cadeia `DOCKER-USER` do iptables ou no firewall da sua nuvem, liberando só o IP da máquina do
serviço de mídia.

## Parte 2 — Instalar o serviço de mídia de uma sessão

Repita esta parte para cada sessão que vai atender pelo aplicativo. Os exemplos usam o
identificador padrão `worker-1`.

**Numa segunda sessão:** vincule-a com `-bind-only` (passo 1.4) e escolha para o novo serviço
de mídia um identificador, um endereço público (outra porta, por exemplo `:9445`) e uma faixa
UDP só dele. Acrescente o identificador e o endereço em `control.worker_origins` e reinicie a
API antes do passo 2.2. O `calls-api.json` precisa continuar com permissão `0600` e dono `1001`
depois da edição: edite uma cópia e devolva-a com
`install -m 0600 -o 1001 -g 1001 calls-api.json.novo /srv/zuckzapgo-calls/calls-api.json`.

### 2.1 Preparar a máquina do serviço de mídia

Prepare tudo antes de emitir a credencial de registro, porque ela vale por pouco tempo (passo
2.2). Na máquina Linux do serviço de mídia, crie o diretório de configuração:

```bash
install -d -m 0755 /srv/callworker/worker-1/etc
```

Copie para lá, por um canal seguro (por exemplo `scp`):

| Arquivo na máquina do serviço de mídia | De onde vem | Permissão |
|---|---|---|
| `ca.pem` | cópia de `control-ca.pem`, do host da API | leitura |
| `api-verification-key` | cópia de `api-verification-key`, do host da API | leitura |
| `media-certificate.pem` | o certificado TLS de `media.seudominio.com`, com a cadeia completa | leitura |
| `media-key.pem` | a chave desse certificado | `0600` |

Escreva `config.json` nesse diretório. Os caminhos são **os de dentro do contêiner**:

```json
{
  "user_id": "ID_DA_SESSAO",
  "session_id": "ID_DA_SESSAO",
  "worker_id": "worker-1",
  "control_target": "calls-control.seudominio.com:9444",
  "enrollment_url": "https://calls-control.seudominio.com:9444",
  "ca_file": "/etc/callworker/ca.pem",
  "server_name": "calls-control.seudominio.com",
  "key_path": "/var/lib/callworker/key.pem",
  "certificate_path": "/var/lib/callworker/certificate.pem",
  "journal_path": "/var/lib/callworker/worker.sqlite",
  "max_calls": 2,
  "media_config_file": "/etc/callworker/media.json"
}
```

- `user_id` e `session_id` são iguais: o `id` da sessão.
- `control_target`, `enrollment_url` e `server_name` usam o mesmo nome de `-control-host`.
- `max_calls` vai de 1 a 8 e nunca passa do `-worker-max-calls` que você vai usar no passo 2.2.

E `media.json`:

```json
{
  "version": 1,
  "issuer": "https://api.seudominio.com",
  "public_origin": "https://media.seudominio.com:9443",
  "listen": "0.0.0.0:9443",
  "tls_certificate_file": "/etc/callworker/media-certificate.pem",
  "tls_key_file": "/etc/callworker/media-key.pem",
  "verification_key_files": {"key-1": "/etc/callworker/api-verification-key"},
  "origins": ["tauri://localhost", "https://tauri.localhost"],
  "ice_policy": "all",
  "ice_servers": [],
  "udp_port_min": 40000,
  "udp_port_max": 40100,
  "include_loopback": false
}
```

- `issuer` é o mesmo da API.
- `public_origin` é idêntico ao endereço de `control.worker_origins` na API, e o certificado
  precisa valer para esse nome.
- A chave de `verification_key_files` é o `signing_key_id` da API (`key-1`).
- `origins` repete as origens do `calls-api.json`, inclusive a da sua página com o SDK, se
  houver.
- Defina sempre a faixa UDP: com `0` e `0`, as portas seriam aleatórias e não dá para abri-las
  no firewall.

O serviço de mídia roda com o usuário `10001`. Ajuste dono e permissões; nenhum desses
arquivos pode ser link simbólico:

```bash
cd /srv/callworker/worker-1/etc
chown 10001:10001 *
chmod 0600 config.json media.json media-key.pem
```

### 2.2 Emitir a credencial e registrar o serviço de mídia

> **A credencial de registro vale 10 minutos e aceita no máximo 5 tentativas.** Faça este passo
> inteiro de uma vez, com a máquina do passo 2.1 já pronta.

Na API, emita a credencial. Ela é de uso único e sai num arquivo novo; o segredo nunca aparece
na saída do comando:

```bash
docker run --rm --network REDE_DA_API -v /srv/zuckzapgo-calls:/private/calls \
  setupautomatizado/zuckzapgo-private:v2.5.0 \
  /app/callsprovision -config /private/calls/calls-api.json \
    -calls-driver pgx -calls-dsn-file /private/calls/calls-dsn \
    -bind-user ID_DA_SESSAO -enroll-worker worker-1 -worker-max-calls 2 \
    -enrollment-out /private/calls/enrollment.json
```

- `-worker-max-calls` é o máximo de chamadas simultâneas que você autoriza para esse serviço de
  mídia, **de 1 a 8** (a cota de serviços de mídia da sessão).
- Um valor fora disso, um identificador inválido ou um caminho de `-enrollment-out` que não pode
  ser criado são recusados **antes** de reservar qualquer coisa, e você pode corrigir e repetir
  com o mesmo identificador. Por exemplo:
  `callsprovision: worker-max-calls 10 is above the worker quota of this session (8); use a value from 1 to 8, nothing was reserved`.
  O identificador tem de 1 a 96 caracteres entre letras, dígitos, `_`, `-`, `:` e `.`.
- Este passo também passa a sessão para o modo com serviço de mídia.

Copie `/srv/zuckzapgo-calls/enrollment.json` para a máquina do serviço de mídia **fora** do
diretório de configuração, por exemplo em `/root/enrollment-worker-1.json`, com permissão
`0600`. Assim o segredo não fica visível dentro do contêiner.

Suba o serviço de mídia uma vez, com a credencial no stdin, usando o mesmo volume que ele vai
usar sempre:

```bash
docker run --rm -i --name callworker-registro --network host \
  --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges:true \
  -v /srv/callworker/worker-1/etc:/etc/callworker:ro \
  -v callworker-worker-1:/var/lib/callworker \
  setupautomatizado/zuckzapgo-callworker:v2.5.0 < /root/enrollment-worker-1.json
```

Ele gera a chave local, grava o pedido de certificado no volume, registra-se na porta de
controle e continua rodando. Em outro terminal, confira que o certificado foi emitido e pare o
contêiner:

```bash
docker run --rm -v callworker-worker-1:/var/lib/callworker \
  --entrypoint grep setupautomatizado/zuckzapgo-callworker:v2.5.0 \
  -c -- '-----BEGIN CERTIFICATE-----' /var/lib/callworker/certificate.pem
docker stop callworker-registro
```

O primeiro comando mostra um número maior que zero quando o registro terminou.

Se o registro falhar no meio (`enrollment_unavailable` ou `issuance_unavailable`), o volume
guarda a mesma chave e o mesmo pedido: repita o `docker run` do registro **com o mesmo volume**,
dentro do prazo da credencial. Não apague o volume para contornar um resultado incerto.

**Se o identificador ficar preso.** Cada identificador recebe uma credencial uma única vez. Se
ela vencer (10 minutos ou 5 tentativas) antes do registro, uma nova emissão para o mesmo
identificador é recusada:

`callsprovision: worker enrollment: callruntime: idempotency_conflict: worker worker-1 already has an enrollment, and a credential is issued once per worker id; enroll another worker id and add it to control.worker_origins`

O mesmo vale no caso raro em que a credencial foi emitida, mas o arquivo não pôde ser gravado
(por exemplo, disco cheio): a mensagem termina com `worker worker-1 is now reserved, so enroll
another worker id and add it to control.worker_origins`. Nos dois casos:

1. Apague o arquivo da credencial velha nos dois lados (`/srv/zuckzapgo-calls/enrollment.json` e
   `/root/enrollment-worker-1.json`). A emissão só escreve num arquivo novo; com o arquivo antigo
   no lugar, ela responde
   `callsprovision: enrollment-out already exists; the credential is delivered once, to a new file`.
2. Escolha outro identificador, por exemplo `worker-2`. Troque-o em `control.worker_origins`,
   mantendo o mesmo endereço e o arquivo com permissão `0600` e dono `1001`, e reinicie a API.
3. Troque `worker_id` no `config.json` e use um volume novo (`callworker-worker-2`).
4. Repita este passo com o novo identificador.

### 2.3 Liberar o serviço de mídia para a sessão

Na API:

```bash
docker run --rm --network REDE_DA_API -v /srv/zuckzapgo-calls:/private/calls \
  setupautomatizado/zuckzapgo-private:v2.5.0 \
  /app/callsprovision -config /private/calls/calls-api.json \
    -calls-driver pgx -calls-dsn-file /private/calls/calls-dsn \
    -bind-user ID_DA_SESSAO -allow-worker worker-1
```

Antes do registro, a resposta é `callsprovision: allowed worker: the worker has not enrolled yet`.

Depois, **apague a credencial dos dois lados**: `/srv/zuckzapgo-calls/enrollment.json` no host da
API e `/root/enrollment-worker-1.json` na máquina do serviço de mídia.

### 2.4 Subir o serviço de mídia em definitivo

Na máquina do serviço de mídia, use o stack de exemplo
[`docker-compose-callworker.yaml`](https://github.com/guilhermejansen/use-zuckzapgo/blob/main/docker-compose-callworker.yaml)
do repositório de apoio, ou este compose:

```yaml
services:
  callworker-worker-1:
    image: setupautomatizado/zuckzapgo-callworker:v2.5.0
    container_name: callworker-worker-1
    restart: unless-stopped
    network_mode: host
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    stop_grace_period: 30s
    volumes:
      - /srv/callworker/worker-1/etc:/etc/callworker:ro
      - callworker-worker-1:/var/lib/callworker

volumes:
  callworker-worker-1:
    name: callworker-worker-1
```

```bash
docker compose up -d
```

Os reinícios usam a chave e o certificado do volume, sem credencial nova. Atualizar a imagem
também não exige novo registro.

**Por que a rede do host.** O serviço de mídia anuncia aos aplicativos os endereços das
interfaces que ele enxerga, e não há opção de IP público. Com a rede do host, esses endereços
são os da máquina, e a porta TCP e a faixa UDP abrem direto nela. Em rede bridge, publique a
faixa UDP com os **mesmos números** dentro e fora (`40000-40100:40000-40100/udp`) e configure
STUN, ou TURN com `"ice_policy": "relay"`; mesmo assim não há garantia de conexão direta.
Docker Desktop no Mac ou no Windows serve para testar a imagem, não para atender.

O TLS de mídia termina **no próprio serviço de mídia**. Se houver um proxy na frente, ele
precisa repassar o TCP sem abrir o TLS.

### 2.5 Reconectar a sessão do WhatsApp

A escolha entre o modo na API e o modo com serviço de mídia acontece na conexão da sessão.
Reconecte a sessão pela API ou pelo dashboard. Até lá ela continua no modo anterior, e as rotas
de configuração respondem `session_reconnect_required`.

## Parte 3 — Instalar o aplicativo do atendente

### 3.1 Instalar no macOS

1. Baixe `calls-desktop-2.5.0-macos-universal.dmg` da release v2.5.0.
2. Abra o arquivo e arraste o **Calls** para **Aplicativos**.
3. Abra o Calls. O aplicativo é assinado e notarizado pela Apple.

### 3.2 Instalar no Windows

1. Baixe `calls-desktop-2.5.0-windows-x64-setup.exe` da release v2.5.0 e confira o checksum
   (veja [Conferir os arquivos](#conferir-os-arquivos)).
2. Execute o instalador. A instalação é só para o seu usuário e não pede administrador. Se o
   Windows não tiver o componente WebView2 da Microsoft, o instalador o baixa durante a
   instalação, então mantenha o computador conectado à internet. No Windows 11 ele já vem
   instalado.
3. Nesta versão o instalador ainda não tem certificado de assinatura de código, e o Windows
   mostra **"O Windows protegeu o computador"**. Clique em **Mais informações** e depois em
   **Executar assim mesmo**.

Como todo este modo, o aplicativo para Windows é **Beta**; ele é gerado do mesmo código do
aplicativo para macOS, mas ainda não foi testado numa máquina Windows. Se algo não funcionar como
este guia descreve, avise o suporte com a versão do Windows e o que apareceu na tela.

O sistema pede acesso ao microfone na primeira vez em que o Calls usa o microfone: no teste de
dispositivo ou na primeira ligação. A câmera, só quando você ligar a prévia ou o vídeo.

### 3.3 Vincular o aparelho do atendente

O aplicativo nunca recebe o token da API. Ele recebe uma credencial curta, emitida para aquele
aparelho e aquela pessoa, depois de uma aprovação feita no navegador.

**No aplicativo:**

1. Na tela **Endereço da API**, digite o issuer, por exemplo `https://api.seudominio.com`, e
   clique em **Continuar**.
2. A tela **Confirme o dispositivo** mostra um **código** de oito caracteres. Clique em **Abrir
   página de aprovação**: o navegador abre a página de aprovação da sua API. O aplicativo
   mostra **"Aguardando sua aprovação no navegador…"** até você aprovar, ou **Cancelar vínculo**.

**No navegador, na página "Conecte seu dispositivo":**

3. Cole o **token da sessão** do WhatsApp e clique em **Acessar minha sessão**. O token fica só
   nessa página; ele não vai para o aplicativo.
4. Em **Confira o dispositivo**, confira o aplicativo e a origem mostrados, e digite o
   **código** que aparece no Calls.
5. Em **Quem vai usar o dispositivo?**, escolha o atendente. Na primeira vez, abra
   **Cadastrar um atendente**, digite o nome e clique em **Cadastrar atendente**.
6. Marque as permissões: **Receber e assumir chamadas** e **Ligar, atender e encerrar
   chamadas** (consultar já vem marcado). Clique em **Autorizar dispositivo**.
7. A página mostra **Autorização enviada**. Volte ao aplicativo.

**De volta ao aplicativo:** ele conclui o vínculo sozinho e mostra **Organização conectada**,
com os botões **Abrir chamadas** e **Conferir dispositivos**. A credencial de renovação fica no
cofre do sistema (Chaves do macOS ou Gerenciador de Credenciais do Windows).

Não autorize um código que você não pediu. Para tirar o acesso de um aparelho, revogue a família
de credenciais dele (`DELETE /session/calls/device-grants/{family_id}`). A revogação é
assíncrona: a resposta traz uma operação a acompanhar.

## Parte 4 — A primeira ligação

No aplicativo, clique em **Abrir chamadas**.

**Para ligar:**

1. Na tela **Discador**, deixe a aba **Número / pessoa**. Escolha a sessão do WhatsApp, se houver
   mais de uma.
2. Em **País ou região**, confira o país (o padrão é Brasil, `+55`).
3. Em **Número de telefone**, digite o número com DDD, como você discaria dentro do país, ou o
   número internacional começando com `+`. Também dá para usar o teclado numérico da tela.
4. Em **Tipo de chamada**, deixe **Áudio** e ligue para um número. Este modo faz só ligações de
   áudio, de uma pessoa para outra, e o aplicativo mostra o resto desabilitado nesta versão: com
   **Vídeo**, o botão **Ligar** fica desabilitado e aparece *"O servidor conectado ainda não
   oferece este tipo de mídia."*; nas abas de grupo, participantes e link de chamada, aparece
   *"Esta sessão ainda não oferece este recurso."*
5. Clique em **Ligar**. O aplicativo abre **Confirmar chamada**, com o número como será discado e
   o tipo da chamada; confira e clique em **Ligar** de novo. Na primeira ligação, o sistema pede
   acesso ao microfone: permita.

O aplicativo só aceita número de telefone válido para o país escolhido: texto, ramal e código
de serviço são recusados com o pedido de conferir o número e o país. Enquanto o resultado de uma
ligação está sendo confirmado, ele não disca de novo, para não fazer duas chamadas. O
**Discador flutuante** abre um discador numa janela pequena, que mostra a linha **"Será
discado"** antes de ligar.

Durante a ligação, use **Silenciar**, **Microfone e saída** (para escolher o microfone e o
alto-falante) e **Encerrar chamada**.

**Para atender:** uma chamada recebida toca com os botões **Atender** e **Recusar**, na janela
completa, no widget e no modo mini. **Atender** pega a chamada para este aparelho e liga o
microfone. **Recusar** recusa a chamada; numa chamada de fila, passa a vez para a próxima pessoa
da fila sem encerrá-la.

Se a ligação não completar, confira, nesta ordem:

1. O serviço de mídia está rodando (`docker ps`) e foi liberado para a sessão (passo 2.3).
2. A sessão foi reconectada depois da configuração (passo 2.5).
3. O computador do atendente alcança `https://media.seudominio.com:9443` e a faixa UDP.
4. As duas origens do aplicativo estão em `origins` da API **e** do `media.json`.

## SDK de chamadas, para o seu próprio aplicativo

O aplicativo do atendente usa por dentro o SDK de chamadas `@conversalabs/calls-sdk`. Com ele,
uma página sua disca, atende, recusa e encerra ligações, e o áudio vai do navegador direto ao
serviço de mídia, por WebRTC.

**Requisitos:**

- A instalação das partes 1 e 2 deste guia, com o serviço de mídia no ar.
- Página em HTTPS: o navegador só libera o microfone em origem segura.
- A origem da página em `origins` do `calls-api.json` **e** do `media.json`, como as do
  aplicativo (passos 1.3 e 2.1).
- Chrome, Edge ou Safari 16 e mais novos. Node.js 22.12 ou mais novo para instalar.

**Instalação:** o pacote vem da release, não do registro do npm:

```bash
npm install https://github.com/guilhermejansen/use-zuckzapgo/releases/download/v2.5.0/calls-sdk-2.5.0.tgz
```

| Import | Para quê |
|---|---|
| `@conversalabs/calls-sdk/browser` | navegador: controle das chamadas, microfone e áudio |
| `@conversalabs/calls-sdk/core` | só controle e eventos, sem áudio; roda no navegador e no Node |
| `@conversalabs/calls-sdk/native-protocol` | tipos do vínculo de aparelho, para quem escreve um aplicativo nativo |

O guia completo do SDK, com a referência de cada método, vem dentro do pacote, em
`node_modules/@conversalabs/calls-sdk/README.md`.

**Credencial.** O token da sessão nunca vai para o navegador. O seu backend pede um **grant**
curto (no máximo 5 minutos) para o atendente logado no seu sistema e entrega só o grant à
página:

```bash
curl -X POST https://api.seudominio.com/session/calls/grants \
  -H "token: SEU_TOKEN_DA_SESSAO" -H 'Content-Type: application/json' \
  --data '{"profile":"backend","operator_id":"atendente-1","role":"operator",
           "scopes":["calls:read","calls:claim","calls:control"],
           "origin":"https://atendimento.seudominio.com","endpoint_type":"browser"}'
```

O grant está em `data` na resposta. O `operator_id` precisa ser um atendente cadastrado: pela
página de aprovação (passo 3.3) ou por
`PUT /session/calls/members/{operator_id}`, com o corpo `{"display_name","role","scopes","state":"active","expected_revision":"0"}`.
Na renovação, o SDK manda `familyId` e `expectedFamilyRevision`; o backend os repassa como
`family_id` e `expected_family_revision`, para manter a mesma família de credenciais. As revisões
(`expected_family_revision` aqui e `expected_revision` dos atendentes) vão como **string** JSON,
por exemplo `"3"`.

**Uso mínimo no navegador:**

```ts
import { createBrowserCallsClient } from '@conversalabs/calls-sdk/browser';

const { client, audio } = createBrowserCallsClient({
  apiUrl: 'https://api.seudominio.com',
  mediaTransport: 'webrtc',
  autoReplace: true,
  getGrant: async context => {
    const response = await fetch('/seu-backend/calls-grant', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(context ?? {}),
    });
    return response.json();
  },
});

await client.connect();
const endpoint = await client.ensureEndpoint('browser');
client.incoming(call => mostrarChamadaTocando(call));
```

Discar e atender rodam dentro de um clique, porque o microfone exige um gesto do usuário:
`audio.acquireInput()`, depois `client.dial('+5511912345678', endpoint.endpoint_id)` ou
`client.claim(…)` e `client.answer(…)`, e por fim `audio.attachAudio(…)`. Para encerrar,
`client.hangup(call)` e `audio.closeCall(call.call_id)`. O exemplo completo, com a espera pela
chamada reservada para este aparelho, está no README do pacote.

Um erro com `uncertain: true` quer dizer que o pedido pode ter chegado ao servidor: **não repita
com um pedido novo**, que poderia discar duas vezes. Repita com o mesmo pedido
(`client.createRequest()`) ou consulte o resultado com `client.commandLookup(…)`.

## Conferir os arquivos

O `checksums.txt` da release traz o SHA-256 dos pacotes da API, dos dois instaladores e do SDK.
Confira antes de instalar:

```bash
sha256sum -c checksums.txt --ignore-missing       # Linux
shasum -a 256 -c checksums.txt --ignore-missing   # macOS
```

No Windows, rode `Get-FileHash calls-desktop-2.5.0-windows-x64-setup.exe -Algorithm SHA256` no
PowerShell e compare com a linha do arquivo.

## Mensagens do serviço de mídia

O serviço de mídia escreve códigos curtos no log (`docker logs callworker-worker-1`):

| Código | Causa provável |
|---|---|
| `invalid_configuration` | `config.json` ou `media.json` sem permissão `0600`, link simbólico, campo desconhecido, caminho relativo ou arquivo que o usuário `10001` não lê; também a falta da credencial no primeiro registro |
| `private_path_invalid` | volume ou arquivo com dono diferente de `10001`, permissão diferente de `0700`/`0600` ou link simbólico |
| `journal_filesystem_unsupported` | volume em NFS, FUSE ou pasta compartilhada; use volume local (ext4, xfs, btrfs ou zfs) |
| `journal_locked` | outro processo já abriu o mesmo volume |
| `enrollment_unavailable`, `issuance_unavailable` | a porta de controle da API não está alcançável, ou o registro está pendente; repita com o mesmo volume |
| `scope_denied` | credencial de outra sessão, de outro serviço de mídia ou já usada |
| `media_listener_unavailable` | a porta `9443` está ocupada ou sem permissão |

## Cuidados de operação

- **Um serviço de mídia por sessão**, com o próprio volume. Nunca dois processos no mesmo
  volume, e nunca o mesmo volume em duas máquinas.
- **Cotas:** cada sessão segura no máximo 8 chamadas simultâneas, e cada atendente 2. Valores
  maiores em `control.max_calls` ou no `max_calls` do serviço de mídia não passam disso.
- **Backup:** o diretório `/srv/zuckzapgo-calls`, os dois bancos e o volume de cada serviço de
  mídia. Um backup antigo do volume não substitui o atual.
- **Atualização:** pare antes de subir de novo. `docker compose up -d` já faz assim; no Swarm,
  mantenha uma réplica e `update_config.order: stop-first`.
- **Limites deste modo nesta versão:** vídeo, chamadas em grupo e gravação ficam no modo na API,
  e não há ponte SIP. Detalhes em [calls-overview.md](calls-overview.md#limites-deste-modo).

## Onde continuar

- [Chamadas: modos de uso, licença e implantação](calls-overview.md)
- [Configuração da API](CONFIGURATION.md)
- Suporte: [suporte@setupautomatizado.com.br](mailto:suporte@setupautomatizado.com.br)
