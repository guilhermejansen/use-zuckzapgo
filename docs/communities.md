# Comunidades

Uma comunidade do WhatsApp é um grupo-pai que agrupa outros grupos. Quem entra na
comunidade entra, na verdade, no **grupo de avisos** dela (o subgrupo padrão), e é por isso
que as duas permissões que o aplicativo mostra juntas, em **Permissões da comunidade**, não
moram no mesmo lugar:

| O que o aplicativo mostra | Onde o ajuste mora | Rota |
|---|---|---|
| Entrar na comunidade → **Adicionar novos membros** | no **grupo de avisos** | `POST /community/member-add-mode` |
| Criar grupos → **Adicionar novos grupos** | no **grupo-pai** | `POST /community/group-add-mode` |

As rotas de comunidade resolvem o grupo de avisos sozinhas: você sempre passa o JID da
comunidade. `POST /community/member-add-mode` devolve, em `announcement_group`, o JID em que
gravou.

`POST /group/memberaddmode` **não** é o caminho de comunidade: ela grava no JID que você
passar, e continua existindo, igual, para grupo comum.

## Ler as duas permissões

```bash
curl -s -X POST "$BASE_URL/community/settings" -H "token: $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us"}'
```

```json
{
  "success": true,
  "community": "120363000000000011@g.us",
  "announcement_group": "120363000000000012@g.us",
  "group_add_mode": "admins",
  "allow_non_admin_sub_group_creation": false,
  "member_add_mode": "all_member_add",
  "default_membership_approval_mode": "request_required"
}
```

`GET /community/settings?community=...` devolve o mesmo.

`group_add_mode` e `allow_non_admin_sub_group_creation` são o mesmo ajuste em duas formas: o
nome que esta API usa e o booleano que o WhatsApp manda. O valor também aparece em
`GET /group/info` do grupo-pai, como `AllowNonAdminSubGroupCreation`.

## Alterar

```bash
# quem pode adicionar grupos: admins | all_members
curl -s -X POST "$BASE_URL/community/group-add-mode" -H "token: $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us","mode":"admins"}'

# quem pode adicionar membros: admin_add | all_member_add (os mesmos valores de /group/memberaddmode)
curl -s -X POST "$BASE_URL/community/member-add-mode" -H "token: $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us","mode":"admin_add"}'
```

Diferença de comportamento que vale saber: em **grupo comum**, restringir "adicionar membros"
a admins também restringe o link de convite. Em **comunidade**, não — o aplicativo oficial não
faz esse acoplamento no grupo de avisos, e esta API segue o mesmo.

Quem pode alterar é decidido pelo servidor do WhatsApp, não por esta API: sem permissão a
resposta é `403 community_forbidden`.

## Sugestões de grupo

Enquanto "Adicionar novos grupos" está em `admins`, um membro não adiciona um grupo
diretamente — ele **sugere**, e um admin aprova ou recusa. É o que o aplicativo descreve com
"Os membros podem sugerir grupos aos admins, que precisarão aprovar as sugestões."

```bash
# o membro sugere um grupo que já existe (1 a 1000 por requisição)
curl -s -X POST "$BASE_URL/community/group-suggestions/create" -H "token: $TOKEN_MEMBRO" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us","groups":["120363000000000013@g.us"]}'

# o admin lista as pendentes
curl -s -X POST "$BASE_URL/community/group-suggestions" -H "token: $TOKEN_ADMIN" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us"}'

# o admin aprova (ou "reject"); o creator vem da listagem
curl -s -X POST "$BASE_URL/community/group-suggestions/update" -H "token: $TOKEN_ADMIN" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us","action":"approve",
       "suggestions":[{"group":"120363000000000013@g.us","creator":"5511999999999@s.whatsapp.net"}]}'

# quem sugeriu desiste: "cancel" vai SEM creator
curl -s -X POST "$BASE_URL/community/group-suggestions/update" -H "token: $TOKEN_MEMBRO" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us","action":"cancel",
       "suggestions":[{"group":"120363000000000013@g.us"}]}'
```

`approve` e `reject` exigem `creator`, porque o mesmo grupo pode ter sido sugerido por mais de
um membro, e cada sugestão é tratada separadamente. `cancel` não aceita `creator`: é sempre a
sugestão de quem está chamando.

### A resposta diz o resultado de cada sugestão

