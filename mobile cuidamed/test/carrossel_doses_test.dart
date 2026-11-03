import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/componentes/carrossel_doses.dart';
import 'package:cuidamed_mobile/modelos/dose.dart';

Dose _dose(String horario, String nome, String status) => Dose(
      id: '${nome.hashCode}-$horario',
      medicamentoId: nome.hashCode,
      horario: horario,
      nome: nome,
      dosagem: '10mg',
      forma: 'COMPRIMIDO',
      quantidadePorDose: 1,
      status: status,
    );

final _doses = [
  _dose('08:00', 'Atenolol', 'perdido'),
  _dose('10:00', 'Losartana', 'tomado'),
  _dose('13:00', 'Metformina', 'atrasado'),
  _dose('15:00', 'Sinvastatina', 'pendente'),
];

/// Texto completo de uma linha pequena (Text.rich com horário + nome).
Finder _linha(String texto) => find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains(texto));

final _desfeitas = <Dose>[];

Future<List<Dose>> _montar(WidgetTester tester, List<Dose> doses, {double largura = 360, bool botaoAoLado = false}) async {
  final registradas = <Dose>[];
  _desfeitas.clear();
  tester.view.physicalSize = Size(largura, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Container(
        color: const Color(0xFF0B2F63),
        padding: const EdgeInsets.all(20),
        child: CarrosselDoses(
          doses: doses,
          aoRegistrar: (dose) async {
            registradas.add(dose);
            return true;
          },
          aoDesfazer: _desfeitas.add,
          botaoAoLado: botaoAoLado,
        ),
      ),
    ),
  ));
  return registradas;
}

void main() {
  testWidgets('Abre na dose da vez (atrasada) com a anterior e a próxima pequenas', (tester) async {
    final registradas = await _montar(tester, _doses);
    expect(find.text('Metformina'), findsOneWidget); // em foco, grande
    expect(find.text('Atrasada'), findsOneWidget);
    expect(_linha('Losartana'), findsOneWidget); // anterior, tomada
    expect(_linha('Sinvastatina'), findsOneWidget); // próxima
    expect(find.byIcon(Icons.check), findsOneWidget); // ✓ da tomada

    await tester.tap(find.text('Registrar dose'));
    await tester.pump();
    expect(registradas.single.nome, 'Metformina');

    // Logo depois de registrar, um pop-up oferece "Desfazer", com a barrinha do
    // tempo que resta, e some sozinho.
    expect(find.text('Dose das 13:00 registrada.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.getTopLeft(find.text('Dose das 13:00 registrada.')).dy, greaterThan(tester.getBottomLeft(find.text('Registrar dose')).dy));
    final inicio = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value!;
    await tester.pump(const Duration(seconds: 6));
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value!, lessThan(inicio));
    await tester.tap(find.text('Desfazer'));
    await tester.pump();
    expect(_desfeitas.single.nome, 'Metformina');
    expect(find.text('Dose das 13:00 registrada.'), findsNothing);

    await tester.tap(find.text('Registrar dose'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 13));
    expect(find.text('Dose das 13:00 registrada.'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('Só as setas trocam de dose: arrastar e tocar na linha pequena não', (tester) async {
    await _montar(tester, _doses);

    await tester.drag(find.text('Metformina'), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(find.text('Metformina'), findsOneWidget);

    await tester.tap(_linha('Sinvastatina'));
    await tester.pumpAndSettle();
    expect(find.text('Metformina'), findsOneWidget);

    // Seta ↑ no alto do card e seta ↓ no canto inferior, à direita das linhas.
    final cima = tester.getRect(find.byTooltip('Dose anterior'));
    final baixo = tester.getRect(find.byTooltip('Próxima dose'));
    final proxima = tester.getRect(_linha('Sinvastatina'));
    expect(cima.bottom, lessThan(tester.getTopLeft(find.text('Metformina')).dy));
    expect(baixo.top, greaterThan(tester.getBottomLeft(find.text('Metformina')).dy));
    expect(baixo.left, greaterThanOrEqualTo(proxima.right));
    expect(cima.right, baixo.right);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seta ↑ volta às doses anteriores; perdida fica riscada com ✕', (tester) async {
    await _montar(tester, _doses);
    await tester.tap(find.byTooltip('Dose anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Losartana'), findsOneWidget);
    expect(find.text('Tomada'), findsOneWidget);
    expect(find.text('Registrar dose'), findsNothing); // só a dose da vez é registrada aqui

    // Dose tomada em foco: dá para desfazer.
    await tester.tap(find.text('Desfazer'));
    await tester.pump();
    expect(_desfeitas.single.nome, 'Losartana');

    final perdida = tester.widget<RichText>(_linha('Atenolol'));
    expect(perdida.text.style?.decoration, TextDecoration.lineThrough);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Seta ↓ volta para a dose da vez.
    await tester.tap(find.byTooltip('Próxima dose'));
    await tester.pumpAndSettle();
    expect(find.text('Metformina'), findsOneWidget);
    expect(find.text('Registrar dose'), findsOneWidget);
  });

  testWidgets('Tudo resolvido: foco em "Nada pendente" com a última dose em cima', (tester) async {
    await _montar(tester, [_dose('08:00', 'Atenolol', 'perdido'), _dose('10:00', 'Losartana', 'tomado')]);
    expect(find.text('Nada pendente'), findsOneWidget);
    expect(find.text('Algumas doses de hoje foram perdidas.'), findsOneWidget);
    expect(_linha('Losartana'), findsOneWidget);
    expect(find.text('Registrar dose'), findsNothing);
  });

  testWidgets('Tela larga: "Registrar dose" ao lado da dose; sem overflow', (tester) async {
    await _montar(tester, _doses, largura: 900, botaoAoLado: true);
    final botao = tester.getRect(find.text('Registrar dose'));
    final nome = tester.getRect(find.text('Metformina'));
    expect(botao.left, greaterThan(nome.right));
    expect(tester.takeException(), isNull);
  });
}
