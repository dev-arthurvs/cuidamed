import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/componentes/cabecalho.dart';
import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/paginas/cadastro.dart';
import 'package:cuidamed_mobile/paginas/definir_senha.dart';
import 'package:cuidamed_mobile/paginas/login.dart';
import 'package:cuidamed_mobile/utilitarios/tema.dart';

import 'apoio.dart';

AppEstado _deslogado() => AppEstado()..carregandoSessao = false;

const _celular = Size(360, 800);
const _desktop = Size(1400, 900);

/// O card branco do formulário (o Container com sombra que envolve o conteúdo).
Rect _cartao(WidgetTester tester, String textoDentro) => tester.getRect(find
    .ancestor(of: find.text(textoDentro), matching: find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).boxShadow != null))
    .first);

void main() {
  group('Login', () {
    testWidgets('Tem título, "Esqueci minha senha" e os caminhos de cadastro e ativação', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login());
      expect(find.text('Entrar na minha conta'), findsOneWidget);
      expect(find.text('Esqueci minha senha'), findsOneWidget);
      expect(find.text('Não tem conta?'), findsOneWidget);
      expect(find.text('Cadastre-se'), findsOneWidget);
      expect(find.text('Cadastrado pelo seu cuidador?'), findsOneWidget);
      expect(find.text('Ativar meu acesso'), findsOneWidget);
    });

    testWidgets('"Esqueci" à direita, abaixo da senha; rodapé centralizado, um por linha', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login(), tamanho: _celular);
      final form = tester.getRect(find.byType(Form));
      final senha = tester.getRect(find.widgetWithText(TextField, '••••••••'));
      final esqueci = tester.getRect(find.text('Esqueci minha senha'));
      final entrar = tester.getRect(find.text('Entrar'));
      expect(esqueci.top, greaterThan(senha.bottom));
      expect(esqueci.right, closeTo(form.right, 6)); // alinhado à direita
      expect(entrar.top, greaterThan(esqueci.bottom)); // botão depois do "Esqueci"

      final cadastre = tester.getRect(find.text('Cadastre-se'));
      final ativar = tester.getRect(find.text('Ativar meu acesso'));
      expect(cadastre.top, greaterThan(entrar.bottom)); // caminhos no rodapé
      expect(ativar.top, greaterThan(cadastre.bottom)); // um por linha
      final pergunta = tester.getRect(find.text('Não tem conta?'));
      if ((cadastre.top - pergunta.top).abs() < 4) {
        // cabe numa linha: o conjunto fica centralizado
        expect((pergunta.left + cadastre.right) / 2, closeTo(form.center.dx, 6));
      } else {
        // quebrou em duas linhas (a fonte de teste é larga): cada uma centralizada
        expect(pergunta.center.dx, closeTo(form.center.dx, 4));
        expect(cadastre.center.dx, closeTo(form.center.dx, 4));
      }
      for (final texto in ['Esqueci minha senha', 'Cadastre-se', 'Ativar meu acesso', 'Não tem conta?']) {
        expect(tester.widget<Text>(find.text(texto)).style!.fontSize, 16, reason: texto);
      }
    });

    testWidgets('"Esqueci minha senha" só avisa (simulação) e não navega', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login());
      await rolarAte(tester, find.text('Esqueci minha senha'));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pump();
      expect(find.textContaining('instruções de recuperação'), findsOneWidget);
      expect(find.text('rota /definir-senha'), findsNothing);
    });

    testWidgets('"Ativar meu acesso" abre a tela de ativação', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login());
      await rolarAte(tester, find.text('Ativar meu acesso'));
      await tester.tap(find.text('Ativar meu acesso'));
      await tester.pumpAndSettle();
      expect(find.text('rota /definir-senha'), findsOneWidget);
    });

    testWidgets('Validação de campos vazios', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login());
      await rolarAte(tester, find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.text('Informe o e-mail.'), findsOneWidget);
      expect(find.text('Informe a senha.'), findsOneWidget);
    });
  });

  group('Layout', () {
    testWidgets('O gradiente azul escuro cobre a tela inteira', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login(), tamanho: _celular);
      final fundo = find.byWidgetPredicate(
          (w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient == CorApp.gradienteAutenticacao);
      expect(fundo, findsOneWidget);
      expect(tester.getSize(fundo), _celular);
    });

    for (final (nome, rota, pagina, frase, titulo) in [
      ('Login', '/login', const Login() as Widget, 'O remédio certo, na hora certa, todos os dias.', 'Entrar na minha conta'),
      ('Cadastro', '/cadastro', const Cadastro(), 'O remédio certo, na hora certa, sempre com você.', 'Criar cadastro'),
      ('Ativar acesso', '/definir-senha', const DefinirSenha(), 'Seu cuidador já cadastrou você.', 'Ativar meu acesso'),
    ]) {
      testWidgets('$nome: no celular só a logo (grande, centralizada) acima do card; na tela larga, a frase', (tester) async {
        await montarPagina(tester, _deslogado(), rota, (_) => pagina, tamanho: _celular);
        expect(find.text(frase), findsNothing);
        final logo = find.byType(LogoCuidaMed);
        expect(tester.widget<LogoCuidaMed>(logo).tamanho, 72);
        expect(tester.getRect(logo).center.dx, closeTo(_celular.width / 2, 2));
        expect(tester.getRect(find.text(titulo).first).top, greaterThan(tester.getRect(logo).bottom));

        await montarPagina(tester, _deslogado(), rota, (_) => pagina, tamanho: _desktop);
        expect(find.text(frase), findsOneWidget);
        expect(tester.widget<LogoCuidaMed>(find.byType(LogoCuidaMed)).tamanho, 84);
      });
    }

    testWidgets('Tela larga: marca à esquerda e card centralizado na metade direita', (tester) async {
      await montarPagina(tester, _deslogado(), '/cadastro', (_) => const Cadastro(), tamanho: _desktop);
      final frase = tester.getRect(find.textContaining('O remédio certo, na hora certa, sempre'));
      final cartao = _cartao(tester, 'Criar cadastro');
      expect(cartao.left, greaterThan(frase.right));
      final metade = _desktop.width / 2;
      expect(cartao.left - metade, closeTo(_desktop.width - cartao.right, 2));
    });

    for (final (nome, rota, pagina) in [
      ('Login', '/login', const Login() as Widget),
      ('Cadastro', '/cadastro', const Cadastro()),
      ('Ativar acesso', '/definir-senha', const DefinirSenha()),
    ]) {
      testWidgets('$nome sem overflow: celular com fonte grande e tela larga', (tester) async {
        await montarPagina(tester, _deslogado()..tamanhoFonte = 'grande', rota, (_) => pagina, tamanho: _celular);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await montarPagina(tester, _deslogado(), rota, (_) => pagina, tamanho: _desktop);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Cadastro', () {
    testWidgets('Trocar para Cuidador troca campos e a frase do painel; sem "Protótipo"', (tester) async {
      // A frase só aparece na tela larga (no celular fica só a logo).
      await montarPagina(tester, _deslogado(), '/cadastro', (_) => const Cadastro(), tamanho: _desktop);
      // Endereço (paciente) e profissão (cuidador) não são pedidos no cadastro.
      expect(find.text('Endereço'), findsNothing);
      expect(find.text('Profissão'), findsNothing);
      expect(find.text('Data de nascimento'), findsOneWidget);

      await tester.tap(find.text('Cuidador'));
      await tester.pumpAndSettle();
      expect(find.text('Profissão'), findsNothing);
      expect(find.text('Data de nascimento'), findsNothing); // só do paciente
      expect(find.text('Cuidado à distância, com tranquilidade total.'), findsOneWidget);
      expect(find.textContaining('Protótipo'), findsNothing);
    });

    testWidgets('Rodapé: "Já tem conta? Entrar" vai ao login', (tester) async {
      await montarPagina(tester, _deslogado(), '/cadastro', (_) => const Cadastro());
      expect(find.text('‹ Voltar para entrar'), findsNothing);
      await rolarAte(tester, find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('rota /login'), findsOneWidget);
    });
  });

  group('Ativar acesso', () {
    testWidgets('Rodapé: "Já ativou seu acesso? Entrar" e "Não tem conta? Cadastre-se"', (tester) async {
      await montarPagina(tester, _deslogado(), '/definir-senha', (_) => const DefinirSenha());
      expect(find.text('‹ Voltar para entrar'), findsNothing);
      expect(find.text('Já ativou seu acesso?'), findsOneWidget);
      await rolarAte(tester, find.text('Cadastre-se'));
      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();
      expect(find.text('rota /cadastro'), findsOneWidget);
    });

    testWidgets('Validações locais', (tester) async {
      await montarPagina(tester, _deslogado(), '/definir-senha', (_) => const DefinirSenha());
      final botao = find.text('Ativar acesso');

      await rolarAte(tester, botao);
      await tester.tap(botao);
      await tester.pump();
      expect(find.text('Informe o e-mail cadastrado pelo seu cuidador.'), findsOneWidget);

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'maria@email.com');
      await tester.tap(botao);
      await tester.pump();
      expect(find.text('Informe o código de ativação que seu cuidador passou.'), findsOneWidget);

      await tester.enterText(campos.at(1), 'K7M2QA');
      await tester.enterText(campos.at(2), '123');
      await tester.tap(botao);
      await tester.pump();
      expect(find.text('A senha deve ter no mínimo 8 caracteres.'), findsOneWidget);

      await tester.enterText(campos.at(2), '12345678');
      await tester.enterText(campos.at(3), '87654321');
      await tester.tap(botao);
      await tester.pump();
      expect(find.text('As senhas não coincidem.'), findsOneWidget);
    });
  });
}
