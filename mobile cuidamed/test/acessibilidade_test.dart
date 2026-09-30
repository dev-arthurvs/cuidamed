import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/paginas/acessibilidade.dart';
import 'package:cuidamed_mobile/paginas/historico.dart';
import 'package:cuidamed_mobile/utilitarios/ajuda_conteudo.dart';

import 'apoio.dart';

void main() {
  testWidgets('Paciente vê só seções de paciente/ambos e abre a sanfona', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/acessibilidade', (_) => const Acessibilidade());

    expect(find.text('Início (painel do paciente)'), findsOneWidget);
    expect(find.text('Início (painel do cuidador)'), findsNothing);

    final passo = guiaSecoes.firstWhere((s) => s.chave == 'historico').passos.first;
    expect(find.text(passo), findsNothing);
    await rolarAte(tester, find.text('Histórico'));
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    expect(find.text(passo), findsOneWidget);

    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    expect(find.text(passo), findsNothing);
  });

  testWidgets('Cuidador não vê Chat, vê seções de cuidador', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/acessibilidade', (_) => const Acessibilidade());
    expect(find.text('Início (painel do cuidador)'), findsOneWidget);
    await rolarAte(tester, find.text('Ajuda e acessibilidade'));
    expect(find.text('Chat com o assistente'), findsNothing);
  });

  testWidgets('Fonte grande em 360px sem overflow com todas as seções abertas uma a uma', (tester) async {
    final estado = estadoPaciente()..tamanhoFonte = 'grande';
    await montarPagina(tester, estado, '/acessibilidade', (_) => const Acessibilidade());
    for (final secao in guiaSecoes.where((s) => s.visivelPara('paciente'))) {
      // "Farmácias" também é rótulo da barra inferior — procura só no ListView.
      final titulo = find.descendant(of: find.byType(ListView), matching: find.text(secao.titulo));
      await rolarAte(tester, titulo);
      await tester.tap(titulo);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Botão "?" do cabeçalho mostra a ajuda da tela atual', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
    await tester.tap(find.byTooltip('Ajuda desta tela'));
    await tester.pumpAndSettle();
    final secao = guiaSecoes.firstWhere((s) => s.chave == 'historico');
    expect(find.text(secao.paraQueServe), findsOneWidget);
  });

  test('Mapeamento rota → seção de ajuda', () {
    expect(obterChaveAjuda('/painel', 'cuidador'), 'inicio-cuidador');
    expect(obterChaveAjuda('/painel', 'paciente'), 'inicio-paciente');
    expect(obterChaveAjuda('/cuidador/paciente/3', 'cuidador'), 'detalhes-paciente');
    expect(obterChaveAjuda('/cuidador/paciente/3/painel', 'cuidador'), 'painel-paciente-config');
    expect(obterChaveAjuda('/historico/3', 'cuidador'), 'historico');
    expect(obterChaveAjuda('/login', 'paciente'), isNull);
  });
}
