import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';
import 'barra_logo.dart';
import 'barra_navegacao_inferior.dart';
import 'menu_lateral.dart';

/// Andaime comum de toda tela autenticada: AppBar (via [appBar]) + bottom
/// nav fixa + drawer lateral — equivalente a componentes/LayoutApp.jsx do web.
class AndaimeApp extends StatelessWidget {
  final PreferredSizeWidget appBar;
  final Widget body;
  final Widget? botaoFlutuante;

  const AndaimeApp({super.key, required this.appBar, required this.body, this.botaoFlutuante});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    final rotaAtual = GoRouterState.of(context).matchedLocation;
    final tipoUsuario = estado.usuario?.tipo ?? 'paciente';

    return Scaffold(
      appBar: BarraComLogo(abaixo: appBar),
      drawer: const MenuLateral(),
      body: SafeArea(child: body),
      floatingActionButton: botaoFlutuante,
      bottomNavigationBar: Builder(
        builder: (context) => BarraNavegacaoInferior(
          tipoUsuario: tipoUsuario,
          rotaAtual: rotaAtual,
          aoAbrirMenu: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    );
  }
}
