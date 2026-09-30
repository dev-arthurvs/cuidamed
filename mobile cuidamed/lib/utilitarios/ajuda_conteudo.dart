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
      'O card azul grande mostra o próximo medicamento a tomar. Quando tomar, toque em "Registrar dose".',
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
      'Use "Ver histórico completo" para consultar todas as doses já registradas.',
      'Use "Acessar agenda" para adicionar, editar ou remover remédios da agenda do paciente.',
      'Use "Ver ciclos encerrados" para ver remédios cujo tratamento já terminou.',
      'Ao lado do status de cada dose em "Doses de hoje", use o ícone verde de telefone para mandar um lembrete pelo WhatsApp direto pro paciente. Só aparece pra doses ainda não tomadas, e fica desabilitado se o paciente não tiver telefone cadastrado.',
      'Use "Painel do paciente ⚙️" para gerenciar permissões e desvincular o paciente, se precisar.',
    ],
  ),
  SecaoAjuda(
    chave: 'painel-paciente-config',
    publico: 'cuidador',
    titulo: 'Painel do paciente (configurações)',
    paraQueServe: 'Tela de configurações do vínculo com um paciente específico. Só o cuidador pode acessar e alterar essas opções.',
    passos: [
      'A chave "Permite alterações" define se o paciente pode adicionar, editar ou excluir os próprios remédios. Desligada por padrão — ligue se quiser dar autonomia a ele.',
      'Use "Desvincular paciente" se quiser parar de acompanhar esse paciente. Essa ação desfaz o vínculo dos dois lados e não pode ser feita pelo paciente, só pelo cuidador.',
      'Se o paciente não tiver e-mail/senha próprios, desvincular o deixa sem nenhum cuidador responsável — o aplicativo avisa antes de confirmar.',
    ],
  ),
  SecaoAjuda(
    chave: 'agenda',
    publico: 'ambos',
    titulo: 'Agenda de medicamentos',
    paraQueServe:
        'É onde os remédios são cadastrados, com nome, dosagem, forma, frequência e horários. Cuidadores veem a agenda do paciente selecionado; pacientes veem a própria.',
    passos: [
      'Toque em "+ Inserir medicamento" para cadastrar um novo remédio: preencha nome, dosagem, forma (comprimido, gotas, etc.), frequência e os horários do dia.',
      'Em cada card já cadastrado, use "Editar" para mudar alguma informação ou "Excluir" para remover.',
      'Remédios saem daqui automaticamente assim que a última dose do ciclo é confirmada (mesmo no próprio dia em que o tratamento termina) e vão para "Ciclos encerrados".',
      'Se você é paciente e não vê os botões de inserir/editar/excluir, é porque seu cuidador ainda não liberou essa permissão para você — fale com ele.',
    ],
  ),
  SecaoAjuda(
    chave: 'ciclos-encerrados',
    publico: 'ambos',
    titulo: 'Ciclos encerrados',
    paraQueServe:
        'Guarda os remédios cujo período de tratamento já terminou, para consulta futura. Um remédio entra aqui assim que a última dose do ciclo é confirmada, mesmo no próprio dia da data final — ou, o mais tardar, no dia seguinte, mesmo que a última dose não tenha sido registrada.',
    passos: [
      'A lista mostra o período em que cada remédio foi usado (data de início até data de fim).',
      'Use a seta de voltar no topo para retornar aos remédios ativos.',
    ],
  ),
  SecaoAjuda(
    chave: 'historico',
    publico: 'ambos',
    titulo: 'Histórico',
    paraQueServe: 'Mostra o registro de todas as doses já passadas: quais foram tomadas, atrasadas ou perdidas.',
    passos: [
      'Escolha o período nos campos "De" e "Até" (começam no dia de hoje). Não dá para escolher datas futuras.',
      'Use o filtro "Medicamento" para ver o histórico de um remédio específico.',
      'Os três números no topo resumem quantas doses foram tomadas, atrasadas e perdidas no período escolhido.',
      'A lista abaixo mostra cada dose, organizada por dia, da mais recente para a mais antiga.',
    ],
  ),
  SecaoAjuda(
    chave: 'farmacias',
    publico: 'ambos',
    titulo: 'Farmácias',
    paraQueServe: 'Ajuda a encontrar farmácias próximas de um endereço, com mapa e distância até cada uma.',
    passos: [
      'Digite um endereço no campo "Endereço de origem" (pelo menos 3 letras): escolha uma das sugestões, ou toque em "Buscar" para buscar o texto digitado direto.',
      'Ou toque em "Usar minha localização atual" para buscar a partir de onde você está.',
      'Ou informe um CEP (e opcionalmente o número) e toque em "Buscar CEP".',
      'Escolha o raio de busca (1, 3 ou 5 km) para ver mais ou menos farmácias.',
      'Enquanto o aplicativo consulta o serviço de mapas, aparece um ícone de carregamento — a busca pode levar até 20 segundos.',
      'Toque em uma farmácia da lista ou do mapa para destacá-la, e use "Como chegar" para abrir a rota no Google Maps.',
    ],
  ),
  SecaoAjuda(
    chave: 'chat',
    publico: 'paciente',
    titulo: 'Chat com o assistente',
    paraQueServe:
        'Um assistente virtual que responde perguntas sobre a sua própria rotina de remédios: quais toma, em que horário, e se já tomou nos últimos dias.',
    passos: [
      'Toque em uma das perguntas sugeridas para enviar direto, sem precisar digitar.',
      'Ou digite sua pergunta no campo de texto e toque em "Enviar".',
      'O assistente só responde sobre os seus próprios medicamentos e histórico — ele não dá conselhos médicos nem opina sobre outros assuntos.',
      'Se a pergunta for sobre saúde em geral, ele vai pedir para você falar com seu médico ou cuidador.',
    ],
  ),
  SecaoAjuda(
    chave: 'perfil',
    publico: 'ambos',
    titulo: 'Perfil',
    paraQueServe: 'Reúne seus dados pessoais, troca de senha e (se você for paciente) o vínculo com o cuidador.',
    passos: [
      'Atualize nome, e-mail e outros dados no primeiro formulário e toque em "Salvar alterações".',
      'Se você é paciente, cadastre seu telefone com DDD — é ele que o cuidador usa pra mandar lembretes de dose pelo WhatsApp.',
      'Para trocar a senha, preencha a senha atual e a nova senha (mínimo 8 caracteres) e toque em "Atualizar senha".',
      'Se você é paciente sem cuidador vinculado, informe o e-mail do cuidador no card "Vincular cuidador(a)" — ele precisa confirmar o pedido antes do vínculo valer.',
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
  if (RegExp(r'^/cuidador/paciente/[^/]+/painel').hasMatch(rota)) return 'painel-paciente-config';
  if (rota.startsWith('/cuidador/paciente/')) return 'detalhes-paciente';
  if (rota == '/painel') return tipoUsuario == 'cuidador' ? 'inicio-cuidador' : 'inicio-paciente';
  if (rota.startsWith('/agenda')) return 'agenda';
  if (rota.startsWith('/ciclos-encerrados')) return 'ciclos-encerrados';
  if (rota.startsWith('/historico')) return 'historico';
  if (rota.startsWith('/perfil')) return 'perfil';
  if (rota.startsWith('/farmacias')) return 'farmacias';
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
