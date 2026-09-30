import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/componentes/botao.dart';
import 'package:cuidamed_mobile/paginas/chat.dart';
import 'package:cuidamed_mobile/servicos/api_cliente.dart';

import 'apoio.dart';

void main() {
  testWidgets('Envia pergunta digitada, mostra digitando e depois a resposta', (tester) async {
    final resposta = Completer<String>();
    int? pacienteRecebido;
    String? mensagemRecebida;
    await montarPagina(
      tester,
      estadoPaciente(),
      '/chat',
      (_) => Chat(perguntar: (id, msg) {
        pacienteRecebido = id;
        mensagemRecebida = msg;
        return resposta.future;
      }),
    );

    expect(find.textContaining('Eu sou o assistente'), findsOneWidget);
    final botaoEnviar = find.widgetWithText(Botao, 'Enviar');
    expect(tester.widget<Botao>(botaoEnviar).onPressed, isNull); // vazio → desabilitado

    await tester.enterText(find.byType(TextField), '  Que remédio tomo agora?  ');
    await tester.pump();
    await tester.tap(botaoEnviar);
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50)); // rolagem automática até a nova mensagem
    }

    expect(pacienteRecebido, 1);
    expect(mensagemRecebida, 'Que remédio tomo agora?');
    expect(find.text('Que remédio tomo agora?'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-digitando')), findsOneWidget);

    resposta.complete('Agora é a Losartana 50mg.');
    await tester.pumpAndSettle();
    expect(find.text('Agora é a Losartana 50mg.'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-digitando')), findsNothing);
  });

  testWidgets('Pergunta sugerida envia direto e erro mostra mensagem amigável', (tester) async {
    await montarPagina(
      tester,
      estadoPaciente(),
      '/chat',
      (_) => Chat(perguntar: (_, _) async => throw Exception('falha')),
    );
    await tester.tap(find.text('Quais remédios eu preciso tomar?'));
    await tester.pumpAndSettle();
    expect(find.text('Quais remédios eu preciso tomar?'), findsNWidgets(2)); // chip + bolha
    expect(find.textContaining('Não consegui me conectar'), findsOneWidget);
  });

  testWidgets('Limite de perguntas atingido: mostra a mensagem do servidor', (tester) async {
    const aviso = 'Você fez muitas perguntas em pouco tempo. Tente de novo daqui a pouco.';
    await montarPagina(
      tester,
      estadoPaciente(),
      '/chat',
      (_) => Chat(perguntar: (_, _) async => throw ApiExcecao(aviso)),
    );
    await tester.tap(find.text('Quais remédios eu preciso tomar?'));
    await tester.pumpAndSettle();
    expect(find.text(aviso), findsOneWidget);
    expect(find.textContaining('Não consegui me conectar'), findsNothing);
  });

  testWidgets('Chat com fonte grande em 360px não estoura', (tester) async {
    await montarPagina(
      tester,
      estadoPaciente()..tamanhoFonte = 'grande',
      '/chat',
      (_) => Chat(perguntar: (_, _) async => 'Resposta longa ' * 30),
    );
    final chip = find.text('Que horas eu tomo cada remédio?');
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Perguntas prontas: todas visíveis e dentro da tela, em várias larguras', (tester) async {
    for (final (largura, fonte) in [(320.0, 'grande'), (360.0, 'media'), (1100.0, 'media')]) {
      await montarPagina(tester, estadoPaciente()..tamanhoFonte = fonte, '/chat',
          (_) => Chat(perguntar: (_, _) async => 'ok'), tamanho: Size(largura, 800));
      for (final pergunta in [
        'Quais remédios eu preciso tomar?',
        'Que horas eu tomo cada remédio?',
        'Tem alguma observação sobre como tomar meus remédios?',
        'Eu tomei todos os remédios nos últimos dias?',
      ]) {
        final r = tester.getRect(find.text(pergunta));
        expect(r.left, greaterThanOrEqualTo(0), reason: '$pergunta @ $largura');
        expect(r.right, lessThanOrEqualTo(largura), reason: '$pergunta @ $largura');
      }
      expect(tester.takeException(), isNull, reason: '$largura');
    }
  });

  testWidgets('Perguntas prontas somem com o teclado aberto', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/chat', (_) => Chat(perguntar: (_, _) async => 'ok'));
    expect(find.text('Quais remédios eu preciso tomar?'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.text('Quais remédios eu preciso tomar?'), findsNothing);
  });
}
