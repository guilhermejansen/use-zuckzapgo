# Rota mobile nativa por sessão

Este guia descreve o egress TCP por sessão incorporado ao ZuckZapGo com
`tailscale.com/tsnet` v1.98.8. Ele substitui o sidecar SOCKS manual no piloto;
não cria outro serviço e não altera o protocolo WhatsApp.

## Garantias e limites

- Cada usuário com rota desejada possui um `tsnet.Server`, hostname opaco e
  diretório de estado próprio em modo `0700`.
- O exit node é selecionado por `StableNodeID`; hostname e IP mutáveis não são
  aceitos como identidade da rota.
- `ExitNodeAllowLANAccess=false` é aplicado explicitamente.
- O SOCKS5 escuta somente em `127.0.0.1`, exige usuário `tsnet` e senha aleatória
  criada pelo próprio tsnet.
- Antes de a rota ficar `ready`, o servidor realiza conexão TCP e handshake TLS
  com `web.whatsapp.com:443` através desse SOCKS. Como `EditPrefs` converge de
  forma assíncrona, o preflight tem até 8 tentativas canceláveis (5 s por
  tentativa, backoff de 250 ms até 2 s) e exige 2 sucessos consecutivos. Isso
  absorve convergência transitória sem aceitar uma rota que oscila.
- A auth key JIT existe somente durante o apply. O decoder guarda a cópia da
  aplicação em bytes mutáveis e os sobrescreve em todos os retornos; ela não
  entra no banco, estado de resposta ou logs. A API do tsnet recebe `string`,
  então o campo `tsnet.Server.AuthKey` é esvaziado imediatamente após `Start`;
  o backing imutável transitório da biblioteca fica sem referência e depende
  do GC, razão adicional para a chave ser JIT e realmente single-use.
- A senha SOCKS e a URL interna do proxy ficam somente no manager em memória.
- Uma rota `mobile` exige `tcpOnly=true`; `direct` não é um modo válido.
  Recomenda-se enviar `failClosed=true` explicitamente para reter tráfego enquanto
  a rota não está pronta. `failClosed=false` é suportado e a omissão também vira
  `false`: a sessão pode usar o proxy legado ou a saída direta nesse período.
  Isso muda o IP visto pelo WhatsApp e deve ser escolha explícita do operador.
- `tcpOnly` descreve o egress WhatsApp exposto pelo SOCKS. O próprio Tailscale
  pode usar UDP/WireGuard ou DERP para transportar esse TCP; portanto não trate
  a flag como promessa de ausência de pacotes UDP no host.
- Com `failClosed=true`, uma rota desejada que não esteja pronta bloqueia
  `startClient`; falha ao aplicar o proxy também aborta o bootstrap, sem fallback.
  Com `failClosed=false`, uma rota não pronta permite o egresso padrão
  (`proxy_url` legado, quando configurado, ou direto). Isso não torna a rota
  móvel `ready` nem confirma o provisionamento dela.
- A rota mobile é aplicada ao transporte WhatsApp (WebSocket e mídia) e não ao
  cliente HTTP auxiliar que entrega webhooks/control plane. Isso impede que o
  celular vire um proxy genérico e evita dependência circular com o Chatwoot.
  O comportamento legado de proxy para esse cliente auxiliar permanece apenas
  para sessões que usam `proxy_url`, fora do modo mobile.
- Calls nativo depende de UDP. O guard bloqueia o engine nas rotas `mobile`
  com `failClosed=true` e `tcpOnly=true`. `failClosed=false` não ativa esse guard,
  mas o SOCKS continua TCP: a política permissiva não habilita mídia UDP pela
  rota móvel nem garante chamadas por ela.

Limite honesto: o processo consegue verificar que o exit node configurado
produziu um caminho SOCKS/TLS funcional, mas a prova física de operadora móvel,
ASN e geolocalização do IP de saída deve ser feita no tailnet/piloto. O backend
que emite a auth key também deve configurá-la como single-use; a aplicação não
consegue transformar uma chave reutilizável em chave de uso único.

