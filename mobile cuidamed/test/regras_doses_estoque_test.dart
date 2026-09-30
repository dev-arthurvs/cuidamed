import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/modelos/historico.dart';
import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/paginas/agenda_medicamentos.dart';
import 'package:cuidamed_mobile/paginas/painel_idoso.dart';
import 'package:cuidamed_mobile/utilitarios/horarios.dart';

import 'apoio.dart';

const _hoje = '2026-09-24';

Medicamento _med({
  int id = 5,
  String inicio = '2026-09-20',
  String? fim = '2026-10-03',
  int? estoque,
  int? porDose = 1,
  List<String> horarios = const ['08:00', '20:00'],
}) =>
    Medicamento(
      id: id,
      pacienteId: 1,
      nome: 'Remédio',
      dosagem: '10mg',
      forma: 'COMPRIMIDO',
      frequencia: 'DUAS_VEZES_AO_DIA',
      dataInicio: DateTime.parse(inicio),
      dataFim: fim == null ? null : DateTime.parse(fim),
      horarios: horarios,
      quantidadeEstoque: estoque,
      quantidadePorDose: porDose,
    );

Historico _tomada(int medicamentoId, String data) => Historico(
      id: 1,
      pacienteId: 1,
      medicamentoId: medicamentoId,
      data: DateTime.parse(data),
      hora: '08:00',
      nomeMedicamento: 'Remédio',
      dosagem: '10mg',
      status: 'TOMADO',
    );

void main() {
  group('Doses de hoje respeitam a data de início', () {
    test('início amanhã não gera dose hoje', () {
      expect(construirDosesHoje([_med(inicio: '2026-09-25')], [], hojeIso: _hoje), isEmpty);
    });
    test('início hoje gera as doses do dia', () {
      expect(construirDosesHoje([_med(inicio: _hoje)], [], hojeIso: _hoje), hasLength(2));
    });
    test('início no passado gera as doses do dia', () {
      expect(construirDosesHoje([_med(inicio: '2026-09-01')], [], hojeIso: _hoje), hasLength(2));
    });
  });

  group('Estoque x fim do tratamento (mesmos cenários do web)', () {
    // 2x/dia, 1 comp; de hoje (nenhuma tomada) até 03/10 = 10 dias = 20 comp.
    test('20 comp para 20 doses restantes: dura até o fim', () {
      final e = calcularEstoque(_med(estoque: 20), hojeIso: _hoje)!;
      expect(e.duraAteOFim, isTrue);
      expect(e.baixo, isFalse);
    });
    test('19 comp para 20 doses: não cobre', () {
      expect(calcularEstoque(_med(estoque: 19), hojeIso: _hoje)!.duraAteOFim, isFalse);
    });
    test('já tomou 1 hoje (já descontada do estoque): 19 comp cobrem as 19 restantes', () {
      final e = calcularEstoque(_med(estoque: 19), historico: [_tomada(5, _hoje)], hojeIso: _hoje)!;
      expect(e.duraAteOFim, isTrue);
    });
    test('caso relatado: termina em 2 dias e o estoque cobre — não pede reposição', () {
      final e = calcularEstoque(_med(fim: '2026-09-26', estoque: 6), hojeIso: _hoje)!;
      expect(e.duraAteOFim, isTrue);
      expect(e.baixo, isFalse); // antes: "Estoque baixo… Hora de repor."
    });
    test('começa amanhã: conta o ciclo inteiro (3 dias x 2 = 6 comp)', () {
      final e = calcularEstoque(_med(inicio: '2026-09-25', fim: '2026-09-27', estoque: 6), hojeIso: _hoje)!;
      expect(e.duraAteOFim, isTrue);
    });
    test('uso contínuo (sem fim): regra antiga, "baixo" com até 5 dias', () {
      final e = calcularEstoque(_med(fim: null, estoque: 8), hojeIso: _hoje)!;
      expect(e.duraAteOFim, isFalse);
      expect(e.baixo, isTrue);
    });
    test('estoque zerado com doses pela frente: esgotado', () {
      expect(calcularEstoque(_med(estoque: 0), hojeIso: _hoje)!.esgotado, isTrue);
    });
    test('2 comp por dose: 4 doses restantes pedem 8 comp', () {
      final e = calcularEstoque(_med(porDose: 2, fim: '2026-09-25', estoque: 8), hojeIso: _hoje)!;
      expect(e.duraAteOFim, isTrue);
    });
  });

  group('Telas', () {
    AppEstado estadoCom(Medicamento medicamento) {
      final estado = estadoPaciente();
      final dados = estado.pacientes.first;
      estado.pacientes = [PacienteComDados(paciente: dados.paciente, medicamentos: [medicamento], historico: const [])];
      return estado;
    }

    DateTime diaRelativo(int dias) {
      final agora = DateTime.now();
      return DateTime(agora.year, agora.month, agora.day).add(Duration(days: dias));
    }

    String iso(DateTime d) => dataAtualISO(d);

    testWidgets('Agenda: tratamento que começa amanhã mostra "Começa em"', (tester) async {
      final amanha = diaRelativo(1);
      await montarPagina(tester, estadoCom(_med(inicio: iso(amanha), fim: iso(diaRelativo(10)), estoque: 100)), '/agenda',
          (_) => const AgendaMedicamentos());
      final data = '${amanha.day.toString().padLeft(2, '0')}/${amanha.month.toString().padLeft(2, '0')}/${amanha.year}';
      expect(find.text('Começa em $data'), findsOneWidget);
    });

    testWidgets('Agenda: estoque que cobre o tratamento diz que não precisa comprar', (tester) async {
      // Termina depois de amanhã; 2 doses/dia -> no máximo 6 comp restantes; tem 6.
      await montarPagina(tester, estadoCom(_med(inicio: iso(diaRelativo(-3)), fim: iso(diaRelativo(2)), estoque: 6)),
          '/agenda', (_) => const AgendaMedicamentos());
      expect(find.textContaining('✅ Estoque suficiente — (até '), findsOneWidget);
      expect(find.textContaining('Estoque baixo'), findsNothing);
    });

    testWidgets('Início do paciente: remédio que começa amanhã não aparece como dose de hoje', (tester) async {
      await montarPagina(tester, estadoCom(_med(inicio: iso(diaRelativo(1)), fim: iso(diaRelativo(10)))), '/painel',
          (_) => const PainelIdoso());
      expect(find.text('Nada pendente'), findsOneWidget);
      expect(find.text('Remédio'), findsNothing);
    });
  });
}
