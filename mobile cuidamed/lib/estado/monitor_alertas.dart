import 'dart:async';

import '../modelos/paciente.dart';
import '../utilitarios/horarios.dart';
import 'app_estado.dart';

class AlertaPaciente {
  final String titulo;
  final String mensagem;

  final bool notificacaoAgendada;

  const AlertaPaciente(this.titulo, this.mensagem, {this.notificacaoAgendada = false});
}

class MonitorAlertas {
  final AppEstado estado;
  final Future<Paciente> Function(int pacienteId) buscarPaciente;
  final Future<void> Function(int pacienteId) confirmarAlertaManual;
  final void Function(AlertaPaciente alerta) aoAlertar;
  final Duration intervalo;
  final DateTime Function() agora;

  static const mensagemPadraoCuidador = 'Seu cuidador pediu para lembrá-lo de tomar sua medicação.';

  Timer? _timer;
  int? _pacienteMonitorado;
  int? _cuidadorMonitorado;
  bool _verificandoManual = false;
  final Set<String> _dosesAvisadas = {};

  MonitorAlertas({
    required this.estado,
    required this.buscarPaciente,
    required this.confirmarAlertaManual,
    required this.aoAlertar,
    this.intervalo = const Duration(seconds: 30),
    DateTime Function()? agora,
  }) : agora = agora ?? DateTime.now {
    estado.addListener(_sincronizar);
    _sincronizar();
  }

  bool get ativo => _timer != null;

  void _sincronizar() {
    final usuario = estado.usuario;
    final pacienteId = usuario?.tipo == 'paciente' ? usuario!.id : null;
    final cuidadorId = usuario?.tipo == 'cuidador' ? usuario!.id : null;
    if (pacienteId == _pacienteMonitorado && cuidadorId == _cuidadorMonitorado) return;
    _parar();
    if (pacienteId == null && cuidadorId == null) return;
    _pacienteMonitorado = pacienteId;
    _cuidadorMonitorado = cuidadorId;
    _timer = Timer.periodic(intervalo, (_) => verificarAgora());
    verificarAgora();
  }

  void _parar() {
    _timer?.cancel();
    _timer = null;
    _pacienteMonitorado = null;
    _cuidadorMonitorado = null;
    _dosesAvisadas.clear();
  }

  Future<void> verificarAgora() async {
    if (_cuidadorMonitorado != null) {
      _verificarAtrasosDosPacientes();
      return;
    }
    final pacienteId = _pacienteMonitorado;
    if (pacienteId == null) return;
    _verificarHorarioDasDoses();
    await _verificarAlertaManual(pacienteId);
  }

  void _verificarAtrasosDosPacientes() {
    if (estado.emSegundoPlano) return;
    final momento = agora();
    final hojeIso = dataAtualISO(momento);
    final minutos = momento.hour * 60 + momento.minute;
    final novos = <({String paciente, String horario, String remedio})>[];
    for (final dados in estado.pacientes) {
      final historicoHoje = dados.historico.where((h) => dataAtualISO(h.data) == hojeIso).toList();
      for (final dose in construirDosesHoje(dados.medicamentos, historicoHoje, hojeIso: hojeIso)) {
        final chave = '$hojeIso-${dados.paciente.id}-${dose.id}';
        if (dose.status == 'tomado' || _dosesAvisadas.contains(chave)) continue;
        if (calcularStatusAtual(dose.horario, null, agoraEmMinutos: minutos) != 'atrasado') continue;
        _dosesAvisadas.add(chave);
        novos.add((paciente: dados.paciente.nome.split(' ').first, horario: dose.horario, remedio: dose.nome));
      }
    }
    if (novos.isEmpty) return;
    final mensagem = novos.length == 1
        ? '${novos.first.paciente}: a dose das ${novos.first.horario} (${novos.first.remedio}) está atrasada.'
        : '${novos.length} doses atrasadas: ${novos.map((n) => n.paciente).toSet().join(', ')}.';
    aoAlertar(AlertaPaciente('Dose atrasada ⏰', mensagem));
  }

  void _verificarHorarioDasDoses() {
    final dados = estado.pacienteFoco;
    if (dados == null) return;
    final momento = agora();
    final hojeIso = dataAtualISO(momento);
    final historicoHoje = dados.historico.where((h) => dataAtualISO(h.data) == hojeIso).toList();
    final doses = construirDosesHoje(dados.medicamentos, historicoHoje);
    final minutosAtuais = momento.hour * 60 + momento.minute;
    for (final dose in doses) {
      final chave = '$hojeIso-${dose.id}';
      if (dose.status == 'tomado' || _dosesAvisadas.contains(chave)) continue;
      final diferenca = minutosAtuais - paraMinutos(dose.horario);
      if (diferenca >= 0 && diferenca < 1) {
        _dosesAvisadas.add(chave);
        final mensagem = dose.dosagem.isEmpty
            ? 'Está na hora de tomar ${dose.nome}.'
            : 'Está na hora de tomar ${dose.nome} (${dose.dosagem}).';
        aoAlertar(AlertaPaciente('Hora do remédio 💊', mensagem, notificacaoAgendada: true));
      }
    }
  }

  Future<void> _verificarAlertaManual(int pacienteId) async {
    if (_verificandoManual) return;
    _verificandoManual = true;
    try {
      final paciente = await buscarPaciente(pacienteId);
      if (_pacienteMonitorado != pacienteId || !paciente.alertaManualPendente) return;
      final mensagem = (paciente.alertaManualMensagem ?? '').trim().isEmpty
          ? mensagemPadraoCuidador
          : paciente.alertaManualMensagem!.trim();
      aoAlertar(AlertaPaciente('Lembrete do seu cuidador 💊', mensagem));
      await confirmarAlertaManual(pacienteId);
    } catch (_) {
    } finally {
      _verificandoManual = false;
    }
  }

  void dispose() {
    estado.removeListener(_sincronizar);
    _parar();
  }
}
