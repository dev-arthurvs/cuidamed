import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/paginas/painel_cuidador.dart';

import 'apoio.dart';

const _celular = Size(360, 800);
const _desktop = Size(1300, 900);

Future<void> _abrir(WidgetTester tester, {Size tamanho = _celular, String fonte = 'media'}) async {
  await montarPagina(tester, estadoCuidador()..tamanhoFonte = fonte, '/painel', (_) => const PainelCuidador(),
      tamanho: tamanho);
  await rolarAte(tester, find.text('+ Cadastrar paciente'));
  await tester.tap(find.text('+ Cadastrar paciente'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Mesmos campos do web e sem senha', (tester) async {
    await _abrir(tester);
    expect(find.text('PACIENTES'), findsOneWidget);
    expect(find.text('Cadastrar novo paciente'), findsOneWidget);
    for (final rotulo in [
      'Nome completo',
      'Data de nascimento',
      'Sexo',
      'Enfermidade / condição principal',
      'E-mail',
      'Telefone',
      'Endereço',
    ]) {
      expect(find.text(rotulo), findsWidgets, reason: rotulo);
    }
    expect(find.textContaining('Senha'), findsNothing);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Cadastrar paciente'), findsOneWidget);
  });

  testWidgets('Celular abre como painel inferior; tela larga como janela', (tester) async {
    await _abrir(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    await _abrir(tester, tamanho: _desktop);
    expect(find.byType(Dialog), findsOneWidget);
    // Tela larga: e-mail e telefone lado a lado, como no web.
    final email = tester.getRect(find.text('E-mail'));
    final telefone = tester.getRect(find.text('Telefone'));
    expect(telefone.top, closeTo(email.top, 1));
    expect(telefone.left, greaterThan(email.right));
  });

  testWidgets('Validações iguais às do web', (tester) async {
    await _abrir(tester);
    await tester.tap(find.text('Cadastrar paciente'));
    await tester.pump();
    expect(find.text('Informe o nome do paciente.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'João Teste');
    await tester.tap(find.text('Cadastrar paciente'));
    await tester.pump();
    expect(find.text('Informe o e-mail do paciente.'), findsOneWidget);
  });

  testWidgets('Cancelar e o X fecham sem cadastrar', (tester) async {
    await _abrir(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Cadastrar novo paciente'), findsNothing);

    await rolarAte(tester, find.text('+ Cadastrar paciente'));
    await tester.tap(find.text('+ Cadastrar paciente'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Fechar'));
    await tester.pumpAndSettle();
    expect(find.text('Cadastrar novo paciente'), findsNothing);
  });

  testWidgets('Fonte grande no celular: rola até o fim sem overflow', (tester) async {
    await _abrir(tester, fonte: 'grande');
    await tester.drag(find.text('Cadastrar novo paciente'), const Offset(0, 0)); // garante foco no sheet
    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Endereço'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
