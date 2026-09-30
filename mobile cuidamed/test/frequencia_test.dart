import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/modelos/historico.dart';
import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/paginas/agenda_medicamentos.dart';
import 'package:cuidamed_mobile/paginas/painel_idoso.dart';
import 'package:cuidamed_mobile/utilitarios/horarios.dart';

import 'apoio.dart';

Medicamento _med({
  int id = 1,
  required String frequencia,
  List<String> horarios = const ['08:00'],
  required String inicio,
  String? fim,
  int? estoque,
  int? porDose = 1,
}) =>
    Medicamento(
      id: id,
      pacienteId: 1,
      nome: 'Remédio',
      dosagem: '10mg',
      forma: 'COMPRIMIDO',
      frequencia: frequencia,
      dataInicio: DateTime.parse(inicio),
      dataFim: fim == null ? null : DateTime.parse(fim),
      horarios: horarios,
      quantidadeEstoque: estoque,
      quantidadePorDose: porDose,
    );

void main() {
  // Mesmos cenários validados no web.
  final alt = _med(frequencia: 'DIAS_ALTERNADOS', inicio: '2026-09-20');
  final sem = _med(id: 2, frequencia: 'SEMANAL', horarios: const ['09:00'], inicio: '2026-09-17', fim: '2026-10-15');

  test('Dias alternados: 20 sim, 21 não, 22 sim', () {
    expect(temDoseNoDia(alt, diaIso: '2026-09-20'), isTrue);
    expect(temDoseNoDia(alt, diaIso: '2026-09-21'), isFalse);
    expect(temDoseNoDia(alt, diaIso: '2026-09-22'), isTrue);
  });
  test('Dias alternados: sem dose no dia 23, com dose no 24', () {
    expect(construirDosesHoje([alt], [], hojeIso: '2026-09-23'), isEmpty);
    expect(construirDosesHoje([alt], [], hojeIso: '2026-09-24'), hasLength(1));
    expect(proximoDiaDeDose(alt, aPartirIso: '2026-09-23'), '2026-09-24');
  });
  test('Semanal: 24 sim, 25 não, 01/10 sim; nada depois do fim', () {
    expect(temDoseNoDia(sem, diaIso: '2026-09-24'), isTrue);
    expect(temDoseNoDia(sem, diaIso: '2026-09-25'), isFalse);
    expect(temDoseNoDia(sem, diaIso: '2026-10-01'), isTrue);
    expect(proximoDiaDeDose(sem, aPartirIso: '2026-09-25'), '2026-10-01');
    expect(temDoseNoDia(sem, diaIso: '2026-10-22'), isFalse);
  });
  test('Frequências diárias continuam todo dia', () {
    final diario = _med(frequencia: 'DUAS_VEZES_AO_DIA', horarios: const ['08:00', '20:00'], inicio: '2026-09-01');
    expect(construirDosesHoje([diario], [], hojeIso: '2026-09-23'), hasLength(2));
  });
  test('Estoque semanal conta só os dias de dose (3 doses até o fim, não 21)', () {
    final m = _med(id: 2, frequencia: 'SEMANAL', horarios: const ['09:00'], inicio: '2026-09-17', fim: '2026-10-15', estoque: 3);
    expect(calcularEstoque(m, hojeIso: '2026-09-25')!.duraAteOFim, isTrue);
    final pouco = _med(id: 2, frequencia: 'SEMANAL', horarios: const ['09:00'], inicio: '2026-09-17', fim: '2026-10-15', estoque: 2);
    expect(calcularEstoque(pouco, hojeIso: '2026-09-25')!.duraAteOFim, isFalse);
  });
  test('Estoque semanal: dose de hoje já tomada não é contada de novo', () {
    final m = _med(id: 2, frequencia: 'SEMANAL', horarios: const ['09:00'], inicio: '2026-09-17', fim: '2026-10-15', estoque: 3);
    final tomada = Historico(
      id: 1, pacienteId: 1, medicamentoId: 2, data: DateTime(2026, 9, 24), hora: '09:00',
      nomeMedicamento: 'Remédio', dosagem: '10mg', status: 'TOMADO',
    );
    expect(calcularEstoque(m, historico: [tomada], hojeIso: '2026-09-24')!.duraAteOFim, isTrue);
  });
  test('Dias alternados em uso contínuo: 4 comp duram ~8 dias', () {
    final m = _med(frequencia: 'DIAS_ALTERNADOS', inicio: '2026-09-20', estoque: 4);
    expect(calcularEstoque(m, hojeIso: '2026-09-24')!.diasRestantes, 8);
  });
  test('Fim num dia sem dose: ciclo encerrado', () {
    final m = _med(frequencia: 'DIAS_ALTERNADOS', inicio: '2026-09-20', fim: '2026-09-23');
    expect(medicamentoEncerrado(m, hojeIso: '2026-09-23'), isTrue);
  });

  testWidgets('Agenda mostra "Próxima dose" quando hoje não é dia de dose', (tester) async {
    final agora = DateTime.now();
    final ontem = DateTime(agora.year, agora.month, agora.day).subtract(const Duration(days: 1));
    final amanha = ontem.add(const Duration(days: 2));
    final estado = estadoPaciente();
    final dados = estado.pacientes.first;
    estado.pacientes = [
      PacienteComDados(paciente: dados.paciente, historico: const [], medicamentos: [
        _med(frequencia: 'DIAS_ALTERNADOS', inicio: dataAtualISO(ontem)), // ontem sim, hoje não, amanhã sim
      ]),
    ];
    await montarPagina(tester, estado, '/agenda', (_) => const AgendaMedicamentos());
    final data = '${amanha.day.toString().padLeft(2, '0')}/${amanha.month.toString().padLeft(2, '0')}/${amanha.year}';
    expect(find.text('Próxima dose: $data'), findsOneWidget);
  });

  testWidgets('Card "Próximo medicamento" só mostra doses do dia (dias alternados)', (tester) async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    AppEstado estadoComInicio(DateTime inicio) {
      final estado = estadoPaciente();
      final dados = estado.pacientes.first;
      estado.pacientes = [
        PacienteComDados(paciente: dados.paciente, historico: const [], medicamentos: [
          // 23:59: se houver dose hoje, ela é sempre a "próxima", a qualquer hora do teste.
          _med(frequencia: 'DIAS_ALTERNADOS', horarios: const ['23:59'], inicio: dataAtualISO(inicio)),
        ]),
      ];
      return estado;
    }

    // Começou ontem: hoje NÃO é dia de dose -> card vazio, nada nos contadores.
    await montarPagina(tester, estadoComInicio(hoje.subtract(const Duration(days: 1))), '/painel',
        (_) => const PainelIdoso());
    expect(find.text('Nada pendente'), findsOneWidget);
    expect(find.text('Remédio'), findsNothing);
    expect(find.text('Registrar dose'), findsNothing);

    // Controle: começou anteontem -> hoje É dia de dose -> aparece no card.
    await montarPagina(tester, estadoComInicio(hoje.subtract(const Duration(days: 2))), '/painel',
        (_) => const PainelIdoso());
    expect(find.text('Registrar dose'), findsOneWidget);
    expect(find.text('Remédio'), findsWidgets);
  });
}
