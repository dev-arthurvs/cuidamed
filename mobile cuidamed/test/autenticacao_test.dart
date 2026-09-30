import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/componentes/cabecalho.dart';
import 'package:cuidamed_mobile/componentes/layout_autenticacao.dart';
import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/paginas/cadastro.dart';
import 'package:cuidamed_mobile/paginas/definir_senha.dart';
import 'package:cuidamed_mobile/paginas/login.dart';

import 'apoio.dart';

AppEstado _deslogado() => AppEstado()..carregandoSessao = false;

const _celular = Size(360, 800);
const _desktop = Size(1400, 900);

void main() {
  group('Login', () {
    testWidgets('Tem título e os três links; sem "Não tem conta?"', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login());
      expect(find.text('Entrar na minha conta'), findsOneWidget);
      expect(find.text('Esqueci minha senha'), findsOneWidget);
      expect(find.text('Cadastre-se'), findsOneWidget);
      expect(find.text('Ativar meu acesso'), findsOneWidget);
      expect(find.text('Não tem conta?'), findsNothing);
    });

    testWidgets('Links centralizados, um abaixo do outro, com fonte menor (14)', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login(), tamanho: _celular);
      final cartao = tester.getRect(find.byType(Form));
      final linhas = [
        find.text('Esqueci minha senha'),
        find.text('Cadastre-se'),
        find.text('Cadastrado pelo seu cuidador?'),
      ];
      final esqueci = tester.getRect(linhas[0]);
      final cadastre = tester.getRect(linhas[1]);
      final ativar = tester.getRect(find.text('Ativar meu acesso'));
      expect(cadastre.top, greaterThan(esqueci.bottom)); // um abaixo do outro
      expect(tester.getRect(linhas[2]).top, greaterThan(cadastre.bottom));
      expect(esqueci.center.dx, closeTo(cartao.center.dx, 2)); // centralizados
      expect(cadastre.center.dx, closeTo(cartao.center.dx, 2));
      final pergunta = tester.getRect(linhas[2]);
      if ((ativar.top - pergunta.top).abs() < 2) {
        // cabe numa linha: o conjunto fica centralizado
        expect((pergunta.left + ativar.right) / 2, closeTo(cartao.center.dx, 4));
      } else {
        // quebrou em duas linhas: cada uma centralizada
        expect(pergunta.center.dx, closeTo(cartao.center.dx, 4));
        expect(ativar.center.dx, closeTo(cartao.center.dx, 4));
      }
      for (final f in [...linhas, find.text('Ativar meu acesso')]) {
        expect(tester.widget<Text>(f).style!.fontSize, 14);
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
    testWidgets('Celular: login só com a logo, maior e centralizada no painel azul', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login(), tamanho: _celular);
      expect(find.text('O remédio certo, na hora certa, todos os dias.'), findsNothing);
      final logo = find.byType(LogoCuidaMed);
      expect(tester.widget<LogoCuidaMed>(logo).tamanho, 64);
      expect(tester.getRect(logo).center.dx, closeTo(_celular.width / 2, 2));
      expect(tester.getRect(find.text('Entrar na minha conta')).top, greaterThan(tester.getRect(logo).bottom));
    });

    testWidgets('Tela larga: login mantém a frase no painel azul, como no web', (tester) async {
      await montarPagina(tester, _deslogado(), '/login', (_) => const Login(), tamanho: _desktop);
      expect(find.text('O remédio certo, na hora certa, todos os dias.'), findsOneWidget);
    });

    for (final (nome, rota, pagina, frase) in [
      ('Cadastro', '/cadastro', const Cadastro() as Widget, 'O remédio certo, na hora certa, sempre com você.'),
      ('Ativar acesso', '/definir-senha', const DefinirSenha(), 'Seu cuidador já cadastrou você.'),
    ]) {
      testWidgets('$nome: no celular só a logo (maior, centralizada); na tela larga mantém a frase', (tester) async {
        await montarPagina(tester, _deslogado(), rota, (_) => pagina, tamanho: _celular);
        expect(find.text(frase), findsNothing);
        final logo = find.byType(LogoCuidaMed);
        expect(tester.widget<LogoCuidaMed>(logo).tamanho, 64);
        expect(tester.getRect(logo).center.dx, closeTo(_celular.width / 2, 2));
        expect(tester.widget<Text>(find.text('‹ Voltar para entrar')).style!.fontSize, 14);

        await montarPagina(tester, _deslogado(), rota, (_) => pagina, tamanho: _desktop);
        expect(find.text(frase), findsOneWidget);
      });
    }

    testWidgets('Ativar acesso: só "Cadastre-se", centralizado e menor', (tester) async {
      await montarPagina(tester, _deslogado(), '/definir-senha', (_) => const DefinirSenha(), tamanho: _celular);
      expect(find.text('Ainda não tem cadastro?'), findsNothing);
      await rolarAte(tester, find.text('Cadastre-se'));
      final link = tester.getRect(find.text('Cadastre-se'));
      final cartao = tester.getRect(find.text('Ativar acesso'));
      expect(link.center.dx, closeTo(cartao.center.dx, 2));
      expect(tester.widget<Text>(find.text('Cadastre-se')).style!.fontSize, 14);
    });

    testWidgets('Tela larga: painel azul à esquerda e card centralizado à direita', (tester) async {
      await montarPagina(tester, _deslogado(), '/cadastro', (_) => const Cadastro(), tamanho: _desktop);
      final frase = tester.getRect(find.textContaining('O remédio certo, na hora certa, sempre'));
      final titulo = tester.getRect(find.text('Criar cadastro'));
      expect(titulo.left, greaterThan(frase.right));
      // Card centralizado no espaço à direita do painel (margens iguais ± alguns px).
      final cartao = tester.getRect(find
          .ancestor(of: find.text('Criar cadastro'), matching: find.byType(Container))
          .last);
      final painelDireito = Rect.fromLTRB(
          tester.getRect(find.byType(LayoutAutenticacao)).left + (1400 * 0.42).clamp(420.0, 620.0), 0, 1400, 900);
      expect(cartao.left - painelDireito.left, closeTo(painelDireito.right - cartao.right, 2));
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
    testWidgets('Trocar para Cuidador troca campos e a frase do painel', (tester) async {
      // A frase do painel azul só aparece na tela larga (no celular fica só a logo).
      await montarPagina(tester, _deslogado(), '/cadastro', (_) => const Cadastro(), tamanho: _desktop);
      expect(find.text('Endereço'), findsOneWidget);
      expect(find.text('Profissão'), findsNothing);

      await tester.tap(find.text('Cuidador'));
      await tester.pumpAndSettle();
      expect(find.text('Profissão'), findsOneWidget);
      expect(find.text('Endereço'), findsNothing);
      expect(find.text('Cuidado à distância, com tranquilidade total.'), findsOneWidget);
    });

    testWidgets('Voltar para entrar vai ao login', (tester) async {
      await montarPagina(tester, _deslogado(), '/cadastro', (_) => const Cadastro());
      await tester.tap(find.text('‹ Voltar para entrar'));
      await tester.pumpAndSettle();
      expect(find.text('rota /login'), findsOneWidget);
    });
  });

  group('Ativar acesso', () {
    testWidgets('Validações locais', (tester) async {
      await montarPagina(tester, _deslogado(), '/definir-senha', (_) => const DefinirSenha());
      final botao = find.text('Ativar acesso');

      await rolarAte(tester, botao);
      await tester.tap(botao);
      await tester.pump();
      expect(find.text('Informe o e-mail cadastrado pelo seu cuidador.'), findsOneWidget);

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'maria@email.com');
      await tester.enterText(campos.at(1), '123');
      await tester.tap(botao);
      await tester.pump();
      expect(find.text('A senha deve ter no mínimo 8 caracteres.'), findsOneWidget);

      await tester.enterText(campos.at(1), '12345678');
      await tester.enterText(campos.at(2), '87654321');
      await tester.tap(botao);
      await tester.pump();
      expect(find.text('As senhas não coincidem.'), findsOneWidget);
    });
  });
}
