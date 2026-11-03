import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/modelos/cuidador.dart';
import 'package:cuidamed_mobile/modelos/paciente.dart';
import 'package:cuidamed_mobile/paginas/cadastro.dart';
import 'package:cuidamed_mobile/paginas/definir_senha.dart';
import 'package:cuidamed_mobile/paginas/edicao_perfil.dart';
import 'package:cuidamed_mobile/paginas/login.dart';
import 'package:cuidamed_mobile/paginas/painel_cuidador.dart';
import 'package:cuidamed_mobile/utilitarios/mascaras.dart';

import 'apoio.dart';

const _semEmail = 'Não tenho e-mail';
const _avisoTelefone = 'Sem e-mail, informe o telefone com DDD.';

AppEstado _deslogado() => AppEstado()..carregandoSessao = false;

/// Login por e-mail ou telefone e cadastro sem e-mail (muitos idosos não têm).
void main() {
  testWidgets('Login e ativação pedem "E-mail ou telefone"', (tester) async {
    await montarPagina(tester, _deslogado(), '/login', (_) => const Login());
    expect(find.text('E-mail ou telefone'), findsOneWidget);
    expect(find.text('E-mail'), findsNothing);

    await montarPagina(tester, _deslogado(), '/definir-senha', (_) => const DefinirSenha());
    expect(find.text('E-mail ou telefone cadastrado'), findsOneWidget);
  });

  testWidgets('Cadastro: "Não tenho e-mail" tira o campo e exige o telefone', (tester) async {
    await montarPagina(tester, _deslogado(), '/cadastro', (_) => const Cadastro());
    expect(find.text('E-mail'), findsOneWidget);

    await tester.ensureVisible(find.text(_semEmail));
    await tester.tap(find.text(_semEmail));
    await tester.pumpAndSettle();
    expect(find.text('E-mail'), findsNothing);
    expect(find.textContaining('número de telefone'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Maria Aparecida Souza').first, 'Maria');
    await tester.ensureVisible(find.text('Criar conta e entrar'));
    await tester.tap(find.text('Criar conta e entrar'));
    await tester.pumpAndSettle();
    expect(find.text(_avisoTelefone), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cuidador cadastrando paciente também pode marcar "Não tenho e-mail"', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/painel', (_) => const PainelCuidador());
    await rolarAte(tester, find.text('+ Cadastrar paciente'));
    await tester.tap(find.text('+ Cadastrar paciente'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(_semEmail));
    await tester.tap(find.text(_semEmail));
    await tester.pumpAndSettle();
    expect(find.text('E-mail'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'João Teste');
    await tester.tap(find.text('Cadastrar paciente'));
    await tester.pump();
    expect(find.text(_avisoTelefone), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Configurações: conta sem e-mail abre com a caixa marcada', (tester) async {
    final estado = estadoPaciente()..usuario = UsuarioLogado(id: 1, nome: 'Maria da Silva', email: '', tipo: 'paciente');
    await montarPagina(tester, estado, '/configuracoes', (_) => const EdicaoPerfil());
    expect(find.text('E-mail'), findsNothing);
    expect(find.text(_semEmail), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    // Com e-mail: campo visível e caixa desmarcada.
    await montarPagina(tester, estadoPaciente(), '/configuracoes', (_) => const EdicaoPerfil());
    expect(find.text('E-mail'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  test('Conta sem e-mail vinda da API não quebra o app', () {
    expect(Paciente.fromJson({'id': 1, 'nome': 'Maria', 'email': null}).email, '');
    expect(Cuidador.fromJson({'id': 2, 'nome': 'Ana', 'email': null}).email, '');
  });

  test('Telefone completo: com DDD, fixo ou celular', () {
    expect(telefoneCompleto('(79) 99999-0000'), isTrue);
    expect(telefoneCompleto('(79) 3333-4444'), isTrue);
    expect(telefoneCompleto('99999-0000'), isFalse);
    expect(telefoneCompleto(''), isFalse);
  });
}
