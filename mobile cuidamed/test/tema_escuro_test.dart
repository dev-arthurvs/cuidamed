import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cuidamed_mobile/paginas/agenda_medicamentos.dart';
import 'package:cuidamed_mobile/paginas/edicao_perfil.dart';
import 'package:cuidamed_mobile/paginas/historico.dart';
import 'package:cuidamed_mobile/paginas/painel_cuidador.dart';
import 'package:cuidamed_mobile/paginas/painel_idoso.dart';
import 'package:cuidamed_mobile/utilitarios/tema.dart';

import 'apoio.dart';

void main() {
  tearDown(() => CorApp.usarModoEscuro(false));

  test('Paleta escura: mesmos tons do web e cards da tela inicial invertidos', () {
    CorApp.usarModoEscuro(true);
    expect(CorApp.escuro, isTrue);
    expect(CorApp.fundo, const Color(0xFF0D1624));
    expect(CorApp.texto, const Color(0xFFE6EDF6));
    expect(CorApp.fundoCardDose, CorApp.gradienteCartaoClaro); // dose clara no escuro
    expect(CorApp.fundoCartaoPaciente, CorApp.gradienteCartaoEscuro);

    CorApp.usarModoEscuro(false);
    expect(CorApp.fundo, const Color(0xFFEEF4FB));
    expect(CorApp.fundoCardDose, CorApp.gradienteCartaoEscuro); // dose escura no claro
  });

  test('Tema salvo no aparelho e só vale dentro do sistema', () async {
    SharedPreferences.setMockInitialValues({});
    final estado = estadoPaciente();
    expect(estado.modoEscuro, isFalse);
    await estado.alternarTema();
    expect(estado.tema, 'escuro');
    expect(estado.usarModoEscuro, isTrue);
    expect((await SharedPreferences.getInstance()).getString('tema'), 'escuro');

    // Deslogado (login, cadastro, ativação): sempre claro.
    await estado.sair();
    expect(estado.modoEscuro, isTrue);
    expect(estado.usarModoEscuro, isFalse);
  });

  testWidgets('Configurações › Aparência: botões Claro / Escuro', (tester) async {
    final estado = estadoPaciente();
    await montarPagina(tester, estado, '/configuracoes', (_) => const EdicaoPerfil());
    await rolarAte(tester, find.text('Escuro'));
    expect(find.text('Tema'), findsOneWidget);
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    expect(estado.tema, 'escuro');
    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(estado.tema, 'claro');
  });

  testWidgets('Telas principais desenham no modo escuro sem erro, com fundo escuro', (tester) async {
    final telas = <(String, Widget Function(GoRouterState), bool)>[
      ('/painel', (_) => const PainelIdoso(), false),
      ('/painel', (_) => const PainelCuidador(), true),
      ('/agenda', (_) => const AgendaMedicamentos(), false),
      ('/agenda?aba=encerrados', (_) => const AgendaMedicamentos(), false),
      ('/historico', (_) => const HistoricoPagina(), false),
      ('/configuracoes', (_) => const EdicaoPerfil(), false),
    ];
    for (final (rota, tela, cuidador) in telas) {
      CorApp.usarModoEscuro(true);
      final estado = cuidador ? estadoCuidador() : estadoPaciente();
      estado.tema = 'escuro';
      await montarPagina(tester, estado, rota, tela);
      expect(tester.takeException(), isNull, reason: rota);
      final fundo = tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor ??
          Theme.of(tester.element(find.byType(Scaffold).first)).scaffoldBackgroundColor;
      expect(fundo, const Color(0xFF0D1624), reason: rota);
    }
  });
}