**Um `200` não quer dizer que todas foram aceitas.** O WhatsApp responde sucesso no IQ e marca
a recusa dentro, por item. Leia `results`:

```json
{
  "success": true,
  "community": "120363000000000011@g.us",
  "action": "approve",
  "results": [
    {"group": "120363000000000013@g.us", "creator": "5511999999999@s.whatsapp.net", "accepted": true},
    {"group": "120363000000000014@g.us", "creator": "5511999999999@s.whatsapp.net", "accepted": false, "error": 419}
  ],
  "accepted": 1,
  "refused": 1
}
```

| `error` | Em `approve`/`reject`/`cancel` | Em `group-suggestions/create` |
|---|---|---|
| `400` | — | o grupo foi criado há instantes (`reason: group_not_ready_yet`); repita em um ou dois minutos |
| `404` | a sugestão já não existe | — |
| `405` | — | o grupo já foi sugerido a esta comunidade por outro membro |
| `406` | — | nome do grupo longo demais |
| `409` | o grupo foi removido ou entrou em outra comunidade | — |
| `419` | a comunidade está cheia | a comunidade bateu o limite de sugestões |
| `433` | há adições de grupo pendentes | — |
| `500` | erro do servidor para esse item | erro do servidor para esse item |

**Grupo recém-criado.** O WhatsApp recusa com `400` um grupo criado segundos antes e aceita a
mesma sugestão um ou dois minutos depois (visto ao vivo). Esse item vem com
`"reason": "group_not_ready_yet"` e um `detail` dizendo para repetir. O gateway não repete
sozinho, e o aplicativo também não. Se o `400` continuar depois de alguns minutos, o WhatsApp
está recusando o grupo por outro motivo, que não detalha. Vincular um grupo recém-criado por
`POST /community/link` esbarra na mesma regra; ali a rota mantém o contrato antigo e responde o
`500` genérico `failed to link group`.

### Dois cuidados de comportamento do WhatsApp

1. **Trocar "Adicionar novos grupos" para `all_members` aprova todas as sugestões pendentes.**
   É decisão do servidor. A rota faz o que o aplicativo faz: **lista as pendentes antes** de
   trocar. Sem nenhuma pendente, troca direto. Com pendentes, recusa com
   `409 pending_suggestions_need_confirmation` e `pending_suggestions` (a contagem), sem enviar
   nada, até você mandar `confirm_approve_pending: true`; aí troca e responde
   `pending_suggestions_approved` com quantas estavam pendentes. Se as pendentes não couberem
   na comunidade (101 grupos pelo padrão do WhatsApp), as duas respostas trazem
   `available_group_slots` e o aviso `community_full_not_every_pending_suggestion_fits`: o
   servidor só aprova o que cabe, e não diz quantas aprovou. Se as pendentes não puderem ser
   lidas, a troca é recusada com `502 suggestions_unreadable` em vez de ser enviada às cegas.
   As vagas contam os grupos da listagem completa (`/community/all-groups`), que traz o grupo de
   avisos junto (confirmado ao vivo). O número exato de vagas não foi medido ao vivo.

2. **A listagem precisa de um grupo da comunidade em que a sessão esteja.** O WhatsApp exige
   essa dica na consulta; a rota usa o grupo de avisos, que todo membro tem, e você pode
   passar outro em `sub_group_hint`. Uma comunidade cujos subgrupos a sessão não consegue ver
   não pode ser consultada.

Sugestões só existem enquanto a permissão está em `admins`. Com ela em `all_members` a
listagem vem vazia, porque não há o que aprovar.

## Criar um grupo já dentro da comunidade

É o botão "Criar grupo" da tela de gerenciar grupos: o grupo nasce com a comunidade como pai,
numa requisição, sem existir solto em nenhum momento.

```bash
curl -s -X POST "$BASE_URL/community/group/create" -H "token: $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us","name":"Suporte","participants":["5511999999999@s.whatsapp.net"]}'
```

`POST /group/create` não mudou e continua criando grupo solto.

### Sugerir um grupo que ainda não existe

O aplicativo também deixa sugerir um grupo **novo**, que o WhatsApp cria dentro da comunidade
só se um admin aprovar. A resposta traz o JID da sugestão, que é o que
`/community/group-suggestions/update` recebe.

