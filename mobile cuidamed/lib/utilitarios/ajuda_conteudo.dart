/// Conteúdo do guia de ajuda — porta de front-end cuidamed/src/utilitarios/ajudaConteudo.js,
/// com os passos ajustados ao que existe no app (toque, barra inferior, menu).
/// Usado na tela de Acessibilidade (guia completo) e no botão "?" do cabeçalho
/// (só a seção da tela atual).
class SecaoAjuda {
  final String chave;
  final String publico; // 'paciente' | 'cuidador' | 'ambos'
  final String titulo;
  final String paraQueServe;
  final List<String> passos;

  const SecaoAjuda({
    required this.chave,
    required this.publico,
    required this.titulo,
    required this.paraQueServe,
    required this.passos,
  });

  bool visivelPara(String tipoUsuario) => publico == 'ambos' || publico == tipoUsuario;
}

const List<SecaoAjuda> guiaSecoes = [
  SecaoAjuda(
    chave: 'inicio-paciente',
    publico: 'paciente',
    titulo: 'Início (painel do paciente)',
    paraQueServe:
        'É a tela principal quando você entra no aplicativo. Mostra quantas doses faltam hoje, qual é o próximo remédio e um resumo rápido do seu dia.',
    passos: [
      'O card "Doses de hoje" mostra no meio, em letra grande, a dose da vez. Quando tomar, toque em "Registrar dose".',
      'Registrou sem querer? Toque em "Desfazer" no aviso que aparece por alguns segundos, ou volte até a dose tomada e toque em "Desfazer". Dá para desfazer as doses de hoje.',
      'Se algum remédio estiver acabando, o card "Estoque acabando" aparece nesta tela.',
      'Em cima fica a dose anterior: verde com ✓ se foi tomada, vermelha e riscada com ✕ se foi perdida. Embaixo fica a próxima dose.',
      'Para ver as outras doses do dia, use as setas do card: ↑ no canto de cima e ↓ no canto de baixo.',
      'Os números embaixo mostram quantas doses já foram tomadas, quantas faltam e quantas estão atrasadas.',
      'A lista "Agenda de hoje" no final mostra todos os horários do dia, em ordem.',
      'Puxe a tela para baixo para atualizar as informações.',
    ],
  ),
  SecaoAjuda(
    chave: 'inicio-cuidador',
    publico: 'cuidador',
    titulo: 'Início (painel do cuidador)',
    paraQueServe:
        'É a tela principal do cuidador. Mostra um resumo de todos os pacientes vinculados a você e permite gerenciar pedidos de vínculo.',
    passos: [
      'Os cards no topo mostram quantos pacientes você acompanha, quantos precisam de atenção e a adesão média aos remédios.',
      'Se aparecer "Solicitações pendentes", é porque um paciente pediu para se vincular a você — toque em "Aceitar" ou "Recusar".',
      'Toque em qualquer paciente da lista "Pacientes vinculados" para abrir os detalhes dele.',
      'Use o botão "+ Cadastrar paciente" para registrar um novo paciente que ainda não tem conta própria. Preencha o telefone dele se quiser poder mandar lembretes de dose pelo WhatsApp depois.',
      'Depois de cadastrar, abra os detalhes do paciente para ver o código de ativação: é com ele (e o e-mail ou telefone cadastrado) que o paciente cria a própria senha em "Ativar meu acesso".',
    ],
  ),
  SecaoAjuda(
    chave: 'detalhes-paciente',
    publico: 'cuidador',
    titulo: 'Detalhes do paciente',
    paraQueServe: 'Mostra as informações de um paciente específico: doses de hoje, adesão e ações rápidas para gerenciá-lo.',
    passos: [
      'Veja as doses de hoje e o percentual de adesão dos últimos 30 dias no topo.',
      'Use "Lembrar agora 🔔" para mandar um alerta imediato para o paciente, a qualquer momento.',
      'Use "Ver histórico de doses" para consultar todas as doses já registradas.',
      'Use "Acessar agenda" para adicionar, editar ou remover remédios da agenda do paciente. Os remédios cujo tratamento já terminou ficam lá, na aba "Encerrados".',
      'Ao lado do status de cada dose em "Doses de hoje", use o ícone verde de telefone para mandar um lembrete pelo WhatsApp direto pro paciente. Só aparece pra doses ainda não tomadas, e fica desabilitado se o paciente não tiver telefone cadastrado.',
      'O card "Permite alterações" define se o paciente pode adicionar, editar ou excluir os próprios remédios. Desligado por padrão.',
      'Use "Desvincular paciente" se quiser parar de acompanhar esse paciente. Se ele não tiver e-mail, telefone ou senha próprios, o aplicativo avisa antes de confirmar.',
      'Se o paciente esqueceu a senha, toque em "Gerar código de nova senha" no card "Acesso do paciente" e passe o código a ele. O código vale por 24 horas.',
      'A adesão considera os últimos 30 dias, e doses que passaram do limite sem registro contam como perdidas.',
      'Se o paciente ainda não ativou o acesso ao app, o card "Acesso do paciente" mostra o código de ativação. Passe esse código para ele usar em "Ativar meu acesso", junto com o e-mail ou telefone cadastrado. Depois de usado, o card some.',
      'No card "Observações clínicas", escreva informações importantes (alergias, cuidados ao tomar os remédios) e toque em "Salvar observações". O assistente do chat também usa essas observações para responder o paciente.',
    ],
  ),
  SecaoAjuda(
    chave: 'agenda',
    publico: 'ambos',
    titulo: 'Agenda de medicamentos',
    paraQueServe:
        'É onde ficam os remédios, com nome, forma, frequência e horários, em duas abas: "Em uso" (o tratamento atual) e "Encerrados" (remédios cujo tratamento já terminou). Cuidadores veem a agenda do paciente selecionado; pacientes veem a própria.',
    passos: [
      'Se você é cuidador e abriu a agenda pela barra inferior, escolha primeiro o paciente na lista. Pelos detalhes do paciente ("Acessar agenda"), ela abre direto.',
      'Toque em "+ Inserir medicamento" para cadastrar um novo remédio: preencha nome, forma (comprimido, gotas, etc.), frequência e os horários do dia.',
      'Em cada card já cadastrado, use "Editar" para mudar alguma informação ou "Excluir" para remover.',
      'Quando o tratamento termina, o remédio passa sozinho de "Em uso" para "Encerrados": assim que a última dose é confirmada (mesmo no próprio dia da data final) ou, o mais tardar, no dia seguinte.',
      'Na aba "Encerrados" você consulta o período em que cada remédio foi usado (data de início até data de fim). Ali não dá para editar nem excluir.',
      'Cada card mostra o estoque do remédio: suficiente até o fim do tratamento (verde), baixo (amarelo, hora de repor) ou esgotado (vermelho).',
      'Se você é paciente e não vê os botões de inserir/editar/excluir, é porque seu cuidador ainda não liberou essa permissão para você — fale com ele.',
      'Se você é cuidador, use "‹ Voltar para os detalhes do paciente" no topo para voltar aos detalhes do paciente.',
    ],
  ),
  SecaoAjuda(
    chave: 'historico',
    publico: 'ambos',
    titulo: 'Histórico de doses',
    paraQueServe:
        'Mostra o registro de todas as doses já passadas: quais foram tomadas, atrasadas ou perdidas. (Os remédios que já terminaram ficam na Agenda, aba "Encerrados".)',
    passos: [
      'Se você é cuidador e abriu pela barra inferior, escolha primeiro o paciente na lista. Pelos detalhes do paciente ("Ver histórico de doses"), abre direto.',
      'Escolha o período nos campos "De" e "Até" (começam no dia de hoje). Não dá para escolher datas futuras.',
      'Use o filtro "Medicamento" para ver o histórico de um remédio específico.',
      'Os três números no topo resumem quantas doses foram tomadas, atrasadas e perdidas no período escolhido.',
      'A lista abaixo mostra cada dose, organizada por dia, da mais recente para a mais antiga.',
      'Use "Gerar relatório (PDF)" para imprimir ou salvar o período escolhido e levar ao médico.',
      'Se você é cuidador, use "‹ Voltar para os detalhes do paciente" no topo para voltar aos detalhes do paciente.',
    ],
  ),
  SecaoAjuda(
    chave: 'chat',
    publico: 'paciente',
    titulo: 'Chat com o assistente',
    paraQueServe:
        'Um assistente virtual que responde sobre os seus remédios (horários, estoque, próxima dose e histórico) e explica como usar o aplicativo.',
    passos: [
      'Toque em uma das perguntas sugeridas para enviar direto, sem precisar digitar.',
      'Ou digite sua pergunta no campo de texto e toque em "Enviar".',
      'O assistente responde sobre os seus próprios medicamentos e sobre como usar o aplicativo. Ele não registra doses, não altera nada, não dá conselhos médicos e não opina sobre outros assuntos.',
      'Se a pergunta for sobre saúde em geral, ele vai pedir para você falar com seu médico ou cuidador.',
      'Há um limite de perguntas por hora e por dia. Se aparecer o aviso de limite, espere um pouco e pergunte de novo.',
    ],
  ),
  SecaoAjuda(
    chave: 'perfil',
    publico: 'ambos',
    titulo: 'Configurações',
    paraQueServe:
        'Reúne seus dados pessoais, a troca de senha, o tamanho da fonte e (se você for paciente) o vínculo com o cuidador.',
    passos: [
      'Atualize nome, e-mail e outros dados no card "Dados pessoais" e toque em "Salvar alterações".',
      'Se você é paciente, cadastre seu telefone com DDD — é ele que o cuidador usa pra mandar lembretes de dose pelo WhatsApp.',
      'Para trocar a senha, preencha a senha atual e a nova senha (mínimo 8 caracteres) e toque em "Atualizar senha".',
      'No card "Aparência", escolha o tamanho da fonte (Pequena, Média ou Grande). A escolha vale na hora, em todo o aplicativo.',
      'Se você é paciente sem cuidador vinculado, informe o e-mail ou telefone do cuidador no card "Vincular cuidador(a)" — ele precisa confirmar o pedido antes do vínculo valer.',
      'Use "Sair da conta" para fazer logout.',
    ],
  ),
  SecaoAjuda(
    chave: 'acessibilidade',
    publico: 'ambos',
    titulo: 'Ajuda e acessibilidade',
    paraQueServe:
        'Esta própria tela: um guia com todas as telas do aplicativo (toque em uma para ver como usá-la) e o controle de tamanho da fonte.',
    passos: [
      'Toque em uma das telas listadas para ver, na hora, para que ela serve e o passo a passo de uso.',
      'Use os botões "Pequena", "Média" ou "Grande" para ajustar o tamanho do texto em todo o aplicativo.',
      'Você também pode tocar no botão "?" no topo de qualquer tela para ver só a ajuda daquela tela específica.',
    ],
  ),
];

String? obterChaveAjuda(String rota, String tipoUsuario) {
  if (rota.startsWith('/cuidador/paciente/')) return 'detalhes-paciente';
  if (rota == '/painel') return tipoUsuario == 'cuidador' ? 'inicio-cuidador' : 'inicio-paciente';
  if (rota.startsWith('/agenda')) return 'agenda';
  if (rota.startsWith('/historico')) return 'historico';
  if (rota.startsWith('/configuracoes')) return 'perfil';
  if (rota.startsWith('/chat')) return 'chat';
  if (rota.startsWith('/acessibilidade')) return 'acessibilidade';
  return null;
}

SecaoAjuda? obterSecaoAjuda(String rota, String tipoUsuario) {
  final chave = obterChaveAjuda(rota, tipoUsuario);
  for (final secao in guiaSecoes) {
    if (secao.chave == chave) return secao;
  }
  return null;
}
