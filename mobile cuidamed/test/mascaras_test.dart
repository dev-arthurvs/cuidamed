import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/componentes/campo_texto.dart';
import 'package:cuidamed_mobile/utilitarios/mascaras.dart';

import 'apoio.dart';

void main() {
  group('formatarTelefone', () {
    test('celular, fixo e textos com símbolos', () {
      expect(formatarTelefone('79991234567'), '(79) 99123-4567');
      expect(formatarTelefone('7933334444'), '(79) 3333-4444');
      expect(formatarTelefone('(79) 9 9912-3456'), '(79) 99912-3456');
      expect(formatarTelefone('799912345678999'), '(79) 99123-4567'); // para no 11º dígito
      expect(formatarTelefone(''), '');
    });
  });

  group('MascaraEmailOuTelefone (digitação)', () {
    const mascara = MascaraEmailOuTelefone();
    String digitar(String texto) {
      var valor = TextEditingValue.empty;
      for (final letra in texto.split('')) {
        valor = mascara.formatEditUpdate(valor, TextEditingValue(text: valor.text + letra));
      }
      return valor.text;
    }

    test('só números viram telefone com máscara', () {
      expect(digitar('79999998888'), '(79) 99999-8888');
    });

    test('e-mail fica como foi digitado', () {
      expect(digitar('maria-souza@email.com'), 'maria-souza@email.com');
    });

    test('e-mail que começa com números perde a máscara ao virar e-mail', () {
      expect(digitar('123abc@x.com'), '123abc@x.com');
    });
  });

  group('MascaraTelefone (digitação)', () {
    const mascara = MascaraTelefone();
    TextEditingValue valor(String texto) => TextEditingValue(text: texto);

    test('digitando número a número', () {
      var atual = valor('');
      for (final d in '79991234567'.split('')) {
        atual = mascara.formatEditUpdate(atual, valor(atual.text + d));
      }
      expect(atual.text, '(79) 99123-4567');
      expect(atual.selection.baseOffset, atual.text.length); // cursor no fim
      final extra = mascara.formatEditUpdate(atual, valor('${atual.text}8'));
      expect(extra.text, '(79) 99123-4567'); // 12º dígito ignorado
    });

    test('Backspace no hífen apaga o dígito anterior (não trava)', () {
      final antes = valor('(79) 9912-3456');
      final depois = mascara.formatEditUpdate(antes, valor(antes.text.replaceFirst('-', ''))); // removeu só o "-"
      expect(depois.text, '(79) 9912-345');
      var atual = valor('(79) 99123-4567');
      for (var i = 0; i < 20 && atual.text.isNotEmpty; i++) {
        atual = mascara.formatEditUpdate(atual, valor(atual.text.substring(0, atual.text.length - 1)));
      }
      expect(atual.text, isEmpty); // apaga tudo só com Backspace
    });
  });

  testWidgets('Campo de telefone aplica a máscara ao digitar', (tester) async {
    final controller = TextEditingController();
    await montarPagina(
      tester,
      estadoCuidador(),
      '/x',
      (_) => Scaffold(
        body: CampoTexto(rotulo: 'Telefone', controller: controller, tipoTeclado: TextInputType.phone),
      ),
    );
    await tester.enterText(find.byType(TextField), '79991234567');
    expect(controller.text, '(79) 99123-4567');
  });
}
