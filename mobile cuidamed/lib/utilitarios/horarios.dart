import '../modelos/dose.dart';
import '../modelos/historico.dart';
import '../modelos/medicamento.dart';

/// Porta fiel de front-end cuidamed/src/utilitarios/horarios.js — mesma
/// regra de negócio, mesmos limiares, calculados no cliente porque o
/// back-end não persiste status "pendente"/"atrasado" em tempo real.
const int toleranciaAtrasoMin = 15;
const int limitePerdidaMin = 180;

int paraMinutos(String horario) {
  final partes = horario.split(':');
  return int.parse(partes[0]) * 60 + int.parse(partes[1]);
}

int minutosAgora([DateTime? agora]) {
  final data = agora ?? DateTime.now();
  return data.hour * 60 + data.minute;
}

/// [statusRegistrado] vem do histórico (TOMADO/ATRASADO/PERDIDO em minúsculo
/// já convertido) quando a dose já foi confirmada; null quando ainda não foi.
String calcularStatusAtual(String horario, String? statusRegistrado, {int? agoraEmMinutos}) {
  if (statusRegistrado == 'tomado') return 'tomado';
  final diferenca = (agoraEmMinutos ?? minutosAgora()) - paraMinutos(horario);
  if (diferenca < toleranciaAtrasoMin) return 'pendente';
  if (diferenca < limitePerdidaMin) return 'atrasado';
  return 'perdido';
}

