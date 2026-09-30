import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/paginas/edicao_perfil.dart';

import 'apoio.dart';

void main() {
  testWidgets('Perfil do paciente sem cuidador mostra dados, senha, fonte e vínculo', (tester) async {
    final estado = estadoPaciente();
    await montarPagina(tester, estado, '/perfil', (_) => const EdicaoPerfil());

    expect(find.text('Maria da Silva'), findsWidgets);
    expect(find.text('Paciente'), findsOneWidget);
    expect(find.text('10/03/1950'), findsOneWidget);
    expect(find.text('Feminino'), findsOneWidget);
    expect(find.text('Alterar senha'), findsOneWidget);

    await rolarAte(tester, find.text('Vincular cuidador(a)'));
    expect(find.text('Enviar solicitação'), findsOneWidget);
  });

  testWidgets('Perfil com solicitação pendente mostra aviso de aguardando', (tester) async {
    await montarPagina(tester, estadoPaciente(cuidadorSolicitadoId: 9), '/perfil', (_) => const EdicaoPerfil());
    await rolarAte(tester, find.textContaining('aguardando confirmação'));
    expect(find.text('Vincular cuidador(a)'), findsNothing);
  });

  testWidgets('Perfil do cuidador mostra profissão e não mostra campos de paciente', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/perfil', (_) => const EdicaoPerfil());
    expect(find.text('Cuidador(a) / Médico(a)'), findsOneWidget);
    expect(find.text('Enfermeiro'), findsOneWidget);
    expect(find.text('Data de nascimento'), findsNothing);
    expect(find.text('Vincular cuidador(a)'), findsNothing);
  });

  testWidgets('Validações locais de senha e dados', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/perfil', (_) => const EdicaoPerfil());

    await tester.enterText(find.widgetWithText(TextFormField, 'Nova senha'), '123');
    await rolarAte(tester, find.text('Atualizar senha'));
    await tester.tap(find.text('Atualizar senha'));
    await tester.pump();
    expect(find.text('A nova senha deve ter no mínimo 8 caracteres.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nova senha'), '12345678');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirmar nova senha'), '87654321');
    await tester.tap(find.text('Atualizar senha'));
    await tester.pump();
    expect(find.text('As senhas não coincidem.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome de usuário'), '');
    await rolarAte(tester, find.text('Salvar alterações'));
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle(); // snackbar anterior sai antes da nova entrar
    expect(find.text('Preencha nome e e-mail.'), findsOneWidget);
  });

  testWidgets('Tamanho da fonte grande muda estado e não estoura layout em 360px', (tester) async {
    final estado = estadoPaciente();
    await montarPagina(tester, estado, '/perfil', (_) => const EdicaoPerfil());

    await rolarAte(tester, find.text('Grande'));
    await tester.tap(find.text('Grande'));
    await tester.pumpAndSettle();
    expect(estado.tamanhoFonte, 'grande');
    expect(estado.escalaFonte, 1.15);

    // Percorre a tela inteira com a fonte grande — overflow vira exceção no teste.
    await rolarAte(tester, find.text('Enviar solicitação'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Em tela larga os cards ficam lado a lado', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/perfil', (_) => const EdicaoPerfil(), tamanho: const Size(1100, 900));
    final dados = tester.getTopLeft(find.text('Salvar alterações'));
    final senha = tester.getTopLeft(find.text('Alterar senha'));
    expect(senha.dx, greaterThan(dados.dx + 200));
    final ajuda = tester.getTopLeft(find.text('Ajuda e acessibilidade').first);
    final fonte = tester.getTopLeft(find.text('Tamanho da fonte'));
    expect(fonte.dy, closeTo(ajuda.dy, 2));
  });
}
