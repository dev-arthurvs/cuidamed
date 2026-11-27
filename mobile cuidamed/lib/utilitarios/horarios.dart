import '../modelos/dose.dart';
import '../modelos/historico.dart';
import '../modelos/medicamento.dart';

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

List<Dose> construirDosesHoje(List<Medicamento> medicamentos, List<Historico> historicoHoje, {String? hojeIso}) {
  final hoje = hojeIso ?? dataAtualISO();
  final doses = <Dose>[];
  for (final medicamento in medicamentos) {
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

const int diasJanelaHistorico = diasJanelaAdesao + 1;

DateTime inicioJanelaHistorico([DateTime? hoje]) {
  final dia = hoje ?? DateTime.now();
  return DateTime(dia.year, dia.month, dia.day - diasJanelaHistorico);
}

int calcularAdesao(List<Historico> historico, {List<Medicamento> medicamentos = const [], String? hojeIso}) {
  final hoje = DateTime.parse(hojeIso ?? dataAtualISO());
  final inicioIso = dataAtualISO(hoje.subtract(const Duration(days: diasJanelaAdesao - 1)));
  final hojeStr = dataAtualISO(hoje);
  final recentes = historico.where((h) {
    final dia = dataAtualISO(h.data);
    return dia.compareTo(inicioIso) >= 0 && dia.compareTo(hojeStr) <= 0;
  }).toList();
  recentes.addAll(
    dosesSemRegistro(0, medicamentos, historico, DateTime.parse(inicioIso), hoje).where((d) => d.status == 'PERDIDO'),
  );
  if (recentes.isEmpty) return 100;
  final tomados = recentes.where((h) => h.status.toLowerCase() == 'tomado').length;
  return ((tomados / recentes.length) * 100).round();
}

bool medicamentoEncerrado(Medicamento medicamento, {String? hojeIso, List<Historico>? historico}) {
  if (medicamento.dataFim == null) return false;
  final hoje = hojeIso ?? dataAtualISO();
  final fimIso = dataAtualISO(medicamento.dataFim);
  if (fimIso.compareTo(hoje) < 0) return true;
  if (fimIso.compareTo(hoje) > 0) return false;
  if (!temDoseNoDia(medicamento, diaIso: hoje)) return true;

  final historicoHoje = (historico ?? []).where((h) => dataAtualISO(h.data) == hoje && h.medicamentoId == medicamento.id);
  return medicamento.horarios.every((horario) => historicoHoje.any((h) => h.hora == horario));
}

bool medicamentoIniciado(Medicamento medicamento, {String? hojeIso}) =>
    dataAtualISO(medicamento.dataInicio).compareTo(hojeIso ?? dataAtualISO()) <= 0;

int _diasEntre(String deIso, String ateIso) => DateTime.parse(ateIso).difference(DateTime.parse(deIso)).inDays;

String _somarDias(String dataIso, int dias) => dataAtualISO(DateTime.parse(dataIso).add(Duration(days: dias)));

List<Historico> dosesSemRegistro(
  int pacienteId,
  List<Medicamento> medicamentos,
  List<Historico> historico,
  DateTime de,
  DateTime ate, {
  DateTime? agora,
}) {
  final momento = agora ?? DateTime.now();
  final hojeIso = dataAtualISO(momento);
  final ateIso = dataAtualISO(ate).compareTo(hojeIso) > 0 ? hojeIso : dataAtualISO(ate);
  var dia = dataAtualISO(de);
  final inicios = medicamentos.map((m) => dataAtualISO(m.dataInicio)).toList()..sort();
  if (inicios.isNotEmpty && inicios.first.compareTo(dia) > 0) dia = inicios.first;
  final registrados = historico.map((h) => '${h.medicamentoId}|${dataAtualISO(h.data)}|${h.hora}').toSet();
  final agoraEmMinutos = minutosAgora(momento);
  final doses = <Historico>[];
  for (; dia.compareTo(ateIso) <= 0; dia = _somarDias(dia, 1)) {
    for (final medicamento in medicamentos) {
      if (!temDoseNoDia(medicamento, diaIso: dia)) continue;
      for (final horario in medicamento.horarios) {
        if (registrados.contains('${medicamento.id}|$dia|$horario')) continue;
        final status = dia.compareTo(hojeIso) < 0
            ? 'perdido'
            : calcularStatusAtual(horario, null, agoraEmMinutos: agoraEmMinutos);
        if (status == 'pendente') continue;
        doses.add(Historico(
          id: 0,
          pacienteId: pacienteId,
          medicamentoId: medicamento.id,
          data: DateTime.parse(dia),
          hora: horario,
          nomeMedicamento: medicamento.nome,
          dosagem: medicamento.dosagem,
          status: status.toUpperCase(),
        ));
      }
    }
  }
  return doses;
}

const Map<String, int> _intervaloDiasPorFrequencia = {'DIAS_ALTERNADOS': 2, 'SEMANAL': 7};

int intervaloEntreDiasDeDose(Medicamento medicamento) => _intervaloDiasPorFrequencia[medicamento.frequencia] ?? 1;

bool temDoseNoDia(Medicamento medicamento, {String? diaIso}) {
  final dia = diaIso ?? dataAtualISO();
  final inicio = dataAtualISO(medicamento.dataInicio);
  if (dia.compareTo(inicio) < 0) return false;
  if (medicamento.dataFim != null && dia.compareTo(dataAtualISO(medicamento.dataFim)) > 0) return false;
  final intervalo = intervaloEntreDiasDeDose(medicamento);
  if (intervalo == 1) return true;
  return _diasEntre(inicio, dia) % intervalo == 0;
}

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

int _contarDiasDeDose(Medicamento medicamento, String deIso, String ateIso) {
  if (ateIso.compareTo(deIso) < 0) return 0;
  final intervalo = intervaloEntreDiasDeDose(medicamento);
  if (intervalo == 1) return _diasEntre(deIso, ateIso) + 1;
  final primeiro = proximoDiaDeDose(medicamento, aPartirIso: deIso);
  if (primeiro == null || primeiro.compareTo(ateIso) > 0) return 0;
  return _diasEntre(primeiro, ateIso) ~/ intervalo + 1;
}

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

InfoEstoque? calcularEstoque(Medicamento medicamento, {List<Historico> historico = const [], String? hojeIso}) {
  if (medicamento.forma == 'POMADA') return null;
  if (medicamento.quantidadeEstoque == null) return null;
  final hoje = hojeIso ?? dataAtualISO();
  final dosesPorDia = medicamento.horarios.isEmpty ? 1 : medicamento.horarios.length;
  final consumoPorDose = medicamento.quantidadePorDose ?? 1;
  final quantidade = medicamento.quantidadeEstoque!;
  final diasRestantes = (quantidade / (dosesPorDia * consumoPorDose)).floor() * intervaloEntreDiasDeDose(medicamento);
  final necessarias = _unidadesAteOFim(medicamento, historico, hoje, dosesPorDia, consumoPorDose);
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

class AvisoEstoque {
  final String nome;
  final String texto;
  final bool esgotado;
  const AvisoEstoque({required this.nome, required this.texto, required this.esgotado});
}

List<AvisoEstoque> avisosEstoque(List<Medicamento> medicamentosAtivos, List<Historico> historico, {String? hojeIso}) {
  final avisos = <AvisoEstoque>[];
  for (final medicamento in medicamentosAtivos) {
    final estoque = calcularEstoque(medicamento, historico: historico, hojeIso: hojeIso);
    if (estoque == null) continue;
    if (estoque.esgotado) {
      avisos.add(AvisoEstoque(nome: medicamento.nome, texto: 'Estoque esgotado. Reponha o quanto antes.', esgotado: true));
    } else if (estoque.baixo) {
      final dias = estoque.diasRestantes;
      final duracao = dias <= 0 ? 'não dá para o dia todo' : 'dura $dias dia${dias == 1 ? '' : 's'}';
      avisos.add(AvisoEstoque(nome: medicamento.nome, texto: 'Restam ${estoque.quantidade} ${estoque.unidade} ($duracao).', esgotado: false));
    }
  }
  return avisos;
}