```bash
curl -s -X POST "$BASE_URL/community/group-suggestions/create-new" -H "token: $TOKEN_MEMBRO" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us","name":"Suporte",
       "description":"Dúvidas de instalação",
       "admins_only_send":false,"admins_only_edit_info":true,
       "join_approval":true,"member_add_mode":"admin_add"}'
```

Todo ajuste é opcional. O aplicativo sempre manda o estado do formulário de sugestão, então
`join_approval`, `member_add_mode` e `history_share_mode` sempre saem; omitidos, vão os valores
com que esse formulário começa: aprovação de entrada **desligada**, `all_member_add` e
`all_member_share`. `description`, `admins_only_send` (só admins mandam mensagem) e
`admins_only_edit_info` (só admins mudam os dados do grupo) só saem quando pedidos.

`hidden` (quem não entrou não vê) é aceito pelo esquema do WhatsApp, mas o aplicativo nunca o
manda numa sugestão. O aplicativo também não manda a permissão de link de convite numa
sugestão, e esta rota igualmente não manda.

## Todos os grupos da comunidade, inclusive os que a sessão não entrou

`POST /community/sub-groups` lista os grupos pela consulta antiga. `POST /community/all-groups`
usa a consulta que o aplicativo usa na tela de gerenciar grupos, e alcança mais:

```bash
curl -s -X POST "$BASE_URL/community/all-groups" -H "token: $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us"}'
```

```json
{
  "success": true,
  "community": "120363000000000011@g.us",
  "groups": [
    {"jid": "120363000000000012@g.us", "name": "Avisos",
     "is_default_sub_group": true, "is_general_sub_group": false,
     "is_hidden_group": false, "is_join_approval_required": false,
     "pending_membership_requests": 0},
    {"jid": "120363000000000013@g.us", "name": "Suporte",
     "is_default_sub_group": false, "is_general_sub_group": false,
     "is_hidden_group": false, "is_join_approval_required": true,
     "pending_membership_requests": 2}
  ],
  "count": 2
}
```

O grupo de avisos vem **primeiro**, marcado `is_default_sub_group` (confirmado ao vivo: a
listagem trouxe o grupo de avisos e o grupo sugerido). Além dos grupos em que a
sessão não entrou, esta rota traz o grupo geral, o grupo oculto, a exigência de aprovação de
entrada e quantos pedidos cada grupo tem esperando — nada disso na rota antiga.

## Transferir a propriedade da comunidade

Torna um **admin** da comunidade o dono dela. **Quem chama deixa de ser o dono**, então só o
novo dono pode devolver: por isso a rota exige `confirm: true`.

```bash
curl -s -X POST "$BASE_URL/community/transfer-ownership" -H "token: $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us",
       "new_owner":"5511999999999@s.whatsapp.net","confirm":true}'
```

Antes de enviar, a rota confere, na lista de participantes da comunidade, as mesmas condições
com que o aplicativo decide se mostra a opção, e **nada é enviado** se alguma falhar:

| Condição | Resposta |
|---|---|
| o JID é de uma comunidade | `400 not_a_community` |
| a comunidade não está suspensa | `409 community_suspended` |
| `new_owner` não é a própria sessão | `400 transfer_to_self` |
| a sessão é a dona | `409 not_owner` |
| `new_owner` participa da comunidade | `409 target_not_member` |
| `new_owner` é admin | `409 target_not_admin` |
| a lista pôde ser lida | `502 roles_unreadable` |

Para transferir a alguém que é só membro, promova-o a admin da comunidade antes
(`POST /group/updateparticipants` com `Action: "promote"` no JID da comunidade; confirmado ao
vivo). A lista lida aqui é a da própria comunidade, que parece trazer só os admins, então um
membro comum pode cair em `target_not_member` em vez de `target_not_admin` (dedução pelo
cliente oficial; não testado ao vivo). O dono é
enviado do jeito que a lista de participantes o nomeia (o endereçamento da própria
comunidade, normalmente LID), e a resposta devolve essa forma em `new_owner`.

Toda resposta de erro das duas rotas sem volta (transferir e desativar) traz `success: false`,
um `reason` e **`sent`**: `false` quer dizer que nada saiu do gateway e pode repetir; `true`
quer dizer que pode ter chegado ao WhatsApp. Se o envio der timeout ou a conexão cair depois
dele, a resposta é `504 transfer_outcome_unknown` (ou `deactivate_outcome_unknown`): **não
repita**. Leia o estado com `GET /group/info?groupJID=<comunidade>` e decida a partir dele.
Essas duas ações saem uma vez só: a biblioteca não as reenvia sozinha depois de uma queda.