## Configuração do estado

O estado do nó Tailscale de cada rota (a identidade que permite restaurar sem
auth key nova) fica no banco da aplicação, na tabela `network_route_node_state`
(migração 29, PostgreSQL, MySQL e SQLite), cifrado. A auth key continua sem ser
guardada em lugar nenhum. Com isso o serviço não precisa de volume nem de trava de
máquina: deploy, restart, recriação do container ou troca de nó do cluster
restauram a rota `ready`, passando pelo mesmo preflight TLS de sempre.

```bash
# Todas opcionais.
NETWORK_ROUTE_STATE_DIR=/var/lib/zuckzapgo/network-routes   # só importação legada
NETWORK_ROUTE_STATE_KEY=                                    # chave própria, >= 32 caracteres
NETWORK_ROUTE_STATE_KEY_PREVIOUS=                           # valor antigo, só na troca
NETWORK_ROUTE_RESTORE_CONCURRENCY=32                        # rotas em paralelo no boot
```

### Criptografia e chaves

- Cada valor do estado é cifrado com AES-256-GCM (biblioteca padrão do Go), com
  nonce aleatório por gravação e dados autenticados `user_id + state_key`: um
  byte alterado faz a leitura falhar, e o estado de uma sessão não abre como
  estado de outra. Cada linha guarda o `key_id` da chave que a cifrou (`auto` ou
  `env:<impressão digital>`, que identifica sem revelar).
- **Sem `NETWORK_ROUTE_STATE_KEY`** (padrão): no primeiro boot o gateway gera uma
  chave aleatória de 32 bytes e a guarda em `network_route_state_keys`; os boots
  seguintes e as outras réplicas reutilizam a mesma. Nada precisa ser configurado.
  **Limitação:** a chave fica no mesmo banco do estado, então quem tem o banco
  inteiro consegue abrir o estado. A chave nunca deriva de `ZUCKZAPGO_ADMIN_TOKEN`
  nem de outro segredo configurável: trocá-los não afeta rotas.
- **Com `NETWORK_ROUTE_STATE_KEY`**: qualquer texto com pelo menos 32 caracteres; a
  chave de cifra é derivada dele por HKDF-SHA256. O valor nunca é gravado. No boot
  em que ela aparece, o estado cifrado com a chave automática é recifrado com ela
  (log `network_route_state_rewrapped`), sem ação do operador e sem auth key nova.
  Valor com menos de 32 caracteres é ignorado com `network_route_state_key_invalid`
  (sem imprimir o valor) e o gateway sobe normalmente.
- **Trocar o valor da chave**: suba com o novo valor em `NETWORK_ROUTE_STATE_KEY` e
  o antigo em `NETWORK_ROUTE_STATE_KEY_PREVIOUS`. O boot recifra tudo com o novo;
  depois de conferir `network_route_state_rewrapped` e as rotas `ready`, a
  variável anterior pode sair. **Trocar a chave sem informar a anterior deixa as
  rotas cifradas com ela em `restore_failed`**, pelo caminho normal de falha
  (fail-closed retém a sessão; permissiva sai pela saída padrão). A recuperação é
  a mesma de sempre: versão maior com auth key nova, que descarta o estado
  indecifrável e inscreve o nó do zero.
- Estado que não abre com nenhuma chave nunca derruba o processo: a rota vai para
  `restore_failed`, as demais sobem, e o log registra
  `network_route_state_undecryptable` com o `userID` e os `key_id`, sem conteúdo.

### Importação do estado legado (2.1.0)

`NETWORK_ROUTE_STATE_DIR` agora é só a origem de uma importação única. No boot,
para cada rota sem estado no banco, o gateway lê
`NETWORK_ROUTE_STATE_DIR/route-<hash>/tailscaled.state`, cifra, grava no banco e
renomeia o arquivo para `tailscaled.state.imported`
(`network_route_state_imported`). Se o banco já tem estado da rota, o arquivo é
ignorado (`network_route_state_import_skipped`: o banco vence). Arquivo ilegível
não interrompe o boot e não é apagado (`network_route_state_import_failed`). Se o
rename falhar (volume somente leitura), o estado já está no banco e o próximo boot
apenas ignora o arquivo.

