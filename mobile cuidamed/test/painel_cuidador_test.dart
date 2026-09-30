import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/componentes/data_hora_atual.dart';
import 'package:cuidamed_mobile/paginas/painel_cuidador.dart';

import 'apoio.dart';

const _celular = Size(360, 800);
const _desktop = Size(1300, 900);

void main() {
  test('Data por extenso e hora no formato do web', () {
    expect(formatarDataPorExtenso(DateTime(2026, 9, 24)), 'Quinta-feira, 24 de setembro');
    expect(formatarDataPorExtenso(DateTime(2026, 3, 1)), 'Domingo, 1 de março');
    expect(formatarHora(DateTime(2026, 9, 24, 8, 5)), '08:05');
  });

  testWidgets('Indicadores com as contas do web', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/painel', (_) => const PainelCuidador(), tamanho: _desktop);
    // estadoCuidador: 1 paciente, 2 medicamentos (1 ativo + 1 encerrado), 1 dose tomada.
    String valorDo(String rotulo) {
      final coluna = find.ancestor(of: find.text(rotulo).first, matching: find.byType(Column)).first;
      return tester.widgetList<Text>(find.descendant(of: coluna, matching: find.byType(Text))).first.data!;
    }

    expect(valorDo('Pacientes vinculados'), '1');
    expect(valorDo('Precisam de atenção'), isIn(['0', '1'])); // depende do horário em que o teste roda
    expect(valorDo('Adesão média (30 dias)'), '100%');
    expect(valorDo('Medicamentos monitorados'), '1'); // o encerrado não conta
    expect(find.textContaining('· 1 medicamentos'), findsOneWidget);
    expect(find.text('Acompanhe seus pacientes'), findsOneWidget);
  });

  testWidgets('Celular: faixa de data, avatar, 2x2 e botão abaixo do título', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/painel', (_) => const PainelCuidador(), tamanho: _celular);
    expect(find.byType(FaixaDataHora), findsOneWidget);
    expect(find.byType(DataHoraCabecalho), findsNothing);
    // Avatar do usuário logado no cabeçalho (os pacientes da lista também usam
    // AvatarUsuario, com descrição "Paciente: ...").
    expect(find.byWidgetPredicate((w) => w is AvatarUsuario && w.descricao == null), findsOneWidget);

    final p1 = tester.getRect(find.text('Pacientes vinculados').first);
    final p2 = tester.getRect(find.text('Precisam de atenção'));
    final p3 = tester.getRect(find.text('Adesão média (30 dias)'));
    expect(p2.top, closeTo(p1.top, 1)); // mesma linha
    expect(p3.top, greaterThan(p1.bottom)); // linha de baixo

    await rolarAte(tester, find.text('+ Cadastrar paciente'));
    final titulo = tester.getRect(find.text('Pacientes vinculados').last);
    final botao = tester.getRect(find.text('+ Cadastrar paciente'));
    expect(botao.top, greaterThan(titulo.bottom));
  });

  testWidgets('Tela larga: data no cabeçalho, 4 indicadores em linha e botão ao lado do título', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/painel', (_) => const PainelCuidador(), tamanho: _desktop);
    expect(find.byType(DataHoraCabecalho), findsOneWidget);
    expect(find.byType(FaixaDataHora), findsNothing);
    final tops = ['Pacientes vinculados', 'Precisam de atenção', 'Adesão média (30 dias)', 'Medicamentos monitorados']
        .map((t) => tester.getRect(find.text(t).first).top)
        .toSet();
    expect(tops.length, 1);
    final titulo = tester.getRect(find.text('Pacientes vinculados').last);
    final botao = tester.getRect(find.text('+ Cadastrar paciente'));
    expect(botao.center.dy, closeTo(titulo.center.dy, 12));
  });

  testWidgets('Texto do botão cabe inteiro, sem encolher', (tester) async {
    await carregarNunito(tester);
    for (final tamanho in [_celular, _desktop]) {
      await montarPagina(tester, estadoCuidador(), '/painel', (_) => const PainelCuidador(), tamanho: tamanho);
      await rolarAte(tester, find.text('+ Cadastrar paciente'));
      // O Botao usa FittedBox(scaleDown): se o texto não coubesse, a altura renderizada ficaria menor que a natural.
      final caixa = find.ancestor(of: find.text('+ Cadastrar paciente'), matching: find.byType(FittedBox));
      final fitted = tester.renderObject<RenderBox>(caixa);
      final texto = tester.renderObject<RenderBox>(find.text('+ Cadastrar paciente'));
      expect(fitted.size.width, greaterThanOrEqualTo(texto.size.width - 0.5), reason: '$tamanho');
    }
  });

  testWidgets('Fonte grande no celular e tela larga sem overflow', (tester) async {
    await montarPagina(tester, estadoCuidador()..tamanhoFonte = 'grande', '/painel', (_) => const PainelCuidador(),
        tamanho: _celular);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await montarPagina(tester, estadoCuidador()..tamanhoFonte = 'grande', '/painel', (_) => const PainelCuidador(),
        tamanho: const Size(700, 900));
    expect(tester.takeException(), isNull);
  });
}
