# 📋 Changelog

Todas as mudanças importantes neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).


## [v1.2.2] - 2025-07-27

### 🚀 Novos Recursos

#### 🎯 Mensagens Interativas
- ✅ **Botões Interativos**: Suporte completo para mensagens com botões
  - Quick reply (resposta rápida)
  - Copy (copiar código/texto)
  - URL (links externos)
  - Call (ligação)
  - PIX (pagamentos)
- ✅ **Mensagens de Lista**: Suporte para single select
- ✅ **Novos Endpoints**: `/chat/send/buttons`, `/chat/send/list`

#### 💬 Gerenciamento Avançado de Chat
- ✅ **Pin/Unpin**: Fixar e desfixar conversas importantes
- ✅ **Arquivamento**: Arquivar e desarquivar conversas
- ✅ **Silenciamento**: Silenciar chats por períodos (8h, 1 semana, sempre)
- ✅ **Favoritos**: Marcar/desmarcar mensagens com estrela
- ✅ **Sistema de Labels**: Gerenciamento completo de etiquetas
  - Editar labels existentes
  - Aplicar em chats e mensagens
  - Organização inteligente

#### 🔒 Privacidade e Segurança
- ✅ **Configurações de Privacidade**: Controle total sobre visibilidade
- ✅ **Timer de Mensagens**: Configurar mensagens temporárias
- ✅ **Lista de Bloqueados**: Gerenciar contatos bloqueados
- ✅ **Privacidade de Status**: Controlar quem vê seus status
- ✅ **Configurações Avançadas**: Todas as opções de privacidade do WhatsApp

#### 👥 Comunidades WhatsApp
- ✅ **Criação de Comunidades**: Criar e gerenciar comunidades
- ✅ **Vinculação de Grupos**: Conectar grupos às comunidades
- ✅ **Anúncios**: Enviar anúncios para toda a comunidade
- ✅ **Administração**: Sistema completo de moderação
- ✅ **Solicitações**: Gerenciar pedidos de entrada

#### 💼 Recursos Business
- ✅ **Links Business**: Resolver links de mensagens business
- ✅ **QR Code de Contato**: Gerar QR codes para contatos
- ✅ **Gerenciamento de Bots**: Listar e configurar bots
- ✅ **Perfis de Bots**: Informações detalhadas de bots
- ✅ **Mensagens de Pedido**: Enviar mensagens de pedido (order message)

#### 📱 Gerenciamento de Dispositivos
- ✅ **Listagem de Dispositivos**: Ver todos os dispositivos conectados
- ✅ **Dispositivos Vinculados**: Identificar dispositivos do usuário
- ✅ **Identificação de Plataforma**: Detectar sistema operacional
- ✅ **Consultas Contextuais**: Buscas avançadas com contexto

### 🛠️ Melhorias Técnicas

#### 🔧 Painel Administrativo
- ✅ **Avatares de Usuários**: Exibição de fotos de perfil
- ✅ **Método Interno**: `getAvatarInternal()` para busca eficiente
- ✅ **Informações Completas**: Listagem aprimorada de usuários
- ✅ **Status de Conexão**: Indicadores visuais de conectividade

#### 📊 Constantes e Validações
- ✅ **Tipos de Eventos**: Novos eventos suportados
- ✅ **Mapa de Eventos**: Validação rápida e eficiente
- ✅ **Função de Validação**: `isValidEventType()` para verificações

#### 🔗 Helpers e Utilitários
- ✅ **Processamento de Mídia**: Novos helpers para mídia
- ✅ **Mensagens Interativas**: Funções auxiliares especializadas
- ✅ **Sistema de Callbacks**: Melhorias nos webhooks

#### 🛣️ Rotas e Endpoints
- ✅ **35+ Novas Rotas**: Endpoints RESTful adicionados
- ✅ **Organização por Domínio**: Estrutura clara e lógica
  - `/chat/*` - Operações de chat
  - `/privacy/*` - Configurações de privacidade
  - `/community/*` - Gerenciamento de comunidades
  - `/business/*` - Recursos business
  - `/device/*` - Gerenciamento de dispositivos

#### 📤 Handlers de Envio
- ✅ **SendButtonsMessage()**: Implementação completa
- ✅ **SendListMessage()**: Suporte total para listas
- ✅ **SendCarouselMessage()**: Mensagens em carrossel
- ✅ **Validações Robustas**: Tratamento de erros aprimorado

### 📦 Novos Serviços

#### 🏭 Factory de Mensagens
- ✅ **create_buttons_message_service.go**
  - Factory pattern para criação de botões
  - Suporte para 6 tipos diferentes
  - Validações de limites e formatos
  - Suporte para mídia no header

- ✅ **create_list_message_service.go**
  - Factory para mensagens de lista
  - Múltiplas seções suportadas
  - Validações de tamanho e conteúdo

### 📈 Estatísticas da Versão

| Categoria | Quantidade |
|-----------|------------|
| **Novos Handlers** | 9 arquivos |
| **Novos Endpoints** | 35+ rotas |
| **Novos Serviços** | 3 serviços |
| **Novas Funções** | 100+ funções |
| **Recursos WhatsApp** | Completo |

### 🔄 Compatibilidade

- ✅ **Sem Breaking Changes**: Total compatibilidade com versões anteriores
- ✅ **APIs Existentes**: Todas as funcionalidades anteriores mantidas
- ✅ **Configurações**: Compatibilidade total com configurações existentes

### 📚 Documentação

- ✅ **CHANGELOG.md**: Atualizado com todas as mudanças
- ✅ **Dockerfile**: Melhorias na imagem Docker
- ✅ **docker-compose**: Configurações atualizadas
- ✅ **API Spec**: Documentação da API atualizada
- ✅ **Postman**: Coleção atualizada
- ✅ **Dashboard**: Interface HTML melhorada

## 📊 Estatísticas

- **Total de commits**: 64
- **Período**: 2025-06-11 até 2025-07-13

### 👥 Principais Contribuidores

- **Guilherme Jansen**: 52 commit(s)
- **GitHub Action**: 10 commit(s)
- **GitHub Actions Bot**: 2 commit(s)

### 🔗 Links Úteis

- [🚀 GitHub Repository](https://github.com/guilhermejansen/use-zuckzapgo)
- [🐳 Docker Hub](https://hub.docker.com/r/setupautomatizado/zuckzapgo-private)
- [📖 Documentação](https://github.com/guilhermejansen/use-zuckzapgo/blob/main/README.md)
- [🆘 Suporte](mailto:contato@setupautomatizado.com.br)

