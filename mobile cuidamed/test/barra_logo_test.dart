import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cuidamed_mobile/componentes/barra_logo.dart';
import 'package:cuidamed_mobile/componentes/cabecalho.dart';
import 'package:cuidamed_mobile/paginas/acessibilidade.dart';
import 'package:cuidamed_mobile/paginas/agenda_medicamentos.dart';
import 'package:cuidamed_mobile/paginas/chat.dart';
import 'package:cuidamed_mobile/paginas/edicao_perfil.dart';
import 'package:cuidamed_mobile/paginas/historico.dart';
import 'package:cuidamed_mobile/paginas/painel_cuidador.dart';
import 'package:cuidamed_mobile/paginas/painel_idoso.dart';

import 'apoio.dart';

void main() {
  final telas = <(String, Widget Function(GoRouterState), bool)>[
    ('/painel', (_) => const PainelIdoso(), false),
    ('/painel', (_) => const PainelCuidador(), true),
    ('/agenda', (_) => const AgendaMedicamentos(), false),
    ('/agenda?aba=encerrados', (_) => const AgendaMedicamentos(), false),
    ('/historico', (_) => const HistoricoPagina(), false),
    ('/configuracoes', (_) => const EdicaoPerfil(), false),
    ('/acessibilidade', (_) => const Acessibilidade(), false),
    ('/chat', (_) => Chat(perguntar: (_, _) async => ''), false),
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

  testWidgets('Logo à esquerda e "?" à direita com folga da borda, na faixa de cima', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
    final faixa = find.byType(BarraComLogo);
    final logo = tester.getRect(find.descendant(of: faixa, matching: find.byType(LogoCuidaMed)));
    final ajuda = tester.getRect(find.byTooltip('Ajuda desta tela'));
    final cabecalho = tester.getRect(find.byType(Cabecalho));

    expect(logo.left, closeTo(20, 8)); // a logo abre a faixa
    expect(ajuda.center.dy, closeTo(logo.center.dy, 2)); // "?" na faixa de cima
    expect(ajuda.bottom, lessThanOrEqualTo(cabecalho.top + 1));
    expect(360 - ajuda.right, greaterThanOrEqualTo(12)); // afastado da borda direita
    expect(360 - ajuda.right, lessThanOrEqualTo(24)); // mas encostado no canto, não no meio

    // Engrenagem (Configurações) logo à esquerda do "?", na mesma linha.
    final engrenagem = tester.getRect(find.byTooltip('Configurações'));
    expect(engrenagem.right, lessThanOrEqualTo(ajuda.left + 1));
    expect(engrenagem.center.dy, closeTo(ajuda.center.dy, 2));

    // O cabeçalho da tela não repete os botões.
    expect(find.descendant(of: find.byType(Cabecalho), matching: find.byIcon(Icons.help_outline)), findsNothing);
  });

  testWidgets('320px com fonte grande: logo, engrenagem e "?" cabem na faixa', (tester) async {
    await montarPagina(tester, estadoPaciente()..tamanhoFonte = 'grande', '/historico', (_) => const HistoricoPagina(),
        tamanho: const Size(320, 800));
    expect(find.byTooltip('Configurações'), findsOneWidget);
    expect(find.byTooltip('Ajuda desta tela'), findsOneWidget);
    expect(tester.getRect(find.byTooltip('Ajuda desta tela')).right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tela larga: engrenagem e "?" continuam no canto direito', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina(), tamanho: const Size(1000, 800));
    final ajuda = tester.getRect(find.byTooltip('Ajuda desta tela'));
    final engrenagem = tester.getRect(find.byTooltip('Configurações'));
    expect(1000 - ajuda.right, lessThanOrEqualTo(24));
    expect(engrenagem.right, lessThanOrEqualTo(ajuda.left + 1));
    expect(ajuda.left - engrenagem.right, lessThan(20)); // lado a lado, sem buraco entre eles
  });

  testWidgets('Tocar na engrenagem abre as Configurações', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('rota /configuracoes'), findsOneWidget);
  });

  testWidgets('Barra inferior com Histórico cabe em 360px com fonte grande', (tester) async {
    for (final estado in [estadoPaciente(), estadoCuidador()]) {
      estado.tamanhoFonte = 'grande';
      await montarPagina(tester, estado, '/historico', (_) => const HistoricoPagina());
      expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Histórico')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
