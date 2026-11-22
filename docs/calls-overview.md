# Chamadas: modos de uso, licença e implantação

Chamadas de voz pelo ZuckZapGo funcionam de duas formas diferentes, e a escolha muda o que
você instala, por onde passa o áudio e quem fala com o WhatsApp. Esta página compara as
duas, explica a regra de licença que vale para ambas e descreve a implantação de cada uma.

Para os formatos exatos de áudio, os corpos de requisição e os exemplos de cliente, use os
guias técnicos citados ao longo do texto e o [OpenAPI](../api/spec.yml) da versão que você
instalou.

> Esta é a integração por protocolo de aparelhos vinculados, não a API oficial da
> Meta/WhatsApp. Limites de participantes e restrições de conta são impostos pelo WhatsApp,
> não pelo gateway.

## Licença de Chamadas

A regra é a mesma nos dois modos e vale para a instalação inteira, não por sessão.

| Situação | O que acontece |
|---|---|
| Nova assinatura | Chamadas exigem licença **Enterprise** |
| Assinatura ou instalação que já tinha direito a chamadas antes desta política | Mantém o acesso, sem mudar de plano |
| A verificação da licença traz a decisão, e ela nega chamadas | As rotas de chamada respondem `403` |
| A verificação é bem-sucedida e **não traz** decisão sobre chamadas — campo ausente, `null` ou vazio | Vale a última decisão que a instalação recebeu. Nunca recebeu nenhuma: as chamadas continuam liberadas |
| A verificação traz uma decisão que o gateway não reconhece | As rotas de chamada respondem `503`, e a última decisão recebida é preservada |
| Licença inválida ou expirada | **O gateway não sobe, ou encerra**, com o erro no log — em Docker, o contêiner fica reiniciando. Não é `503` nas rotas de chamada |

A decisão **em vigor** fica no cache de licença e sobrevive a reinício, inclusive numa subida
pelo cache dentro da tolerância offline. A última decisão **reconhecida** também é guardada, e
é ela que volta a valer na próxima verificação bem-sucedida: por isso uma resposta ilegível não
apaga o direito, mas, enquanto o servidor de licenças não responder de novo, o reinício sobe com
o `503` que estava em vigor. Uma verificação que não fala de chamadas nunca derruba o acesso, e
uma negação já recebida não é desfeita por esse silêncio.

As rotas protegidas são `/call/*` e `/session/skipcalls/config`, que existem sempre, mais
`/calls/*` e `/session/calls/*`, que **só existem quando o modo com serviço de mídia está
configurado** — sem essa configuração elas respondem `404`, qualquer que seja a licença. As
demais rotas da API — mensagens, grupos, negócios, sessões — não são afetadas: continuam
atendendo normalmente com a sua licença atual.

| Resposta | `error_code` | O que fazer |
|---|---|---|
| `403` | `calls_enterprise_required` | É a decisão do servidor de licenças para esta instalação: a licença não inclui chamadas. Fale com o suporte para avaliar o upgrade; nenhuma variável de ambiente libera o recurso. |
| `503` | `calls_license_unavailable` | Tem **uma causa só**: a verificação trouxe uma decisão sobre chamadas que o gateway não conseguiu ler — agora, ou na última resposta guardada no cache. É transitório se o servidor de licenças voltar a responder algo legível, e permanente enquanto ele mandar um valor desconhecido. O que conferir é a **resposta do servidor de licenças**, não a sua `LICENSE_KEY`: licença inválida não gera `503`, derruba o processo. **Não é** o que acontece quando a verificação simplesmente não fala de chamadas. |

Dois efeitos que costumam passar despercebidos:

- **Os eventos de chamada também dependem da licença.** Sem autorização, o gateway não
  emite `CallOffer`, `CallAccept`, `CallTerminate` e os demais eventos de chamada para o seu
  webhook. Um webhook silencioso pode ser licença, não configuração.
- **Só a perda explícita da autorização encerra o que está em andamento.** Na renovação, uma
  licença que mantém o direito preserva as chamadas e os streams abertos — e o mesmo vale
  quando a resposta não fala de chamadas. Encerram as chamadas e os streams daquela
  instalação apenas a negação explícita e a decisão que o gateway não conseguiu ler.

## Os dois modos de uso

