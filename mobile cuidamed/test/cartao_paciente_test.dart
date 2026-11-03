import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/componentes/cartao_paciente.dart';
import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/modelos/paciente.dart';
import 'package:cuidamed_mobile/paginas/painel_idoso.dart';

import 'apoio.dart';

/// Paciente com cuidador vinculado (vínculo nº 12).
AppEstado _comVinculo() {
  final estado = estadoPaciente(cuidadorId: 5);
  final d = estado.pacientes.first;
  final p = d.paciente;
  estado.pacientes = [
    PacienteComDados(
      paciente: Paciente(
        id: p.id,
        nome: p.nome,
        email: p.email,
        dataNascimento: p.dataNascimento,
        sexo: p.sexo,
        cuidadorId: 5,
        codigoVinculo: 12,
      ),
      medicamentos: d.medicamentos,
      historico: d.historico,
    ),
  ];
  return estado;
}

void main() {
  test('Número do cartão a partir do código do vínculo', () {
    expect(CartaoPaciente.numeroDoCartao(12), '0000 0012');
    expect(CartaoPaciente.numeroDoCartao(143), '0000 0143');
  });

  testWidgets('Tela inicial: cartão com dados do paciente, contadores e atalho da agenda', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/painel', (_) => const PainelIdoso());
    expect(find.byType(CartaoPaciente), findsOneWidget);
    expect(find.text('MARIA DA SILVA'), findsOneWidget); // nome completo em caixa alta
    expect(find.text('10/03/1950'), findsOneWidget); // nascimento
    expect(find.text('Feminino'), findsOneWidget); // sexo
    expect(find.text('Nº DO CARTÃO'), findsNothing); // sem cuidador vinculado, sem número
    for (final rotulo in ['Tomados', 'A tomar', 'Atrasados']) {
      expect(find.descendant(of: find.byType(CartaoPaciente), matching: find.text(rotulo)), findsOneWidget);
    }
    await rolarAte(tester, find.text('Ver agenda completa ›')); // no celular, o cartão fica abaixo da dose
    await tester.tap(find.text('Ver agenda completa ›'));
    await tester.pumpAndSettle();
    expect(find.text('rota /agenda'), findsOneWidget);
  });

  testWidgets('Com cuidador vinculado, o cartão mostra o nº (código do vínculo)', (tester) async {
    await montarPagina(tester, _comVinculo(), '/painel', (_) => const PainelIdoso());
    expect(find.text('Nº DO CARTÃO'), findsOneWidget);
    expect(find.text('0000 0012'), findsOneWidget);
  });

  testWidgets('Tela larga: dose à esquerda e cartão à direita; celular: dose em cima', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/painel', (_) => const PainelIdoso(), tamanho: const Size(1300, 900));
    final cartao = tester.getRect(find.byType(CartaoPaciente));
    final proximo = tester.getRect(find.text('Doses de hoje'));
    expect(cartao.left, greaterThan(proximo.right)); // dose à esquerda, cartão à direita

    await montarPagina(tester, estadoPaciente(), '/painel', (_) => const PainelIdoso());
    expect(
      tester.getRect(find.byType(CartaoPaciente)).top,
      greaterThan(tester.getRect(find.text('Doses de hoje')).bottom),
    );
    expect(tester.takeException(), isNull);
  });
}
