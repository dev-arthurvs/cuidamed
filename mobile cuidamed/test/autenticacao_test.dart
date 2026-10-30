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
    testWidgets('Tem título, campos com ícone, olho na senha e os caminhos como botões', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login());
      expect(find.text('Entrar na minha conta'), findsOneWidget);
      expect(find.text('Esqueci minha senha'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Criar conta'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Ativar acesso'), findsOneWidget);
    });

    testWidgets('Olho da senha mostra e esconde o que foi digitado', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login());
      final senha = find.widgetWithText(TextField, '••••••••');
      expect(tester.widget<TextField>(senha).obscureText, isTrue);
      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();
      expect(tester.widget<TextField>(senha).obscureText, isFalse);
      await tester.tap(find.byTooltip('Esconder senha'));
      await tester.pump();
      expect(tester.widget<TextField>(senha).obscureText, isTrue);
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

      final criar = tester.getRect(find.widgetWithText(OutlinedButton, 'Criar conta'));
      final ativar = tester.getRect(find.widgetWithText(OutlinedButton, 'Ativar acesso'));
      expect(criar.top, greaterThan(entrar.bottom)); // caminhos no rodapé
      expect(criar.top, closeTo(ativar.top, 1)); // lado a lado
      expect(ativar.left, greaterThan(criar.right));
      expect(criar.width, closeTo(ativar.width, 1)); // mesma largura
      expect(criar.left, closeTo(form.left, 1));
      expect(ativar.right, closeTo(form.right, 1));
      expect(criar.height, greaterThanOrEqualTo(52)); // fácil de tocar
      expect(tester.widget<Text>(find.text('Esqueci minha senha')).style!.fontSize, 16);
    });

    testWidgets('"Esqueci minha senha" só avisa (simulação) e não navega', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login());
      await rolarAte(tester, find.text('Esqueci minha senha'));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pump();
      expect(find.textContaining('instruções de recuperação'), findsOneWidget);
      expect(find.text('rota /definir-senha'), findsNothing);
    });

    testWidgets('"Ativar acesso" abre a tela de ativação', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login());
      await rolarAte(tester, find.text('Ativar acesso'));
      await tester.tap(find.text('Ativar acesso'));
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
    testWidgets('Fonte "Grande" escolhida no sistema não aumenta o login', (tester) async {
      await montarPagina(tester, _deslogado()..tamanhoFonte = 'grande', '/login', (_) => const Login());
      final contexto = tester.element(find.text('Entrar na minha conta'));
      expect(MediaQuery.textScalerOf(contexto).scale(10), 10); // escala 1,0
    });

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

    testWidgets('Rodapé: botão "Entrar" vai ao login', (tester) async {
      await montarPagina(tester, _deslogado(), '/cadastro', (_) => const Cadastro());
      expect(find.text('‹ Voltar para entrar'), findsNothing);
      await rolarAte(tester, find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('rota /login'), findsOneWidget);
    });
  });

  group('Ativar acesso', () {
    testWidgets('Rodapé: botões "Entrar" e "Criar conta"', (tester) async {
      await montarPagina(tester, _deslogado(), '/definir-senha', (_) => const DefinirSenha());
      expect(find.text('‹ Voltar para entrar'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Entrar'), findsOneWidget);
      await rolarAte(tester, find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
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
