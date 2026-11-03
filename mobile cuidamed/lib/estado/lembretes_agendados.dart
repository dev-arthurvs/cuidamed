import '../modelos/historico.dart';
import '../modelos/medicamento.dart';
import '../utilitarios/horarios.dart';
import 'app_estado.dart';

/// Um lembrete de "Hora do remédio" agendado no próprio celular: toca mesmo com
/// o app fechado.
class LembreteAgendado {
  final int id;
  final DateTime quando;
  final String titulo;
  final String corpo;
  const LembreteAgendado({required this.id, required this.quando, required this.titulo, required this.corpo});
}

/// Doses dos próximos [dias] que ainda vão acontecer e não foram registradas,
/// da mais próxima para a mais distante. O [limite] existe porque o sistema
/// aceita um número máximo de agendamentos por app.
List<LembreteAgendado> lembretesParaAgendar(
  List<Medicamento> medicamentos,
  List<Historico> historico, {
  required DateTime agora,
  int dias = 7,
  int limite = 60,
}) {
  final registrados = historico.map((h) => '${h.medicamentoId}|${dataAtualISO(h.data)}|${h.hora}').toSet();
  final doses = <({DateTime quando, Medicamento medicamento})>[];
  final hoje = DateTime(agora.year, agora.month, agora.day);
  for (var i = 0; i < dias; i++) {
    final dia = DateTime(hoje.year, hoje.month, hoje.day + i);
    final diaIso = dataAtualISO(dia);
    for (final medicamento in medicamentos) {
      if (!temDoseNoDia(medicamento, diaIso: diaIso)) continue;
      for (final horario in medicamento.horarios) {
        final minutos = paraMinutos(horario);
        final quando = DateTime(dia.year, dia.month, dia.day, minutos ~/ 60, minutos % 60);
        if (!quando.isAfter(agora) || registrados.contains('${medicamento.id}|$diaIso|$horario')) continue;
        doses.add((quando: quando, medicamento: medicamento));
      }
    }
  }
  doses.sort((a, b) => a.quando.compareTo(b.quando));
  return [
    for (final (indice, dose) in doses.take(limite).indexed)
      LembreteAgendado(
        id: 100000 + indice, // longe dos ids das notificações imediatas
        quando: dose.quando,
        titulo: 'Hora do remédio 💊',
        corpo: dose.medicamento.dosagem.isEmpty
            ? 'Está na hora de tomar ${dose.medicamento.nome}.'
            : 'Está na hora de tomar ${dose.medicamento.nome} (${dose.medicamento.dosagem}).',
      ),
  ];
}

/// Mantém os lembretes do celular iguais à agenda do paciente logado: reagenda
/// quando a agenda ou o histórico mudam e cancela tudo ao sair da conta.
class LembretesAgendados {
  final AppEstado estado;
  final Future<void> Function(List<LembreteAgendado> lembretes) agendar;
  final Future<void> Function() cancelar;
  final DateTime Function() agora;

  String? _assinatura;

  LembretesAgendados({required this.estado, required this.agendar, required this.cancelar, DateTime Function()? agora})
      : agora = agora ?? DateTime.now {
    estado.addListener(_sincronizar);
    _sincronizar();
  }

  void _sincronizar() {
    final dados = estado.usuario?.tipo == 'paciente' ? estado.pacienteFoco : null;
    if (dados == null) {
      if (_assinatura != null) {
        _assinatura = null;
        cancelar();
      }
      return;
    }
    final lembretes = lembretesParaAgendar(dados.medicamentos, dados.historico, agora: agora());
    final assinatura = lembretes.map((l) => '${l.quando.millisecondsSinceEpoch}:${l.corpo}').join('|');
    if (assinatura == _assinatura) return;
    _assinatura = assinatura;
    agendar(lembretes);
  }

  void dispose() => estado.removeListener(_sincronizar);
}
