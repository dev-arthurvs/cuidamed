// Conteúdo central do guia de ajuda: usado tanto na página /ajuda (guia completo)
// quanto no botão "?" contextual do Cabecalho (mostra só a seção da tela atual).

export const GUIA_SECOES = [
  {
    chave: 'inicio-paciente',
    publico: 'paciente',
    titulo: 'Início (painel do paciente)',
    paraQueServe:
      'É a tela principal quando você entra no sistema. Mostra quantas doses faltam hoje, qual é o próximo remédio e um resumo rápido do seu dia.',
    passos: [
      'Se aparecer a faixa azul no topo, clique em "Ativar" para receber som e notificação na hora de cada remédio.',
      'O card "Doses de hoje" mostra no meio, em letra grande, a dose da vez. Quando tomar, clique em "Registrar dose".',
      'Registrou sem querer? Clique em "Desfazer" logo depois, ou volte até a dose tomada e clique em "Desfazer". Dá para desfazer as doses de hoje.',
      'Se algum remédio estiver acabando, o card "Estoque acabando" aparece nesta tela.',
      'Em cima fica a dose anterior: verde com ✓ se foi tomada, vermelha e riscada com ✕ se foi perdida. Embaixo fica a próxima dose.',
      'Para ver as outras doses do dia, use as setas do card: ↑ no canto de cima e ↓ no canto de baixo.',
      'Os números embaixo mostram quantas doses já foram tomadas, quantas faltam e quantas estão atrasadas.',
      'O botão azul flutuante no canto inferior direito abre o Chat com o assistente, em qualquer tela do sistema.',
      'A lista "Agenda de hoje" no final mostra todos os horários do dia, em ordem.',
    ],
  },
  {
    chave: 'inicio-cuidador',
    publico: 'cuidador',
    titulo: 'Início (painel do cuidador)',
    paraQueServe:
      'É a tela principal do cuidador. Mostra um resumo de todos os pacientes vinculados a você e permite gerenciar pedidos de vínculo.',
    passos: [
      'Os cards no topo mostram quantos pacientes você acompanha, quantos precisam de atenção e a adesão média aos remédios.',
      'Se aparecer "Solicitações pendentes", é porque um paciente pediu para se vincular a você — clique em "Aceitar" ou "Recusar".',
      'Clique em qualquer paciente da lista "Pacientes vinculados" para abrir os detalhes dele.',
      'Use o botão "+ Cadastrar paciente" para registrar um novo paciente que ainda não tem conta própria. Preencha o telefone dele se quiser poder mandar lembretes de dose pelo WhatsApp depois.',
      'Depois de cadastrar, abra os detalhes do paciente para ver o código de ativação: é com ele (e o e-mail ou telefone cadastrado) que o paciente cria a própria senha em "Ativar meu acesso".',
    ],
  },
  {
    chave: 'detalhes-paciente',
    publico: 'cuidador',
    titulo: 'Detalhes do paciente',
    paraQueServe:
      'Mostra as informações de um paciente específico: doses de hoje, adesão e ações rápidas para gerenciá-lo.',
    passos: [
      'Veja as doses de hoje e o percentual de adesão dos últimos 30 dias no topo.',
      'Use "Lembrar agora 🔔" para mandar um alerta imediato para o paciente (som + notificação), a qualquer momento.',
      'Use "Ver histórico de doses" para consultar todas as doses já registradas.',
      'Use "Acessar agenda" para adicionar, editar ou remover remédios da agenda do paciente. Os remédios cujo tratamento já terminou ficam lá, na aba "Encerrados".',
      'Ao lado do status de cada dose em "Doses de hoje", use o ícone verde de telefone para mandar um lembrete pelo WhatsApp direto pro paciente. Só aparece pra doses ainda não tomadas, e fica desabilitado se o paciente não tiver telefone cadastrado.',
      'O card "Permite alterações" define se o paciente pode adicionar, editar ou excluir os próprios remédios. Desligado por padrão.',
      'Use "Desvincular paciente" se quiser parar de acompanhar esse paciente. Se ele não tiver e-mail, telefone ou senha próprios, o sistema avisa antes de confirmar.',
      'Se o paciente esqueceu a senha, toque em "Gerar código de nova senha" no card "Acesso do paciente" e passe o código a ele. O código vale por 24 horas.',
      'A adesão considera os últimos 30 dias, e doses que passaram do limite sem registro contam como perdidas.',
      'Se o paciente ainda não ativou o acesso ao app, o card "Acesso do paciente" mostra o código de ativação. Passe esse código para ele usar em "Ativar meu acesso", junto com o e-mail ou telefone cadastrado. Depois de usado, o card some.',
      'No card "Observações clínicas", escreva informações importantes (alergias, cuidados ao tomar os remédios) e clique em "Salvar observações". O assistente do chat também usa essas observações para responder o paciente.',
    ],
  },
  {
    chave: 'agenda',
    publico: 'ambos',
    titulo: 'Agenda de medicamentos',
    paraQueServe:
      'É onde ficam os remédios, com nome, forma, frequência e horários, em duas abas: "Em uso" (o tratamento atual) e "Encerrados" (remédios cujo tratamento já terminou). Cuidadores veem a agenda do paciente selecionado; pacientes veem a própria.',
    passos: [
      'Se você é cuidador, escolha de qual paciente ver a agenda pelo menu do topo (passe o mouse ou clique em "Agenda" e selecione o paciente) ou pelo botão "Acessar agenda" nos detalhes do paciente.',
      'Clique em "+ Inserir medicamento" para cadastrar um novo remédio: preencha nome, forma (comprimido, gotas, etc.), frequência e os horários do dia.',
      'Em cada card já cadastrado, use "Editar" para mudar alguma informação ou "Excluir" para remover.',
      'Quando o tratamento termina, o remédio passa sozinho de "Em uso" para "Encerrados": assim que a última dose é confirmada (mesmo no próprio dia da data final) ou, o mais tardar, no dia seguinte.',
      'Na aba "Encerrados" você consulta o período em que cada remédio foi usado (data de início até data de fim). Ali não dá para editar nem excluir.',
      'Cada card mostra o estoque do remédio: suficiente até o fim do tratamento (verde), baixo (amarelo, hora de repor) ou esgotado (vermelho).',
      'Se você é paciente e não vê os botões de inserir/editar/excluir, é porque seu cuidador ainda não liberou essa permissão para você — fale com ele.',
      'Se você é cuidador, use "‹ Voltar para os detalhes do paciente" no topo para voltar aos detalhes do paciente.',
    ],
  },
  {
    chave: 'historico',
    publico: 'ambos',
    titulo: 'Histórico de doses',
    paraQueServe: 'Mostra o registro de todas as doses já passadas: quais foram tomadas, atrasadas ou perdidas. (Os remédios que já terminaram ficam na Agenda, aba "Encerrados".)',
    passos: [
      'Se você é cuidador, escolha o paciente pelo menu do topo (passe o mouse ou clique em "Histórico de doses") ou pelo botão "Ver histórico de doses" nos detalhes do paciente.',
      'Escolha o período nos campos "De" e "Até" (começam no dia de hoje). Não dá para escolher datas futuras.',
      'Use o filtro "Medicamento" para ver o histórico de um remédio específico.',
      'Os três números no topo resumem quantas doses foram tomadas, atrasadas e perdidas no período escolhido.',
      'A lista abaixo mostra cada dose, organizada por dia, da mais recente para a mais antiga.',
      'Use "Gerar relatório (PDF)" para imprimir ou salvar o período escolhido e levar ao médico.',
      'Se você é cuidador, use "‹ Voltar para os detalhes do paciente" no topo para voltar aos detalhes do paciente.',
    ],
  },
  {
    chave: 'chat',
    publico: 'paciente',
    titulo: 'Chat com o assistente',
    paraQueServe:
      'Um assistente virtual que responde sobre os seus remédios (horários, estoque, próxima dose e histórico) e explica como usar o sistema.',
    passos: [
      'Clique em uma das perguntas sugeridas para enviar direto, sem precisar digitar.',
      'Ou digite sua pergunta no campo de texto e clique em "Enviar".',
      'O assistente responde sobre os seus próprios medicamentos e sobre como usar o sistema. Ele não registra doses, não altera nada, não dá conselhos médicos e não opina sobre outros assuntos.',
      'Se a pergunta for sobre saúde em geral, ele vai pedir para você falar com seu médico ou cuidador.',
      'Há um limite de perguntas por hora e por dia. Se aparecer o aviso de limite, espere um pouco e pergunte de novo.',
    ],
  },
  {
    chave: 'perfil',
    publico: 'ambos',
    titulo: 'Configurações',
    paraQueServe:
      'Reúne seus dados pessoais, a troca de senha, a aparência do sistema (tamanho da fonte e tema claro ou escuro) e (se você for paciente) o vínculo com o cuidador.',
    passos: [
      'Atualize nome, e-mail e outros dados no card "Dados pessoais" e clique em "Salvar alterações".',
      'Se você é paciente, cadastre seu telefone com DDD — é ele que o cuidador usa pra mandar lembretes de dose pelo WhatsApp.',
      'Para trocar a senha, preencha a senha atual e a nova senha (mínimo 8 caracteres) e clique em "Atualizar senha".',
      'No card "Aparência", escolha o tamanho da fonte (Pequena, Média ou Grande) e o tema (Claro ou Escuro). A escolha vale na hora, em todo o sistema.',
      'Se você é paciente sem cuidador vinculado, informe o e-mail ou telefone do cuidador no card "Vincular cuidador(a)" — ele precisa confirmar o pedido antes do vínculo valer.',
      'Use "Sair da conta" para fazer logout.',
    ],
  },
  {
    chave: 'acessibilidade',
    publico: 'ambos',
    titulo: 'Ajuda e acessibilidade',
    paraQueServe:
      'Esta própria tela: um guia com todas as telas do sistema (clique em uma para ver como usá-la) e o controle de tamanho da fonte.',
    passos: [
      'Clique em uma das telas listadas para ver, na hora, para que ela serve e o passo a passo de uso.',
      'Use os botões "Pequena", "Média" ou "Grande" para ajustar o tamanho do texto em todo o sistema.',
      'Você também pode clicar no botão "?" no topo de qualquer tela para ver só a ajuda daquela tela específica.',
    ],
  },
]

export function obterChaveAjuda(pathname, tipoUsuario) {
  if (/^\/cuidador\/paciente\//.test(pathname)) return 'detalhes-paciente'
  if (pathname === '/painel') return tipoUsuario === 'cuidador' ? 'inicio-cuidador' : 'inicio-paciente'
  if (pathname.startsWith('/agenda')) return 'agenda'
  if (pathname.startsWith('/historico')) return 'historico'
  if (pathname.startsWith('/configuracoes')) return 'perfil'
  if (pathname.startsWith('/chat')) return 'chat'
  if (pathname.startsWith('/acessibilidade')) return 'acessibilidade'
  return null
}

export function obterSecaoAjuda(pathname, tipoUsuario) {
  const chave = obterChaveAjuda(pathname, tipoUsuario)
  return GUIA_SECOES.find((secao) => secao.chave === chave) || null
}