O diretório de trabalho do tsnet (configuração e buffer de log) fica em
`$TMPDIR/zuckzapgo-tsnet/route-<hash>`, descartável.

### Deploy sem volume, em dois passos

Uma instalação que já tem `tailscaled.state` em volume migra assim:

1. **Deploy da versão nova ainda com o volume montado.** Confira no log
   `network_route_state_imported` para cada rota e `GET /session/network-route`
   com `ready: true`.
2. **Deploy seguinte sem o volume e sem restrição de máquina** (por exemplo,
   `docker service update --mount-rm ... --constraint-rm ...`). A rota volta
   `ready` a partir do banco. Só apague o volume antigo depois de um período
   estável.

Instalações novas não precisam de volume em momento nenhum. Em Swarm, nunca use
`docker service rollback` às cegas depois do passo 2: o spec anterior pode trazer
mounts ou tirar os atuais; volte a imagem explicitamente.

**Voltar para a 2.1.0:** as tabelas novas ficam inertes (a 2.1.0 as ignora e
nenhuma coluna existente mudou). A 2.1.0 volta a exigir o arquivo: com o volume
ainda montado, renomeie `tailscaled.state.imported` de volta para
`tailscaled.state`; sem ele, a rota precisa de versão maior com auth key nova.

### Concorrência e dono único

A gravação do estado só vale se a rota ainda deseja a versão que o processo
carregou (`network_routes.desired_version`). Gravação de um processo antigo é
descartada com `network_route_state_write_fenced` no log (sessão e versões), sem
erro para a sessão e sem derrubar o processo; leituras nunca esperam trava. A
regra operacional continua: um único processo dono de cada sessão.

### Códigos de log do estado (`routeStateCode`)

| Código | Quando |
|---|---|
| `network_route_state_key_generated` | chave automática criada no banco (primeiro boot sem variável) |
| `network_route_state_key_invalid` | variável com menos de 32 caracteres, ignorada |
| `network_route_state_imported` | `tailscaled.state` legado importado |
| `network_route_state_import_skipped` | arquivo legado ignorado (banco já tem estado, ou arquivo vazio) |
| `network_route_state_import_failed` | arquivo legado ilegível; nada apagado |
| `network_route_state_rewrapped` | estado recifrado com a chave atual |
| `network_route_state_rewrap_failed` | recifragem falhou; o valor antigo continua legível |
| `network_route_state_undecryptable` | estado não abre com nenhuma chave; rota em `restore_failed` |
| `network_route_state_write_fenced` | gravação de processo antigo descartada |

Nenhum desses logs carrega estado, chave, nonce ou valor cifrado.

## Provisionar ou atualizar

Endpoint autenticado com o token real da sessão:

```http
POST /session/network-route
token: <TOKEN_DA_SESSAO>
Content-Type: application/json
```

```json
{
  "mode": "mobile",
  "authKey": "<AUTH_KEY_JIT_DE_USO_UNICO>",
  "exitNodeId": "nStableMobileExit01",
  "routeVersion": 1,
  "idempotencyKey": "route-2026-08-15-0001",
  "failClosed": true,
  "tcpOnly": true
}
```

O backend deve obter `authKey` imediatamente antes da chamada. Não envie essa
chave ao navegador, não a registre em telemetria e não reutilize o valor em uma
nova versão. Envie `failClosed` explicitamente: `true` é a política recomendada
para impedir fallback; `false` ou a omissão permitem egresso padrão se a rota
estiver indisponível. `tcpOnly` deve permanecer `true` em ambos os casos.

Resposta segura:

