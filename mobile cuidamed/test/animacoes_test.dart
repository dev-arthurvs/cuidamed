import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/componentes/botao.dart';
import 'package:cuidamed_mobile/componentes/confirmacao.dart';
import 'package:cuidamed_mobile/paginas/agenda_medicamentos.dart';
import 'package:cuidamed_mobile/paginas/historico.dart';
import 'package:cuidamed_mobile/utilitarios/animacoes.dart';
import 'package:cuidamed_mobile/utilitarios/tema.dart';

import 'apoio.dart';

double _opacidade(WidgetTester tester, Finder dentroDe) =>
    tester.widget<Opacity>(find.ancestor(of: dentroDe, matching: find.byType(Opacity)).first).opacity;

Widget _app(Widget filho, {bool semAnimacao = false}) => MaterialApp(
      theme: construirTema(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: semAnimacao),
        child: Scaffold(body: filho),
      ),
    );

void main() {
  testWidgets('Item de lista entra com fade, deslize e escala (0,22 s)', (tester) async {
    await tester.pumpWidget(_app(const EntradaSuave(child: Text('item'))));
    expect(_opacidade(tester, find.text('item')), lessThan(0.1));
    await tester.pump(const Duration(milliseconds: 110));
    final meio = _opacidade(tester, find.text('item'));
    expect(meio, inExclusiveRange(0.1, 1.0));
    await tester.pump(const Duration(milliseconds: 150));
    expect(_opacidade(tester, find.text('item')), 1.0);
  });

  testWidgets('Cascata: itens seguintes começam depois (atraso máximo de 240 ms)', (tester) async {
    await tester.pumpWidget(_app(const Column(children: [
      EntradaSuave(indice: 0, child: Text('a')),
      EntradaSuave(indice: 3, child: Text('b')),
      EntradaSuave(indice: 50, child: Text('c')),
    ])));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacidade(tester, find.text('a')), greaterThan(_opacidade(tester, find.text('b'))));
    await tester.pump(const Duration(milliseconds: 150)); // passa do atraso máximo (240 ms)
    expect(_opacidade(tester, find.text('c')), lessThan(1.0));
    await tester.pumpAndSettle(); // e termina, mesmo com índice 50 (atraso limitado)
    expect(_opacidade(tester, find.text('c')), 1.0);
  });

  testWidgets('"Reduzir movimento" do sistema: aparece na hora, sem animar', (tester) async {
    await tester.pumpWidget(_app(const EntradaSuave(indice: 5, child: Text('item')), semAnimacao: true));
    expect(_opacidade(tester, find.text('item')), 1.0);
  });

  testWidgets('Troca de tela usa a transição do CuidaMed (0,22 s)', (tester) async {
    final tema = construirTema();
    expect(tema.pageTransitionsTheme.builders[TargetPlatform.android], isA<TransicaoPaginaCuidaMed>());
    expect(tema.pageTransitionsTheme.builders[TargetPlatform.iOS], isA<TransicaoPaginaCuidaMed>());

    await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
    await tester.tap(find.bySemanticsLabel('Ir para o início'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacidade(tester, find.text('rota /painel')), inExclusiveRange(0.0, 1.0)); // no meio da transição
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('rota /painel'), findsOneWidget);
  });

  testWidgets('Confirmação abre animada e fecha', (tester) async {
    late BuildContext contexto;
    await tester.pumpWidget(_app(Builder(builder: (c) {
      contexto = c;
      return const SizedBox();
    })));
    final resultado = confirmarAcao(contexto, titulo: 'Excluir?', mensagem: 'Certeza?', textoConfirmar: 'Sim');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final caixa = find.ancestor(of: find.text('Excluir?'), matching: find.byType(FadeTransition)).first;
    expect(tester.widget<FadeTransition>(caixa).opacity.value, inExclusiveRange(0.0, 1.0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim'));
    await tester.pumpAndSettle();
    expect(await resultado, isTrue);
    expect(find.text('Excluir?'), findsNothing);
  });

  testWidgets('Botão afunda 1 px ao pressionar e volta ao soltar', (tester) async {
    await tester.pumpWidget(_app(Center(child: Botao(texto: 'Salvar', larguraTotal: false, onPressed: () {}))));
    final antes = tester.getRect(find.text('Salvar')).top;
    final gesto = await tester.startGesture(tester.getCenter(find.text('Salvar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getRect(find.text('Salvar')).top, closeTo(antes + 1, 0.01));
    await gesto.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getRect(find.text('Salvar')).top, closeTo(antes, 0.01));
  });

  testWidgets('Cards da agenda terminam visíveis e na posição final', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/agenda', (_) => const AgendaMedicamentos());
    expect(_opacidade(tester, find.text('Losartana')), 1.0);
    expect(tester.takeException(), isNull);
  });
}
