import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';
import '../utilitarios/ajuda_conteudo.dart';
import '../utilitarios/tema.dart';
import 'data_hora_atual.dart';

/// Ícone de comprimido estilizado ao lado do nome "CuidaMed", mesmo padrão
/// de logo do front-end web (front-end cuidamed/src/componentes/LogoMarca.jsx).
/// [claro]: versão sobre fundo azul — ícone quadrado translúcido e texto
/// branco, como o `fundo="transparente" corTexto="claro"` do web.
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
              : const BoxDecoration(gradient: CorApp.gradienteAzul, shape: BoxShape.circle),
          child: Center(
            // Mesmo comprimido do web (.logo-marca__capsula): pílula branca girada
            // 45°, com a metade esquerda em azul-claro recortada pelas bordas
            // arredondadas (clip = o overflow: hidden do CSS). Sem o recorte, a
            // metade colorida vazava como um retângulo escuro atrás da pílula.
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
        // Text.rich (e não RichText) pra herdar a fonte do tema. A logo é marca,
        // não texto de leitura: não cresce com a opção "fonte grande".
        Text.rich(
          textScaler: TextScaler.noScaling,
          TextSpan(
            style: TextStyle(fontSize: tamanhoTexto, fontWeight: FontWeight.w800),
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

/// AppBar padrão das telas internas: logo + título da seção (kicker) + título
/// grande da página — equivalente a componentes/Cabecalho.jsx do web.
class Cabecalho extends StatelessWidget implements PreferredSizeWidget {
  final String kicker;
  final String titulo;
  final List<Widget>? acoes;

  /// Mostra, à direita, data/hora (só em tela larga, como o web) e o avatar do usuário.
  final bool mostrarUsuario;

  /// Largura a partir da qual a data/hora cabe no cabeçalho (o web esconde abaixo de 640px).
  static const larguraComDataHora = 640.0;

  const Cabecalho({super.key, required this.kicker, required this.titulo, this.acoes, this.mostrarUsuario = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      // O ☰ e o "?" ficam na faixa da logo, acima (ver BarraComLogo).
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(kicker.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: CorApp.azulTexto, letterSpacing: 0.4)),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: CorApp.texto, height: 1.15),
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

/// Seção do guia correspondente à rota atual (botão "?", como no web).
SecaoAjuda? secaoAjudaDaRotaAtual(BuildContext context) {
  try {
    final rota = GoRouterState.of(context).matchedLocation;
    final tipo = context.read<AppEstado>().usuario?.tipo ?? 'paciente';
    return obterSecaoAjuda(rota, tipo);
  } catch (_) {
    return null; // fora de uma rota do GoRouter (ex.: página empilhada via Navigator)
  }
}