```json
{
  "code": 200,
  "data": {
    "mode": "mobile",
    "exitNodeId": "nStableMobileExit01",
    "desiredVersion": 1,
    "appliedVersion": 1,
    "failClosed": true,
    "tcpOnly": true,
    "status": "ready",
    "ready": true
  },
  "details": "network route ready",
  "reconnectScheduled": false,
  "success": true
}
```

Nem a auth key, nem a senha SOCKS, nem a URL do proxy aparecem na resposta.

## Ler o estado

```http
GET /session/network-route
token: <TOKEN_DA_SESSAO>
```

O GET retorna somente metadados não secretos. `ready=true` exige ao mesmo tempo:

1. estado persistido `status=ready`;
2. `desiredVersion == appliedVersion`;
3. runtime tsnet ativo para a mesma versão.

## Remover a rota (saída explícita do operador)

```http
DELETE /session/network-route
token: <TOKEN_DA_SESSAO>
```

Por que este endpoint existe: uma rota fail-closed que não converge prende a
sessão inteira. `ProxyForStart` recusa o start quando não há runtime vivo, quando
o `status` persistido não é `ready`, ou quando `desiredVersion` e
`appliedVersion` divergem — e com `failClosed=true` não existe fallback, por
projeto. O `startClient` aborta, `users.connected` vai a zero e todo
`GET /session/qr` seguinte responde `500 no session`; a tela do cliente fica
presa em "Aguardando o QR code…". O caso mais duro é o restart do gateway em que
a restauração do nó tsnet não acontece — estado do nó indecifrável, auth key já
consumida, exit node fora do ar: sem runtime, cada rota fail-closed bloqueia sua
sessão indefinidamente, sem autocura. Até este endpoint existir, o único conserto
era editar o banco na mão.

Como reconhecer o caso antes de agir: a linha de erro do bootstrap carrega os
fatos que decidem — `routeReason`, `routeStatus`, `routeDesiredVersion`,
`routeAppliedVersion`, `routeRuntimeActive`, `routeRuntimeVersion` e, quando
existe, `routeErrorCode`. O `GET /session/network-route` mostra o mesmo estado
persistido junto de `ready`.

**Remover não é conserto: é troca de saída.** O DELETE faz logout do nó no
tailnet, fecha o runtime, apaga a linha persistida e limpa o diretório de estado
derivado. Na conexão seguinte a sessão sai pelo `proxy_url` legado ou, quando não
há nenhum, direto pela internet do host — ou seja, o outro lado passa a ver outro
IP. Por isso a remoção nunca é automática e nunca é fallback: é decisão
deliberada do operador, o único que sabe se aquele número pode aparecer com outra
saída.

Ordem executada, sob o mesmo mutex por usuário do apply:

1. lê o estado atual — é o último instante em que ainda dá para dizer o que foi
   removido, e é o que decide o passo 4;
2. desconecta o cliente vivo e limpa o QR guardado; um código da era bloqueada
   não pareia mais, apenas engana quem o escaneia;
3. faz logout/fecha o nó, apaga a linha e remove o diretório de estado derivado;
4. reagenda o start quando a rota era o que segurava a sessão: havia cliente
   conectado, ou a rota fail-closed não estava pronta. Uma sessão que o operador
   desligou por vontade própria, com rota sadia, continua desligada.

Resposta — `data` é a rota como lida imediatamente antes da remoção, então ela
ainda diz o que foi removido:

```json
{
  "code": 200,
  "data": {
    "mode": "mobile",
    "exitNodeId": "nStableMobileExit01",
    "desiredVersion": 4,
    "appliedVersion": 3,
    "failClosed": true,
    "tcpOnly": true,
    "status": "blocked",
    "ready": false,
    "errorCode": "network_route_prepare_failed"
  },
  "details": "network route removed; this session egresses through its legacy proxy_url on the next connect, or directly when none is set",
  "reconnectScheduled": true,
  "success": true
}
```

Repetir a chamada é seguro: sem rota, a resposta é
`404 network_route_not_configured`. Isso vale inclusive depois de um
`503 network_route_revoke_failed`, em que parte da remoção pode já ter
acontecido — um 404 na retentativa significa que a rota não existe mais e a
sessão volta a subir pelo caminho legado.

