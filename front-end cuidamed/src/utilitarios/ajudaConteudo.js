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
      'O card azul grande mostra o próximo medicamento a tomar. Quando tomar, clique em "Registrar dose".',
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
      'Use "Ver histórico completo" para consultar todas as doses já registradas.',
      'Use "Acessar agenda" para adicionar, editar ou remover remédios da agenda do paciente.',
      'Use "Ver ciclos encerrados" para ver remédios cujo tratamento já terminou.',
      'Ao lado do status de cada dose em "Doses de hoje", use o ícone verde de telefone para mandar um lembrete pelo WhatsApp direto pro paciente. Só aparece pra doses ainda não tomadas, e fica desabilitado se o paciente não tiver telefone cadastrado.',
      'Use "Painel do paciente ⚙️" para gerenciar permissões e desvincular o paciente, se precisar.',
    ],
  },
  {
    chave: 'painel-paciente-config',
    publico: 'cuidador',
    titulo: 'Painel Paciente (configurações)',
    paraQueServe:
      'Tela de configurações do vínculo com um paciente específico. Só o cuidador pode acessar e alterar essas opções.',
    passos: [
      'O botão "Permite alterações" define se o paciente pode adicionar, editar ou excluir os próprios remédios. Desligado por padrão — ligue se quiser dar autonomia a ele.',
      'Use "Desvincular paciente" se quiser parar de acompanhar esse paciente. Essa ação desfaz o vínculo dos dois lados e não pode ser feita pelo paciente, só pelo cuidador.',
      'Se o paciente não tiver e-mail/senha próprios, desvincular o deixa sem nenhum cuidador responsável — o sistema avisa antes de confirmar.',
    ],
  },
  {
    chave: 'agenda',
    publico: 'ambos',
    titulo: 'Agenda de medicamentos',
    paraQueServe:
      'É onde os remédios são cadastrados, com nome, dosagem, forma, frequência e horários. Cuidadores veem a agenda do paciente selecionado; pacientes veem a própria.',
    passos: [
      'Clique em "+ Inserir medicamento" para cadastrar um novo remédio: preencha nome, dosagem, forma (comprimido, gotas, etc.), frequência e os horários do dia.',
      'Em cada card já cadastrado, use "Editar" para mudar alguma informação ou "Excluir" para remover.',
      'Remédios saem daqui automaticamente assim que a última dose do ciclo é confirmada (mesmo no próprio dia em que o tratamento termina) e vão para "Ciclos encerrados".',
      'Se você é paciente e não vê os botões de inserir/editar/excluir, é porque seu cuidador ainda não liberou essa permissão para você — fale com ele.',
    ],
  },
  {
    chave: 'ciclos-encerrados',
    publico: 'ambos',
    titulo: 'Ciclos encerrados',
    paraQueServe:
      'Guarda os remédios cujo período de tratamento já terminou, para consulta futura. Um remédio entra aqui assim que a última dose do ciclo é confirmada, mesmo no próprio dia da data final — ou, o mais tardar, no dia seguinte, mesmo que a última dose não tenha sido registrada.',
    passos: [
      'A lista mostra o período em que cada remédio foi usado (data de início até data de fim).',
      'Use "‹ Voltar para a agenda" para retornar aos remédios ativos.',
    ],
  },
  {
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
  },
  {
    chave: 'farmacias',
    publico: 'ambos',
    titulo: 'Farmácias',
    paraQueServe: 'Ajuda a encontrar farmácias próximas de um endereço, com mapa e distância até cada uma.',
    passos: [
      'Digite um endereço no campo "Endereço de origem" (pelo menos 3 letras): escolha uma das sugestões, ou clique em "Buscar" (ou tecle Enter) para buscar o texto digitado direto.',
      'Ou clique em "Usar minha localização atual" para buscar a partir de onde você está.',
      'Ou informe um CEP (e opcionalmente o número) e clique em "Buscar CEP".',
      'Escolha o raio de busca (1, 3 ou 5 km) para ver mais ou menos farmácias.',
      'Enquanto o sistema consulta o serviço de mapas, aparece um ícone de carregamento — a busca pode levar até 20 segundos.',
      'Clique em uma farmácia da lista ou do mapa para destacá-la, e use "Como chegar" para abrir a rota no Google Maps.',
    ],
  },
  {
    chave: 'chat',
    publico: 'paciente',
    titulo: 'Chat com o assistente',
    paraQueServe:
      'Um assistente virtual que responde perguntas sobre a sua própria rotina de remédios: quais toma, em que horário, e se já tomou nos últimos dias.',
    passos: [
      'Clique em uma das perguntas sugeridas para enviar direto, sem precisar digitar.',
      'Ou digite sua pergunta no campo de texto e clique em "Enviar".',
      'O assistente só responde sobre os seus próprios medicamentos e histórico — ele não dá conselhos médicos nem opina sobre outros assuntos.',
      'Se a pergunta for sobre saúde em geral, ele vai pedir para você falar com seu médico ou cuidador.',
    ],
  },
  {
    chave: 'perfil',
    publico: 'ambos',
    titulo: 'Perfil',
    paraQueServe: 'Reúne seus dados pessoais, troca de senha e (se você for paciente) o vínculo com o cuidador.',
    passos: [
      'Atualize nome, e-mail e outros dados no primeiro formulário e clique em "Salvar alterações".',
      'Se você é paciente, cadastre seu telefone com DDD — é ele que o cuidador usa pra mandar lembretes de dose pelo WhatsApp.',
      'Para trocar a senha, preencha a senha atual e a nova senha (mínimo 8 caracteres) e clique em "Atualizar senha".',
      'Se você é paciente sem cuidador vinculado, informe o e-mail do cuidador no card "Vincular cuidador(a)" — ele precisa confirmar o pedido antes do vínculo valer.',
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
  if (/^\/cuidador\/paciente\/[^/]+\/painel/.test(pathname)) return 'painel-paciente-config'
  if (/^\/cuidador\/paciente\//.test(pathname)) return 'detalhes-paciente'
  if (pathname === '/painel') return tipoUsuario === 'cuidador' ? 'inicio-cuidador' : 'inicio-paciente'
  if (pathname.startsWith('/agenda')) return 'agenda'
  if (pathname.startsWith('/ciclos-encerrados')) return 'ciclos-encerrados'
  if (pathname.startsWith('/historico')) return 'historico'
  if (pathname.startsWith('/perfil')) return 'perfil'
  if (pathname.startsWith('/farmacias')) return 'farmacias'
  if (pathname.startsWith('/chat')) return 'chat'
  if (pathname.startsWith('/acessibilidade')) return 'acessibilidade'
  return null
}

export function obterSecaoAjuda(pathname, tipoUsuario) {
  const chave = obterChaveAjuda(pathname, tipoUsuario)
  return GUIA_SECOES.find((secao) => secao.chave === chave) || null
}
