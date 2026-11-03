import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/paginas/agenda_medicamentos.dart';
import 'package:cuidamed_mobile/paginas/historico.dart';
import 'package:cuidamed_mobile/paginas/painel_idoso.dart';
import 'package:cuidamed_mobile/modelos/historico.dart';
import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/estado/app_estado.dart';

import 'apoio.dart';

void main() {
  testWidgets('Agenda abre em "Em uso" (só ativos) e abre o formulário de inserção', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/agenda', (_) => const AgendaMedicamentos());
    expect(find.text('1 medicamento em uso'), findsOneWidget);
    expect(find.text('Losartana'), findsOneWidget);
    expect(find.text('Amoxicilina'), findsNothing); // tratamento já encerrado
    expect(find.text('Em uso'), findsOneWidget);
    expect(find.text('Encerrados'), findsOneWidget);

    await rolarAte(tester, find.text('+ Inserir medicamento'));
    await tester.tap(find.text('+ Inserir medicamento'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Agenda no padrão do web: sem botão flutuante, ações no topo e confirmação de exclusão', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/agenda', (_) => const AgendaMedicamentos());
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Agenda de Maria'.toUpperCase()), findsOneWidget);
    final abas = tester.getRect(find.text('Encerrados'));
    final inserir = tester.getRect(find.text('+ Inserir medicamento'));
    expect(inserir.top, greaterThan(abas.bottom)); // celular: empilhado abaixo das abas
    expect(find.textContaining('Cadastre, edite ou remova'), findsNothing); // sem texto de finalidade

    await rolarAte(tester, find.text('Excluir'));
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir medicamento?'), findsOneWidget);
    expect(find.text('Sim, excluir'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir medicamento?'), findsNothing);
    expect(find.text('Losartana'), findsOneWidget);

    // Tela larga: abas à esquerda e o botão na mesma linha, à direita, como no web.
    await montarPagina(tester, estadoCuidador(), '/agenda', (_) => const AgendaMedicamentos(), tamanho: const Size(1200, 900));
    final d = tester.getRect(find.text('Encerrados'));
    final b = tester.getRect(find.text('+ Inserir medicamento'));
    expect(b.center.dy, closeTo(d.center.dy, 14));
    expect(b.left, greaterThan(d.right));
    expect(b.right, greaterThan(1000));
  });

  testWidgets('Paciente com cuidador e sem permissão: não insere nem edita', (tester) async {
    await montarPagina(
        tester, estadoPaciente(cuidadorId: 5, permiteAlteracoes: false), '/agenda', (_) => const AgendaMedicamentos());
    expect(find.text('+ Inserir medicamento'), findsNothing);
    expect(find.textContaining('ainda não liberou alterações'), findsOneWidget);
    expect(find.text('Editar'), findsNothing);
  });

  testWidgets('Paciente sem cuidador (cadastro próprio) cuida da própria agenda', (tester) async {
    await montarPagina(tester, estadoPaciente(permiteAlteracoes: false), '/agenda', (_) => const AgendaMedicamentos());
    expect(find.text('+ Inserir medicamento'), findsOneWidget);
    expect(find.textContaining('ainda não liberou alterações'), findsNothing);
  });

  testWidgets('Aba "Encerrados" lista o tratamento vencido, sem inserir/editar', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/agenda', (_) => const AgendaMedicamentos());
    await tester.tap(find.text('Encerrados'));
    await tester.pumpAndSettle();
    expect(find.text('1 tratamento encerrado'), findsOneWidget);
    expect(find.text('Amoxicilina'), findsOneWidget);
    expect(find.text('Losartana'), findsNothing);
    expect(find.textContaining('Tratamento de '), findsOneWidget);
    expect(find.text('+ Inserir medicamento'), findsNothing);
    expect(find.text('Editar'), findsNothing);

    // Volta para "Em uso".
    await tester.tap(find.text('Em uso'));
    await tester.pumpAndSettle();
    expect(find.text('Losartana'), findsOneWidget);
    expect(find.text('Amoxicilina'), findsNothing);
  });

  testWidgets('?aba=encerrados abre direto na aba "Encerrados"', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/agenda?aba=encerrados', (_) => const AgendaMedicamentos());
    expect(find.text('Amoxicilina'), findsOneWidget);
    expect(find.text('Losartana'), findsNothing);
  });

  testWidgets('Encerrados: sem exclusão e card com 1/3 da largura em tela larga', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/agenda?aba=encerrados', (_) => const AgendaMedicamentos(),
        tamanho: const Size(1400, 900));
    expect(find.text('Excluir'), findsNothing);
    final lista = tester.getSize(find.byType(LayoutBuilder).last).width;
    final card = tester.getSize(find.ancestor(of: find.text('Amoxicilina'), matching: find.byType(SizedBox)).last).width;
    expect(card, closeTo((lista - 28) / 3, 1)); // um card só não estica na linha toda
  });

  testWidgets('Histórico filtra por datas De/Até (padrão: só hoje)', (tester) async {
    final estado = estadoPaciente();
    final dados = estado.pacientes.first;
    final hoje = DateTime.now();
    final antiga = DateTime(hoje.year, hoje.month, hoje.day).subtract(const Duration(days: 10));
    dados.historico.add(Historico(
      id: 101, pacienteId: 1, medicamentoId: 11, data: antiga, hora: '06:00',
      nomeMedicamento: 'Amoxicilina', dosagem: '500mg', status: 'PERDIDO',
    ));
    await montarPagina(tester, estado, '/historico', (_) => const HistoricoPagina());
    expect(find.text('7 dias'), findsNothing); // os botões de período saíram
    expect(find.text('De'), findsOneWidget);
    expect(find.text('Até'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('06:00'), findsNothing); // registro de 10 dias atrás fora do padrão "hoje"

    // "De" = 10 dias atrás, digitada no calendário em português (dia/mês/ano).
    await tester.tap(find.text('De'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar'), findsOneWidget); // calendário em português
    await tester.tap(find.byIcon(Icons.edit_outlined)); // modo de digitação
    await tester.pumpAndSettle();
    String dd(int n) => n.toString().padLeft(2, '0');
    await tester.enterText(find.byType(TextField).last, '${dd(antiga.day)}/${dd(antiga.month)}/${antiga.year}');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // O registro de 10 dias atrás aparece, junto com as doses daqueles dias que
    // passaram sem registro (contam como perdidas, como no Início).
    expect(find.text('08:00'), findsWidgets);
    // Os mais antigos ficam no fim da lista: rola até aparecerem.
    for (var i = 0; i < 40 && find.text('06:00').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pump();
    }
    expect(find.text('Amoxicilina'), findsWidgets);
    expect(find.text('06:00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Histórico mostra a dose de hoje e o resumo', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
    expect(find.text('Losartana'), findsWidgets);
    expect(find.text('08:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Telas antigas com fonte grande em 360px não estouram', (tester) async {
    for (final (rota, pagina) in [
      ('/agenda', const AgendaMedicamentos() as Widget),
      ('/agenda?aba=encerrados', const AgendaMedicamentos()),
      ('/historico', const HistoricoPagina()),
    ]) {
      await montarPagina(tester, estadoPaciente()..tamanhoFonte = 'grande', rota, (_) => pagina);
      expect(tester.takeException(), isNull, reason: rota);
    }
  });

  testWidgets('Formulário de medicamento com fonte grande não estoura', (tester) async {
    await montarPagina(tester, estadoCuidador()..tamanhoFonte = 'grande', '/agenda', (_) => const AgendaMedicamentos());
    await rolarAte(tester, find.text('+ Inserir medicamento'));
    await tester.tap(find.text('+ Inserir medicamento'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Card do próximo medicamento mostra a quantidade por dose (ou a dosagem, se não houver)', (tester) async {
    // Dose às 23:59: é sempre a próxima, a qualquer hora que o teste rode.
    AppEstado estadoCom({int? porDose}) {
      final estado = estadoPaciente();
      final dados = estado.pacientes.first;
      final m = dados.medicamentos.first;
      estado.pacientes = [
        PacienteComDados(paciente: dados.paciente, historico: const [], medicamentos: [
          Medicamento(
            id: m.id, pacienteId: m.pacienteId, nome: m.nome, dosagem: m.dosagem, forma: m.forma,
            frequencia: m.frequencia, dataInicio: m.dataInicio, horarios: const ['23:59'], quantidadePorDose: porDose,
          ),
        ]),
      ];
      return estado;
    }

    await montarPagina(tester, estadoCom(porDose: 1), '/painel', (_) => const PainelIdoso());
    expect(find.text('1 comp'), findsOneWidget); // 1 comprimido por dose
    expect(find.text('50mg'), findsNothing);

    // Sem quantidade por dose cadastrada: mostra a dosagem, como o lembrete do WhatsApp.
    await montarPagina(tester, estadoCom(), '/painel', (_) => const PainelIdoso());
    expect(find.text('50mg'), findsOneWidget);
  });
}