Depois da remoção não sobra identidade para restaurar: uma rota nova exige outra
auth key JIT de uso único. O fencing também recomeça, porque a linha persistida
sumiu e qualquer `routeVersion` válido é aceito no próximo apply; ainda assim,
mantenha o contador do seu lado crescendo. E o guard do Calls nativo, ativo
enquanto uma rota mobile fail-closed TCP-only estava desejada, é removido no próximo
start do cliente.

## Fencing e idempotência

- `routeVersion` deve ser positivo e crescer monotonicamente.
- Versão menor que a desejada retorna `409 network_route_stale_version`.
- Repetir exatamente versão, digest de configuração e `idempotencyKey` retorna
  o resultado atual sem desconectar e sem criar outro nó.
- Reutilizar a mesma versão com exit node/configuração diferente, ou com outra
  idempotency key, retorna `409 network_route_version_conflict`.
- Depois de uma falha, corrija a causa e envie uma versão maior com nova auth
  key. Uma repetição exata da versão bloqueada devolve o mesmo estado e código
  503 sem desconectar novamente, iniciar outro nó ou consumir outra vez a
  credencial; não é uma segunda tentativa de provisionamento.

## Ordem atômica do apply

O handler usa o mesmo mutex por usuário de connect/disconnect/refresh/logout:

1. valida versão e idempotência;
2. bloqueia e desconecta o cliente existente;
3. persiste a nova versão como `preparing`;
4. inicia/restaura o tsnet, aplica o exit node e executa o preflight SOCKS/TLS;
5. marca a versão como `ready` e `applied`;
6. somente então agenda reconexão de uma sessão que estava conectada.

Falha entre os passos 3 e 5 grava um código seguro e deixa o estado `blocked`.

## Provisionamento junto com AddUser

`POST /admin/users` aceita `networkRoute` opcional com o mesmo objeto:

```json
{
  "name": "pilot-mobile-01",
  "token": "<TOKEN_NOVO>",
  "networkRoute": {
    "mode": "mobile",
    "authKey": "<AUTH_KEY_JIT_DE_USO_UNICO>",
    "exitNodeId": "nStableMobileExit01",
    "routeVersion": 1,
    "idempotencyKey": "provision-pilot-0001",
    "failClosed": true,
    "tcpOnly": true
  }
}
```

Não combine `networkRoute` com `proxyConfig`; a API retorna 400. O usuário é
criado antes do pareamento, a rota é verificada e só depois a sessão poderá
conectar.

Contrato de sucesso consumido pelo Chatwoot (campos não relacionados omitidos):

```json
{
  "code": 201,
  "data": {
    "id": "stable-internal-user-id",
    "token": "<TOKEN_NOVO>",
    "network_route": {
      "mode": "mobile",
      "exitNodeId": "nStableMobileExit01",
      "desiredVersion": 1,
      "appliedVersion": 1,
      "failClosed": true,
      "tcpOnly": true,
      "status": "ready",
      "ready": true
    }
  },
  "success": true
}
```

O Chatwoot só deve considerar o provisionamento concluído quando `ready=true`
e `desiredVersion == appliedVersion`. No 2xx, `data.id`, `data.token` e
`data.network_route` estão presentes; a auth key nunca está.

Se o provisionamento falhar depois do INSERT, o usuário permanece
deliberadamente persistido e bloqueado. A resposta 503 usa `data.userId` seguro
e estável — deliberadamente sem `token` — para rollback:

```json
{
  "code": 503,
  "data": {
    "userId": "stable-internal-user-id",
    "network_route": {
      "mode": "mobile",
      "exitNodeId": "nStableMobileExit01",
      "desiredVersion": 1,
      "appliedVersion": 0,
      "failClosed": true,
      "tcpOnly": true,
      "status": "blocked",
      "ready": false,
      "errorCode": "network_route_prepare_failed"
    }
  },
  "error": "network_route_prepare_failed",
  "details": "user persisted in blocked state; submit a higher routeVersion with a new one-use auth key or delete this user",
  "success": false
}
```

