import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';
import '../utilitarios/ajuda_conteudo.dart';
import '../utilitarios/tema.dart';
import 'data_hora_atual.dart';

class LogoCuidaMed extends StatelessWidget {
  final double tamanho;
  final double tamanhoTexto;
  final bool claro;
  const LogoCuidaMed({super.key, this.tamanho = 30, this.tamanhoTexto = 20, this.claro = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tamanho,
          height: tamanho,
          decoration: claro
              ? BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(tamanho * 0.22))
              : BoxDecoration(gradient: CorApp.gradienteAzul, shape: BoxShape.circle),
          child: Center(
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: tamanho * 0.57,
                height: tamanho * 0.26,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(tamanho * 0.13),
                ),
                child: Row(
                  children: [
                    Expanded(child: Container(color: const Color(0xFFBFDCFF))),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: tamanho * 0.32),
        Text.rich(
          textScaler: TextScaler.noScaling,
          TextSpan(
            style: TextStyle(fontSize: tamanhoTexto, fontWeight: FontWeight.w700),
            children: [
              TextSpan(text: 'Cuida', style: TextStyle(color: claro ? Colors.white : CorApp.texto)),
              TextSpan(text: 'Med', style: TextStyle(color: claro ? Colors.white : CorApp.azul)),
            ],
          ),
        ),
      ],
    );
  }
}

class Cabecalho extends StatelessWidget implements PreferredSizeWidget {
  final String kicker;
  final String titulo;
  final List<Widget>? acoes;

  final bool mostrarUsuario;

  static const larguraComDataHora = 640.0;

  const Cabecalho({super.key, required this.kicker, required this.titulo, this.acoes, this.mostrarUsuario = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(kicker.toUpperCase(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CorApp.azulTexto, letterSpacing: 0.4)),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CorApp.texto, height: 1.15),
          ),
        ],
      ),
      actions: [
        ...?acoes,
        if (mostrarUsuario) ..._acoesUsuario(context),
        const SizedBox(width: 12),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: CorApp.borda, height: 1)),
    );
  }

  List<Widget> _acoesUsuario(BuildContext context) {
    final nome = context.select<AppEstado, String?>((e) => e.usuario?.nome);
    if (nome == null) return const [];
    final largo = MediaQuery.sizeOf(context).width >= larguraComDataHora;
    return [
      if (largo) ...[const DataHoraCabecalho(), const SizedBox(width: 14)],
      AvatarUsuario(nome: nome, tamanho: largo ? 44 : 38),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(73);
}

SecaoAjuda? secaoAjudaDaRotaAtual(BuildContext context) {
  try {
    final rota = GoRouterState.of(context).matchedLocation;
    final tipo = context.read<AppEstado>().usuario?.tipo ?? 'paciente';
    return obterSecaoAjuda(rota, tipo);
  } catch (_) {
    return null;
  }
}
