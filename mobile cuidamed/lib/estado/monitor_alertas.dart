import 'dart:async';

import '../modelos/paciente.dart';
import '../utilitarios/horarios.dart';
import 'app_estado.dart';

/// Um aviso disparado pro paciente (vai pra tela, pro som e pra notificação).
class AlertaPaciente {
  final String titulo;
  final String mensagem;

  /// O celular já agendou esta notificação (lembretes agendados): com o app
  /// aberto, só mostra na tela e toca o som, para não notificar duas vezes.
  final bool notificacaoAgendada;

  const AlertaPaciente(this.titulo, this.mensagem, {this.notificacaoAgendada = false});
}

/// Equivalente aos dois useEffect de alerta do ContextoApp.jsx do web. Enquanto
/// há um PACIENTE logado, a cada [intervalo] (30 s, igual ao web):
/// 1. "Lembrar agora": busca o paciente na API; se o cuidador deixou um alerta
///    pendente, avisa e confirma o recebimento (o servidor limpa o pendente);
/// 2. "Hora do remédio": se alguma dose não tomada chegou ao horário (janela de
///    1 minuto), avisa — uma única vez por dose.
/// Com um CUIDADOR logado, a cada [intervalo] avisa uma vez quando a dose de um
/// paciente fica atrasada (só com o app aberto; o status também fica no painel).
/// Ouve o [AppEstado] pra ligar ao entrar e desligar ao sair.
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
    verificarAgora(); // igual ao web: verifica já ao entrar, sem esperar 30 s
  }

  void _parar() {
    _timer?.cancel();
    _timer = null;
    _pacienteMonitorado = null;
    _cuidadorMonitorado = null;
    _dosesAvisadas.clear();
  }

  /// Uma rodada de verificação (público pra teste).
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
    // Em segundo plano os dados não atualizam: o aviso poderia ser de uma dose já tomada.
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
    if (_verificandoManual) return; // evita avisar duas vezes se uma rodada atrasar
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
      // Falha de rede numa verificação periódica não interrompe o uso do app.
    } finally {
      _verificandoManual = false;
    }
  }

  void dispose() {
    estado.removeListener(_sincronizar);
    _parar();
  }
}
