import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cuidamed_mobile/app.dart';
import 'package:cuidamed_mobile/componentes/voltar_detalhes_paciente.dart';
import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/paginas/agenda_medicamentos.dart';
import 'package:cuidamed_mobile/paginas/ciclos_encerrados.dart';
import 'package:cuidamed_mobile/paginas/historico.dart';
import 'package:cuidamed_mobile/paginas/painel_paciente.dart';
import 'package:cuidamed_mobile/utilitarios/tema.dart';

import 'apoio.dart';

const _texto = 'Voltar para os detalhes do paciente';

/// Router com o caminho real: painel → detalhes → agenda → ciclos encerrados.
Future<GoRouter> _montarFluxo(WidgetTester tester, AppEstado estado) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/painel',
    routes: [
      GoRoute(path: '/painel', builder: (_, _) => const Scaffold(body: Text('tela painel'))),
      GoRoute(path: rotaDetalhesPaciente, builder: (_, _) => const Scaffold(body: Text('tela detalhes'))),
      GoRoute(path: '/agenda', builder: (_, _) => const AgendaMedicamentos()),
      GoRoute(path: '/ciclos-encerrados', builder: (_, _) => const CiclosEncerrados()),
    ],
  );
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: estado,
    child: MaterialApp.router(theme: construirTema(), routerConfig: router, builder: aplicarEscalaFonte),
  ));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('Aparece para o cuidador nas quatro telas', (tester) async {
    for (final (rota, pagina) in [
      ('/agenda', const AgendaMedicamentos() as Widget),
      ('/ciclos-encerrados', const CiclosEncerrados()),
      ('/historico', const HistoricoPagina()),
      ('/cuidador/paciente/1/painel', const PainelPaciente(pacienteId: 1)),
    ]) {
      await montarPagina(tester, estadoCuidador(), rota, (_) => pagina);
      expect(find.text(_texto), findsOneWidget, reason: rota);
    }
  });

  testWidgets('Não aparece para o paciente', (tester) async {
    for (final (rota, pagina) in [
      ('/agenda', const AgendaMedicamentos() as Widget),
      ('/ciclos-encerrados', const CiclosEncerrados()),
      ('/historico', const HistoricoPagina()),
    ]) {
      await montarPagina(tester, estadoPaciente(), rota, (_) => pagina);
      expect(find.text(_texto), findsNothing, reason: rota);
    }
  });

  testWidgets('Volta pela pilha até os detalhes, mantendo o painel embaixo', (tester) async {
    final router = await _montarFluxo(tester, estadoCuidador());
    router.push('/cuidador/paciente/1');
    await tester.pumpAndSettle();
    router.push('/agenda');
    await tester.pumpAndSettle();
    router.push('/ciclos-encerrados');
    await tester.pumpAndSettle();

    await tester.tap(find.text(_texto));
    await tester.pumpAndSettle();
    expect(find.text('tela detalhes'), findsOneWidget);

    // O painel continua embaixo: voltar dos detalhes leva ao painel.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('tela painel'), findsOneWidget);
  });

  testWidgets('Aberta por fora dos detalhes (menu): abre os detalhes por cima', (tester) async {
    final router = await _montarFluxo(tester, estadoCuidador());
    router.push('/agenda');
    await tester.pumpAndSettle();

    await tester.tap(find.text(_texto));
    await tester.pumpAndSettle();
    expect(find.text('tela detalhes'), findsOneWidget);
    expect(router.state.uri.path, '/cuidador/paciente/1');
  });
}
