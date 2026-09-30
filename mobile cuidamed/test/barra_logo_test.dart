import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cuidamed_mobile/componentes/barra_logo.dart';
import 'package:cuidamed_mobile/componentes/cabecalho.dart';
import 'package:cuidamed_mobile/paginas/acessibilidade.dart';
import 'package:cuidamed_mobile/paginas/agenda_medicamentos.dart';
import 'package:cuidamed_mobile/paginas/chat.dart';
import 'package:cuidamed_mobile/paginas/ciclos_encerrados.dart';
import 'package:cuidamed_mobile/paginas/edicao_perfil.dart';
import 'package:cuidamed_mobile/paginas/historico.dart';
import 'package:cuidamed_mobile/paginas/painel_cuidador.dart';
import 'package:cuidamed_mobile/paginas/painel_idoso.dart';
import 'package:cuidamed_mobile/paginas/painel_paciente.dart';

import 'apoio.dart';

void main() {
  final telas = <(String, Widget Function(GoRouterState), bool)>[
    ('/painel', (_) => const PainelIdoso(), false),
    ('/painel', (_) => const PainelCuidador(), true),
    ('/agenda', (_) => const AgendaMedicamentos(), false),
    ('/ciclos-encerrados', (_) => const CiclosEncerrados(), false),
    ('/historico', (_) => const HistoricoPagina(), false),
    ('/perfil', (_) => const EdicaoPerfil(), false),
    ('/acessibilidade', (_) => const Acessibilidade(), false),
    ('/chat', (_) => Chat(perguntar: (_, _) async => ''), false),
    ('/cuidador/paciente/1/painel', (_) => const PainelPaciente(pacienteId: 1), true),
  ];

  for (final (rota, tela, cuidador) in telas) {
    testWidgets('Logo no topo acima do cabeçalho: $rota ${cuidador ? '(cuidador)' : ''}', (tester) async {
      await montarPagina(tester, cuidador ? estadoCuidador() : estadoPaciente(), rota, tela);
      expect(find.byType(BarraComLogo), findsOneWidget);
      final logo = tester.getRect(find.descendant(of: find.byType(BarraComLogo), matching: find.byType(LogoCuidaMed)));
      final cabecalho = tester.getRect(find.byType(Cabecalho));
      expect(logo.bottom, lessThanOrEqualTo(cabecalho.top));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Tocar na logo leva ao Início', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
    await tester.tap(find.bySemanticsLabel('Ir para o início'));
    await tester.pumpAndSettle();
    expect(find.text('rota /painel'), findsOneWidget);
  });

  testWidgets('Com barra de status (entalhe), a logo fica abaixo dela', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.resetPadding);
    await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
    final logo = tester.getRect(find.byType(LogoCuidaMed).first);
    expect(logo.top, greaterThanOrEqualTo(40));
    final cabecalho = tester.getRect(find.byType(Cabecalho));
    expect(cabecalho.top, lessThan(40 + BarraComLogo.alturaFaixa + 2)); // sem espaço duplicado da barra de status
    expect(tester.takeException(), isNull);
  });

  testWidgets('☰ à esquerda da logo e "?" à direita com folga da borda, na faixa de cima', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
    final faixa = find.byType(BarraComLogo);
    final menu = tester.getRect(find.descendant(of: faixa, matching: find.byTooltip('Abrir menu')));
    final logo = tester.getRect(find.descendant(of: faixa, matching: find.byType(LogoCuidaMed)));
    final ajuda = tester.getRect(find.byTooltip('Ajuda desta tela'));
    final cabecalho = tester.getRect(find.byType(Cabecalho));

    expect(menu.right, lessThanOrEqualTo(logo.left + 1)); // ☰ antes da logo
    expect(menu.center.dy, closeTo(logo.center.dy, 2)); // mesma linha
    expect(ajuda.center.dy, closeTo(logo.center.dy, 2)); // "?" na faixa de cima
    expect(ajuda.bottom, lessThanOrEqualTo(cabecalho.top + 1));
    expect(360 - ajuda.right, greaterThanOrEqualTo(12)); // afastado da borda direita

    // O cabeçalho da tela não repete os botões.
    expect(find.descendant(of: find.byType(Cabecalho), matching: find.byIcon(Icons.menu)), findsNothing);
    expect(find.descendant(of: find.byType(Cabecalho), matching: find.byIcon(Icons.help_outline)), findsNothing);
  });

  testWidgets('Tocar no ☰ abre o menu lateral', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta'), findsOneWidget);
  });
}