## Desativar a comunidade

Encerra a comunidade: o WhatsApp desvincula todos os grupos e a comunidade deixa de existir.
Os grupos continuam, soltos. **Não tem volta**, então a rota exige `confirm: true`.

```bash
curl -s -X POST "$BASE_URL/community/deactivate" -H "token: $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"community":"120363000000000011@g.us","confirm":true}'
```

Só a conta que **criou** a comunidade pode desativar; para qualquer outra o WhatsApp responde
`403`. Se a comunidade já não existe, responde `404 community_not_found` (confirmado ao vivo,
numa segunda desativação). Resultado incerto
(timeout ou queda depois do envio) é `504 deactivate_outcome_unknown`, com `sent: true`: leia
com `GET /group/info`, onde "não encontrado" quer dizer que a desativação aconteceu.

É esta rota que resolve o caso de sair de uma comunidade em que você é o único admin: ali
`POST /group/leave` responde `200` e a comunidade continua de pé, porque o WhatsApp exige
desativar.

## Erros

Toda rota nova de comunidade desta versão responde erro no mesmo formato, com `success: false`
no nível de cima do envelope:

```json
{"code": 403, "success": false, "reason": "community_forbidden",
 "error": "whatsapp refused the permission change", "community": "120363000000000011@g.us",
 "sent": true}
```

- `reason` é o código, para máquina: `invalid_request`, `not_a_community`,
  `community_forbidden`, `community_not_found`, `community_announcement_group_not_found`,
  `community_rate_limited` (com `Retry-After`), `whatsapp_not_connected`,
  `community_request_failed`, `unauthorized`, `no_session`, e os específicos de cada rota
  descritos acima.
- `error` é o texto para gente.
- `community` aparece quando o JID da comunidade já foi validado.
- `sent` só existe nas rotas que **gravam** (as duas permissões, sugerir, aprovar, recusar e
  cancelar sugestões, criar grupo, sugerir grupo novo, transferir, desativar). `false`: nada saiu
  do gateway e pode repetir. `true`: pode ter chegado ao WhatsApp; leia o estado antes de
  repetir. As leituras (`/community/settings`, `/community/group-suggestions`,
  `/community/all-groups`) não trazem `sent`.

As rotas de comunidade que já existiam antes desta versão (`/community/link`, `/unlink`,
`/linked`, `/linked-groups`, `/sub-groups`, `/requests`, `/requests/update`, `/create`,
`/announcement`) continuam com o formato de antes.

## Desvincular um grupo do qual a sessão não é membro

`POST /community/unlink` com só `group` lê o grupo para descobrir a comunidade pai, e essa
leitura exige ser membro do grupo. Um admin da comunidade que não está no grupo recebe `500
failed to get group info`. Mande também `community`: o pedido vai direto à comunidade, como faz
a tela da comunidade no aplicativo.

```bash
curl -s -X POST "$BASE_URL/community/unlink" -H "token: $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"group":"120363000000000013@g.us","community":"120363000000000011@g.us"}'
```

Se a sessão conseguir ler o grupo, o pai dele tem de ser essa comunidade: outro pai responde
`409 group is linked to a different community`, sem enviar nada. Sem `community`, a rota
responde exatamente como antes.

## O que ainda não tem rota

- **Pedir revisão de uma comunidade suspensa.** A leitura está disponível: `GET /group/info`
  devolve `Suspended` para a comunidade, e uma comunidade suspensa também bloqueia os grupos
  dela. O **pedido de revisão**, não: o cliente oficial o envia por uma chamada GraphQL
  autenticada pela sessão web do Facebook, não pelo soquete do WhatsApp, e um aparelho
  vinculado como este gateway não tem essa sessão. O pedido de revisão se faz no aplicativo.

## Eventos

Uma mudança na permissão de grupos chega no webhook como `GroupInfo` com
`AllowNonAdminSubGroupCreation` (`true` para todos, `false` para só admins). Em qualquer outra
mudança de grupo o campo vem `null`. O nó original da notificação continua também em
`UnknownChanges`, onde chegava antes desta versão, para quem já o lia ali. Ver
`docs/webhook-events.md`.