String dataAtualISO([DateTime? data]) {
  final d = data ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Monta a lista de "doses de hoje" cruzando os horários de cada medicamento
/// ativo com o histórico já registrado hoje.
List<Dose> construirDosesHoje(List<Medicamento> medicamentosAtivos, List<Historico> historicoHoje, {String? hojeIso}) {
  final hoje = hojeIso ?? dataAtualISO();
  final doses = <Dose>[];
  for (final medicamento in medicamentosAtivos) {
    // Só entra se hoje é dia de dose: tratamento que ainda não começou não tem
    // dose (antes aparecia como "perdido"), e "Dias alternados"/"Semanal" só
    // têm dose a cada 2/7 dias (antes geravam dose todo dia).
    if (!temDoseNoDia(medicamento, diaIso: hoje)) continue;
    for (final horario in medicamento.horarios) {
      final registrado = historicoHoje.where((h) => h.medicamentoId == medicamento.id && h.hora == horario);
      final statusRegistrado = registrado.isNotEmpty ? registrado.first.status.toLowerCase() : null;
      final status = calcularStatusAtual(horario, statusRegistrado);
      doses.add(Dose(
        id: '${medicamento.id}-$horario',
        medicamentoId: medicamento.id,
        horario: horario,
        nome: medicamento.nome,
        dosagem: medicamento.dosagem,
        forma: medicamento.forma,
        quantidadePorDose: medicamento.quantidadePorDose,
        dataFim: medicamento.dataFim,
        status: status,
      ));
    }
  }
  doses.sort((a, b) => a.horario.compareTo(b.horario));
  return doses;
}

const int diasJanelaAdesao = 30;

/// Adesão dos últimos 30 dias (hoje incluso) — é o período que as telas
/// anunciam ("Adesão média (30 dias)"). Antes considerava o histórico inteiro.
int calcularAdesao(List<Historico> historico, {String? hojeIso}) {
  final hoje = DateTime.parse(hojeIso ?? dataAtualISO());
  final inicioIso = dataAtualISO(hoje.subtract(const Duration(days: diasJanelaAdesao - 1)));
  final hojeStr = dataAtualISO(hoje);
  final recentes = historico.where((h) {
    final dia = dataAtualISO(h.data);
    return dia.compareTo(inicioIso) >= 0 && dia.compareTo(hojeStr) <= 0;
  }).toList();
  if (recentes.isEmpty) return 100;
  final tomados = recentes.where((h) => h.status.toLowerCase() == 'tomado').length;
  return ((tomados / recentes.length) * 100).round();
}

/// No próprio dia do "fim" do ciclo, só considera encerrado depois que todas
/// as doses de hoje já foram registradas no histórico — senão o medicamento
/// desapareceria da agenda antes do cuidador/paciente confirmar a última dose.
bool medicamentoEncerrado(Medicamento medicamento, {String? hojeIso, List<Historico>? historico}) {
  if (medicamento.dataFim == null) return false;
  final hoje = hojeIso ?? dataAtualISO();
  final fimIso = dataAtualISO(medicamento.dataFim);
  if (fimIso.compareTo(hoje) < 0) return true;
  if (fimIso.compareTo(hoje) > 0) return false;
  if (!temDoseNoDia(medicamento, diaIso: hoje)) return true; // último dia sem dose: ciclo já cumprido

  final historicoHoje = (historico ?? []).where((h) => dataAtualISO(h.data) == hoje && h.medicamentoId == medicamento.id);
  return medicamento.horarios.every((horario) => historicoHoje.any((h) => h.hora == horario));
}

/// false enquanto a data de início do tratamento ainda não chegou.
bool medicamentoIniciado(Medicamento medicamento, {String? hojeIso}) =>
    dataAtualISO(medicamento.dataInicio).compareTo(hojeIso ?? dataAtualISO()) <= 0;

int _diasEntre(String deIso, String ateIso) => DateTime.parse(ateIso).difference(DateTime.parse(deIso)).inDays;

String _somarDias(String dataIso, int dias) => dataAtualISO(DateTime.parse(dataIso).add(Duration(days: dias)));

/// Frequências que não são diárias: "Dias alternados" = dose a cada 2 dias e
/// "Semanal" = a cada 7, contando a partir da data de início. As demais
/// (1x/2x/3x ao dia, a cada 8 horas) têm dose todos os dias. Igual ao web.
const Map<String, int> _intervaloDiasPorFrequencia = {'DIAS_ALTERNADOS': 2, 'SEMANAL': 7};

int intervaloEntreDiasDeDose(Medicamento medicamento) => _intervaloDiasPorFrequencia[medicamento.frequencia] ?? 1;

/// O remédio tem dose nesse dia? Considera início, fim e a frequência.
bool temDoseNoDia(Medicamento medicamento, {String? diaIso}) {
  final dia = diaIso ?? dataAtualISO();
  final inicio = dataAtualISO(medicamento.dataInicio);
  if (dia.compareTo(inicio) < 0) return false;
  if (medicamento.dataFim != null && dia.compareTo(dataAtualISO(medicamento.dataFim)) > 0) return false;
  final intervalo = intervaloEntreDiasDeDose(medicamento);
  if (intervalo == 1) return true;
  return _diasEntre(inicio, dia) % intervalo == 0;
}

/// Próximo dia (a partir de [aPartirIso], inclusive) com dose; null se o ciclo acaba antes.
String? proximoDiaDeDose(Medicamento medicamento, {String? aPartirIso}) {
  final base = aPartirIso ?? dataAtualISO();
  final inicio = dataAtualISO(medicamento.dataInicio);
  var dia = inicio.compareTo(base) > 0 ? inicio : base;
  final fim = medicamento.dataFim == null ? null : dataAtualISO(medicamento.dataFim);
  for (var i = 0; i < 8; i++) {
    if (fim != null && dia.compareTo(fim) > 0) return null;
    if (temDoseNoDia(medicamento, diaIso: dia)) return dia;
    dia = _somarDias(dia, 1);
  }
  return null;
}

/// Quantos dias com dose existem entre [deIso] e [ateIso] (inclusive).
int _contarDiasDeDose(Medicamento medicamento, String deIso, String ateIso) {
  if (ateIso.compareTo(deIso) < 0) return 0;
  final intervalo = intervaloEntreDiasDeDose(medicamento);
  if (intervalo == 1) return _diasEntre(deIso, ateIso) + 1;
  final primeiro = proximoDiaDeDose(medicamento, aPartirIso: deIso);
  if (primeiro == null || primeiro.compareTo(ateIso) > 0) return 0;
  return _diasEntre(primeiro, ateIso) ~/ intervalo + 1;
}

/// Espelha calcularDiasRestantesCiclo do web: null quando não há data final.
int? calcularDiasRestantesCiclo(DateTime? dataFim, {String? hojeIso}) {
  if (dataFim == null) return null;
  final hoje = DateTime.parse(hojeIso ?? dataAtualISO());
  final fim = DateTime(dataFim.year, dataFim.month, dataFim.day);
  return fim.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
}

class InfoEstoque {
  final int quantidade;
  final String unidade;
  final int diasRestantes;
  final bool esgotado;
  final bool baixo;

  /// O estoque atual cobre todas as doses que faltam até a data final.
  final bool duraAteOFim;
  InfoEstoque({
    required this.quantidade,
    required this.unidade,
    required this.diasRestantes,
    required this.esgotado,
    required this.baixo,
    this.duraAteOFim = false,
  });
}

const int limiarDiasEstoqueBaixo = 5;

/// null pra Pomada (não tem unidade discreta) ou quando não há quantidade
/// cadastrada — espelha calcularEstoque do web.
InfoEstoque? calcularEstoque(Medicamento medicamento, {List<Historico> historico = const [], String? hojeIso}) {
  if (medicamento.forma == 'POMADA') return null;
  if (medicamento.quantidadeEstoque == null) return null;
  final hoje = hojeIso ?? dataAtualISO();
  final dosesPorDia = medicamento.horarios.isEmpty ? 1 : medicamento.horarios.length;
  final consumoPorDose = medicamento.quantidadePorDose ?? 1;
  final quantidade = medicamento.quantidadeEstoque!;
  // Dias de calendário: em "Dias alternados"/"Semanal" cada dia de dose rende 2/7 dias.
  final diasRestantes = (quantidade / (dosesPorDia * consumoPorDose)).floor() * intervaloEntreDiasDeDose(medicamento);
  final necessarias = _unidadesAteOFim(medicamento, historico, hoje, dosesPorDia, consumoPorDose);
  // Se o que tem cobre tudo o que falta tomar até a data final, não precisa comprar.
  final duraAteOFim = necessarias != null && quantidade > 0 && quantidade >= necessarias;
  return InfoEstoque(
    quantidade: quantidade,
    unidade: unidadeEstoquePorForma[medicamento.forma] ?? 'unidades',
    diasRestantes: diasRestantes,
    esgotado: quantidade <= 0 && necessarias != 0,
    baixo: !duraAteOFim && diasRestantes <= limiarDiasEstoqueBaixo,
    duraAteOFim: duraAteOFim,
  );
}

/// Unidades que ainda serão consumidas até o fim do tratamento: doses de hoje
/// ainda não registradas + as dos dias seguintes (o back-end já desconta do
/// estoque cada dose registrada como tomada). null em uso contínuo (sem fim).
int? _unidadesAteOFim(Medicamento medicamento, List<Historico> historico, String hoje, int dosesPorDia, int consumoPorDose) {
  if (medicamento.dataFim == null) return null;
  final fim = dataAtualISO(medicamento.dataFim);
  if (fim.compareTo(hoje) < 0) return null;
  if (!medicamentoIniciado(medicamento, hojeIso: hoje)) {
    return _contarDiasDeDose(medicamento, dataAtualISO(medicamento.dataInicio), fim) * dosesPorDia * consumoPorDose;
  }
  final tomadasHoje = historico
      .where((h) => h.medicamentoId == medicamento.id && dataAtualISO(h.data) == hoje && h.status.toUpperCase() == 'TOMADO')
      .length;
  final restantesHoje = temDoseNoDia(medicamento, diaIso: hoje) ? (dosesPorDia - tomadasHoje).clamp(0, dosesPorDia) : 0;
  final diasSeguintes = _contarDiasDeDose(medicamento, _somarDias(hoje, 1), fim);
  return (restantesHoje + diasSeguintes * dosesPorDia) * consumoPorDose;
}

int calcularIdade(DateTime? nascimento, [DateTime? hoje]) {
  if (nascimento == null) return 0;
  final agora = hoje ?? DateTime.now();
  var idade = agora.year - nascimento.year;
  final aindaNaoFezAniversario =
      agora.month < nascimento.month || (agora.month == nascimento.month && agora.day < nascimento.day);
  if (aindaNaoFezAniversario) idade -= 1;
  return idade;
}