O rollback recomendado é `DELETE /admin/users/{data.userId}` com o admin token.
Alternativamente, preserve o usuário bloqueado e aplique uma versão maior com
uma nova auth key por um backend que já possua o token da sessão. Nunca repita
AddUser cegamente: o token já existe e a auth key anterior pode ter sido
consumida.

## Restart, revogação e shutdown

- Startup lê os metadados desejados e o estado de todos os nós numa consulta,
  importa o legado e recifra o que for preciso, e restaura os nós em paralelo
  (`NETWORK_ROUTE_RESTORE_CONCURRENCY`), sem auth key. Rotas que não restauram
  ficam `blocked` antes do auto-connect.
- Exclusão de usuário executa logout/revogação do nó, fecha o runtime, apaga os
  metadados e o estado do nó no banco (mesma transação) e remove apenas os
  subdiretórios derivados daquele usuário.
- `DELETE /session/network-route` executa exatamente a mesma revogação sem apagar
  o usuário, preservando token, pareamento e histórico da sessão. É a saída para
  uma rota que não restaura depois de um restart.
- Graceful shutdown fecha todos os runtimes sem logout, preservando a identidade
  necessária ao próximo startup.

## Códigos principais

| HTTP | Código | Significado |
|---|---|---|
| 400 | `network_route_mode_invalid` | modo diferente de `mobile` |
| 400 | `network_route_mobile_requires_tcp_only` | `tcpOnly` ausente ou falso; `failClosed=false` é aceito |
| 400 | `network_route_auth_key_invalid` | auth key ausente/malformada |
| 409 | `network_route_stale_version` | fencing rejeitou versão antiga |
| 409 | `network_route_version_conflict` | mesma versão, outro digest/idempotency |
| 503 | `network_route_prepare_failed` | tsnet, exit node ou preflight falhou |
| 503 | `network_route_store_unavailable` | metadados não puderam ser lidos/gravados |
| 404 | `network_route_not_configured` | não há rota; no DELETE, resposta idempotente |
| 503 | `network_route_manager_unavailable` | manager de rotas não inicializado |
| 503 | `network_route_revoke_failed` | logout, exclusão ou limpeza falhou; repita o DELETE |

Erros externos nunca incluem resposta do control plane, credencial ou proxy.

## Capacidade

Cada rota pronta contém um netstack e control client Tailscale independentes.
Isso custa mais memória e goroutines que um proxy compartilhado. Dimensione o
piloto medindo RSS, goroutines, conexões DERP e tempo de restore com a quantidade
real de sessões; não extrapole custo de uma única sessão. O binário também cresce
porque incorpora tsnet/gVisor. Não existe worker ou processo sidecar adicional.

## Validação da implementação

Gates executados no worktree desta implementação:

```bash
go test -count=1 ./...
go test -race -count=1 . -run 'Test(NetworkRoute|AddUserNetworkRoute|ApplySessionProxy)'
go build ./...
CGO_ENABLED=0 go build ./...
git diff --check
```

Também foram validados o parse de `static/api/spec.yml`, `swagger.yaml`,
`swagger.json` e a geração da collection Postman com GET/POST, fencing e o shape
de rollback Chatwoot.

Como referência — não como estimativa isolada de custo do tsnet — o binário
Darwin/arm64 deste worktree mediu 108.219.714 bytes. O `.zzg-dev` local anterior
mede 84.579.874 bytes; a diferença indicativa é 23.639.840 bytes (27,9%) e também
inclui os demais diffs de Calls/buffer preservados no worktree.

Ainda faltam duas provas que não podem ser fabricadas em teste unitário: executar
com auth key real de uso único/exit node móvel e confirmar ASN/geolocalização do
IP físico; e medir RSS/goroutines/DERP por sessão no volume real do piloto. Até
essas medições, não extrapole memória por nó nem declare prova de operadora.