| | Modo na API | Modo com serviço de mídia |
|---|---|---|
| O que você instala | Somente a API (gateway) | A API **mais** um serviço de mídia por sessão, o SDK de chamadas e o aplicativo do atendente |
| Quem carrega o áudio | O próprio gateway: ele termina a mídia do WhatsApp e entrega o áudio ao seu sistema | O serviço de mídia, num processo e numa máquina separados. O áudio vai direto do navegador ou do aplicativo para esse serviço, sem passar pelo gateway |
| Como o áudio chega ao seu lado | WebSocket de PCM na própria API | WebRTC direto com o serviço de mídia |
| Quem controla a chamada | O seu sistema, por `/call/*` com o token da sessão | O atendente, pelo aplicativo ou por uma página com o SDK |
| Quem é o "usuário" | O seu software | Uma pessoa atendendo |
| Banco de dados | Só o banco da aplicação | O banco da aplicação **mais** um banco de autoridade separado |
| Porta nova para publicar | Nenhuma | A porta de controle da API, alcançável pelo serviço de mídia, e, no serviço de mídia, a porta HTTPS e a faixa UDP |
| Áudio e vídeo | Áudio e vídeo (vídeo em BETA, com codec no seu cliente) | Somente áudio, de uma pessoa para outra |
| Disponibilidade | Nos pacotes publicados desta distribuição | Nos pacotes publicados desta distribuição, a partir da 2.5.0: veja [o que baixar](calls-media-install.md#o-que-você-vai-baixar) |

A API é obrigatória nos dois modos. É ela que mantém a conexão com o WhatsApp, valida a
licença, autoriza cada chamada e emite os eventos. O serviço de mídia nunca recebe a sessão
do WhatsApp, o token da instância nem a chave de assinatura da API: ele só executa a mídia
que a API autorizou.

Escolha o modo na API quando o seu sistema é que fala: discador automático, atendimento por
software, gravação, integração com um agente externo. Escolha o modo com serviço de mídia
quando pessoas atendem ao telefone e você quer dar a elas um aplicativo com discador, fila e
histórico.

## Modo na API

Nada além da API é instalado. Em cada sessão:

1. Ligue as chamadas com `PUT /call/config`, no campo `callsEnabled`, e **reconecte a
   sessão**. A configuração passa a valer na reconexão seguinte. A exceção é `callRecord`,
   que a sessão em andamento aplica na hora.
2. Escolha o modo de entrada em `callInboundMode`:
   - `webhook` (padrão) — o gateway atende sozinho e emite os eventos de ciclo de vida;
   - `manual` — o seu sistema atende e controla pela API, e troca o áudio pelo WebSocket;
   - `reject` — o motor de chamadas fica desligado;
   - `bot`, `ivr` e `ai` são aceitos na configuração, mas **recusam** as chamadas recebidas:
     não existe agente de voz embutido, e preencher URLs de fala ou de modelo não o habilita.
     Para esse tipo de automação, use `manual` e processe o PCM no seu serviço.
3. Chame por `POST /call/dial`. A rota antiga `POST /call/initiate` responde `501` por
   padrão e só se torna um apelido de `dial` com `GLOBAL_CALL_INITIATE_DIAL_ALIAS=true`.

Os três guias técnicos detalham o resto, e esta página não os repete:

| Guia | O que cobre |
|---|---|
| [Áudio de chamadas](call-audio-implementation-guide.md) | Controle por REST, o WebSocket de PCM, reprodução e gravação |
| [Vídeo de chamadas](call-video-guide.md) | H.264 Annex-B, codecs no cliente e os limites do vídeo |
| [Integração de chamadas no navegador](whatsapp-web-call-integration.md) | Fluxos de integração, configuração por sessão e o desenho antigo, hoje histórico |

O guia completo para assistentes e geradores de código fica em [`/api/llm.txt`](../api/llm.txt).

## Modo com serviço de mídia

> **Disponibilidade.** A partir da 2.5.0, os quatro componentes deste modo são distribuídos:
> a imagem do serviço de mídia (`setupautomatizado/zuckzapgo-callworker`), a ferramenta de
> provisão, que vem dentro da imagem da API, e o aplicativo do atendente para macOS e Windows
> e o SDK de chamadas, na release do repositório de apoio. O passo a passo, da instalação à
> primeira ligação, está em [Chamadas com serviço de mídia: instalação](calls-media-install.md).
> Este modo é **Beta** nesta versão — serviço de mídia, aplicativo do atendente no macOS e no
> Windows, e SDK —, e o aplicativo para Windows ainda não foi testado numa máquina Windows.
> Esta seção explica como o modo funciona e o que ele exige.

### Componentes

| Componente | Onde roda | Papel |
|---|---|---|
| API (gateway) | onde já roda hoje | Conexão com o WhatsApp, licença, autorização de cada chamada, fila, histórico e eventos |
| Porta de controle da API | dentro da API, numa porta nova | Canal privado por onde o serviço de mídia se registra e recebe ordens |
| Banco de autoridade | um banco separado do banco da aplicação | Guarda as provas de vínculo, de permissão e de encerramento, de forma independente |
| Serviço de mídia | um processo Linux próprio, um por sessão | Carrega o áudio. Abre uma porta HTTPS e uma faixa UDP para o navegador e o aplicativo |
| SDK de chamadas | no seu aplicativo ou na sua página | Cliente do contrato: vínculo, fila, comandos, eventos e mídia |
| Aplicativo do atendente | no computador do atendente | Discador, fila, histórico e gestão, usando o SDK |

### Requisitos

**Na API:**

- Um arquivo de configuração **privado**, em JSON, apontado pela variável
  `GLOBAL_CALLS_API_CONFIG_FILE`. Vazio — o padrão — mantém o modo na API. Preenchido, o
  arquivo precisa ter caminho absoluto, ser um arquivo comum, não ser um link simbólico e
  ter permissão `0600`. Se ele estiver inválido, ou se as chaves, o schema ou a conexão
  falharem, **o gateway não sobe**: é falha fechada, de propósito. Nenhum endereço de banco
  ou segredo aparece na mensagem de erro.
- Um **banco de autoridade separado** do banco da aplicação. O endereço de conexão fica num
  arquivo próprio, também `0600`. Apontar o mesmo endereço do banco da aplicação é recusado.
- Dois segredos de 32 bytes, em arquivos distintos e também `0600`: a semente de assinatura
  e a chave de cursor. Se você rotacionar chaves, cabem até três chaves públicas anteriores,
  de 32 bytes cada, em arquivos próprios.
- As origens exatas que podem falar com a API, listadas uma por uma. Não há curinga, `null`,
  equivalência entre portas nem redirecionamento.
- Uma **porta de controle**, declarada no bloco `control` do mesmo arquivo. Ela atende em
  TLS 1.3 e multiplexa, no mesmo número de porta, o canal do serviço de mídia e o registro
  inicial. Precisa de uma autoridade certificadora própria (certificado e chave de
  assinatura) e de um certificado de servidor. No bloco também ficam o endereço HTTPS
  público de cada serviço de mídia, a política de ICE, o máximo de chamadas simultâneas e o
  máximo de streams de eventos.

**No serviço de mídia:**

- Um arquivo de configuração `0600` com a identidade do worker, o endereço da porta de
  controle da API, a autoridade certificadora dessa porta, os caminhos da chave, do
  certificado e do diário, e o limite de chamadas simultâneas (de 1 a 1024, nunca acima do
  que a API autorizou).
- Um segundo arquivo `0600` com a configuração de mídia: a origem HTTPS pública do serviço,
  a porta em que ele escuta, o certificado e a chave TLS dessa origem, as chaves públicas da
  API, as origens aceitas, a política de ICE e a faixa de portas UDP.
- Um volume persistente e exclusivo, com permissão `0700`, para a chave, o certificado e o
  diário. Um diário só abre num sistema de arquivos local admitido: `ext4`, `xfs`, `btrfs`,
  `zfs`, `tmpfs` ou `overlay`. NFS, FUSE e pasta compartilhada são recusados.
- **Um serviço de mídia por sessão**, com o seu próprio volume. Nunca dois processos sobre o
  mesmo diário, e nunca o mesmo volume em duas máquinas.

**Portas e rede do serviço de mídia:**

| Sentido | Porta | Para quê |
|---|---|---|
| Entrada, TCP | a porta que o serviço escuta (`9443` nos exemplos) | HTTPS de mídia. O navegador e o aplicativo falam direto com ele. É a única porta TCP que ele abre. |
| Entrada e saída, UDP | a faixa configurada (`40000-40100` nos exemplos) | Mídia WebRTC. Cada chamada consome portas da faixa; deixe folga. |
| Saída, TCP | a porta de controle da API | Registro, ordens e envio das provas de encerramento. |
| Saída, UDP e TCP | os servidores STUN/TURN, se você configurar | Só quando a sua rede exige. |

O TLS de mídia termina **no próprio serviço de mídia**. Um proxy na frente dele precisa
repassar o TCP sem abrir o TLS, e o certificado tem de corresponder à origem pública
registrada na API. Em contêiner, a faixa UDP precisa chegar com os mesmos números de porta:
em Linux, use a rede do host; em rede isolada, publique a faixa um para um e configure STUN
ou TURN. Não existe opção de IP público no serviço de mídia, então os endereços que ele
anuncia são os das interfaces que ele enxerga.

Cada arquivo, campo a campo e com exemplos completos, está no
[guia de instalação do modo](calls-media-install.md).

### Sequência de implantação

A ordem importa: cada passo depende do anterior.

1. **Gere as chaves e a configuração.** A ferramenta de provisão, que vem na imagem da API
   (`/app/callsprovision -init-files`), gera os **dois** segredos de 32 bytes — a semente de
   assinatura e a chave de cursor —, os certificados da porta de controle e o arquivo de
   configuração completo, em arquivos `0600` fora da imagem. Crie o banco de autoridade
   separado e escreva o endereço dele num arquivo próprio.
2. **Aponte `GLOBAL_CALLS_API_CONFIG_FILE`** para o arquivo gerado.
3. **Prepare o schema e registre o controlador.** Isso é feito uma única vez, pela mesma
   ferramenta de provisão. Ela cria o schema do banco de autoridade e o do banco da
   aplicação, registra o controlador e abre a época configurada. Uma segunda execução sobre
   os mesmos bancos é recusada de propósito.
4. **Vincule a sessão ao modo remoto** e emita, também pela provisão, a **credencial única**
   de registro do serviço de mídia. Ela sai num arquivo novo `0600` e o segredo nunca
   aparece na saída do comando. Ela vale 10 minutos e aceita no máximo 5 tentativas: deixe o
   serviço de mídia configurado antes de emiti-la.
5. **Suba o serviço de mídia uma vez com essa credencial.** Ele gera a chave local, grava o
   pedido de certificado no volume e se registra na porta de controle. Confirme que o
   certificado foi emitido.
6. **Libere o worker para a sessão**, pela provisão. Antes do registro, a liberação é
   recusada com a mensagem de que o worker ainda não se registrou.
7. **Apague a credencial de registro dos dois lados** e suba o serviço normalmente. Os
   reinícios seguintes usam a chave e o certificado do volume, sem credencial nova.
8. **Reconecte a sessão do WhatsApp.** A escolha entre o modo na API e o modo com serviço de
   mídia acontece na conexão da sessão. Trocar a configuração não troca um motor já
   conectado: a resposta diz `session_reconnect_required`.

Se o registro falhar no meio, o volume guarda a mesma chave e o mesmo pedido de certificado:
repita o passo 5 com o **mesmo volume**. Não apague o volume e não emita outra credencial
para contornar um resultado incerto — essa é a regra geral do modo, e vale também para
encerramentos e cortes.

### Como um aparelho do atendente é liberado

O aplicativo do atendente **nunca recebe o token da API**. Ele recebe apenas uma credencial
curta, emitida para aquele aparelho e aquela pessoa:

1. O aplicativo pede os dados iniciais à API e gera, na própria máquina, um par de chaves e
   um desafio.
2. Ele registra um pedido de vínculo e mostra um **código** ao atendente. O código em texto
   claro é entregue uma única vez; uma segunda consulta não o devolve.
3. Uma pessoa autorizada da sua equipe abre a tela de aprovação, já autenticada na sua
   instância, confere o rótulo do aparelho e a origem, e aprova usando aquele código.
4. Só depois da aprovação o aplicativo troca o pedido assinado por uma credencial curta e
   uma credencial de renovação. A renovação fica no cofre do sistema operacional do
   aparelho, nunca na interface.
5. O aparelho registra um ponto de atendimento e passa a renovar o seu prazo
   automaticamente. Um aparelho que dorme, perde a rede ou tem o prazo cortado é substituído
   sozinho, sem refazer o vínculo.

Para revogar um aparelho, a pessoa autorizada apaga a família de credenciais dele. A
revogação é assíncrona: a resposta traz uma operação a acompanhar, e `pending` não significa
que o corte já se completou do outro lado.

### Papéis

| Papel | O que pode |
|---|---|
| Atendente | As chamadas em que atuou e os próprios pontos de atendimento. Pode sair e revogar a própria credencial. |
| Supervisor | Lê a gestão da instância e pode suspender a entrada de chamadas num serviço de mídia. Revoga apenas a própria credencial. |
| Administrador de chamadas | Lê a gestão, configura o runtime e revoga serviços de mídia e credenciais da instância. |
| Administrador da instância | O acesso administrativo que você já tem, com o token da instância, continua valendo. |

Nenhum desses papéis recebe o token da instância ou o token administrativo. Trocar o papel
escrito na credencial não concede permissão: quem decide é a API.

### Limites deste modo

Confirmados no código desta versão, e informados pela própria API no campo de capacidades:

| Recurso | Estado |
|---|---|
| Áudio de uma pessoa para outra | Disponível, quando há serviço de mídia registrado para a sessão |
| Vídeo | **Indisponível.** `POST /call/dial` com `video: true` responde `422` com `media_unsupported` |
| Áudio e vídeo em grupo | **Indisponível** neste modo (`media_unsupported`) |
| Gravação | **Indisponível** neste modo: a API publica `recording_unavailable` nas capacidades, e `POST /call/record/start` responde `409` com `remote_media_direct_required` e encerra a chamada |
| Ponte SIP ou PABX | Não existe em nenhum modo |

Vídeo, grupos e gravação continuam disponíveis no **modo na API**, cada um com as suas
próprias condições. As telas do aplicativo do atendente podem mostrar vídeo e grupos, mas o
efeito depende destes limites.

Sobre mídia local, para não haver dúvida: neste modo o áudio não termina no gateway. Numa
chamada deste modo, `POST /call/play`, `POST /call/record/start` e a abertura dos streams de
áudio (`GET /call/{call_id}/stream`) e de vídeo (`GET /call/{call_id}/video/stream`) respondem
`409` com `reason: remote_media_direct_required`, e a chamada é **encerrada**, como o próprio
runtime de chamadas faz. Grave e troque áudio pelo **modo na API**.

## As rotas `/call/*` nos dois modos

Uma pergunta frequente: uma sessão configurada para o modo com serviço de mídia continua
aceitando as rotas `/call/*`? **Sim, as rotas continuam existindo** — e o que muda é quem
responde, decidido pelo cabeçalho que você manda.

| O que você manda | Quem atende | Resultado |
|---|---|---|
| Cabeçalho `Authorization` presente | O caminho delegado do modo com serviço de mídia | `202` com um identificador de comando a acompanhar |
| Somente o cabeçalho `token` da sessão | O caminho do modo na API | Veja a tabela abaixo |

Com o cabeçalho `token` da sessão, numa sessão vinculada ao modo com serviço de mídia:

| Rota | Comportamento |
|---|---|
| `POST /call/dial` | Recusada, com `502` e a mensagem de que o controle delegado é obrigatório |
| `POST /call/answer` | Recusada, com `400` e a mesma mensagem |
| `POST /call/hangup`, `POST /call/reject`, `GET /call/status`, `/call/record/stop`, as rotas de estado e de estatística do vídeo, de grupo, de link e de sala de espera | Continuam no caminho do modo na API, sem recusa de controle delegado |
| `POST /call/play`, `POST /call/record/start`, `GET /call/{call_id}/stream` e `GET /call/{call_id}/video/stream` | `409` com `reason: remote_media_direct_required`: a mídia desta chamada não passa pelo gateway, e a chamada é encerrada |

Duas consequências práticas:

- **Discar e atender passam a ser do aplicativo**, não do seu backend. Para discar e atender
  por software nessa sessão, use as rotas delegadas com a credencial do aparelho.
- **Qualquer valor no cabeçalho `Authorization` desvia a chamada** para o caminho delegado,
  porque é esse cabeçalho que seleciona a rota. Se você quer o modo na API, mande somente
  o cabeçalho `token` nas rotas `/call/*`.

Além disso, uma sessão vinculada ao modo com serviço de mídia atende **sempre em modo
manual**, qualquer que seja o valor gravado em `callInboundMode`: o gateway não atende
sozinho, e a chamada recebida espera o aparelho do atendente.

## Onde continuar

| Assunto | Onde |
|---|---|
| Instalação do modo com serviço de mídia, passo a passo | [Chamadas com serviço de mídia: instalação](calls-media-install.md) |
| Variáveis de ambiente de chamadas | [Configuração](CONFIGURATION.md) |
| Instalação do gateway | [Instalação](INSTALL.md) |
| Eventos de chamada no webhook | [Eventos e webhooks](webhook-events.md) |
| Guia completo para assistentes | [`/api/llm.txt`](../api/llm.txt) |
| Contrato das operações | [OpenAPI](../api/spec.yml) |
