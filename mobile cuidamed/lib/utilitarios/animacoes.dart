import 'dart:async';

import 'package:flutter/material.dart';

/// Animações do app — mesmas do web (utilitarios/animacoes.js, LayoutApp.jsx e
/// os @keyframes cm-modal-* do global.css), pra manter a mesma sensação de
/// movimento nas duas plataformas. Todas respeitam o "reduzir movimento" do
/// sistema (o web faz o mesmo com prefers-reduced-motion).

/// Itens de lista: 0,22 s easeOut (TRANSICAO_ITEM_LISTA do web).
const duracaoItemLista = Duration(milliseconds: 220);

/// Troca de tela: 0,22 s easeInOut (variantesPagina do LayoutApp.jsx).
const duracaoPagina = Duration(milliseconds: 220);

/// Caixas de diálogo: cubic-bezier(0.16, 1, 0.3, 1) — sobe e "assenta".
const curvaModal = Cubic(0.16, 1, 0.3, 1);

bool _semAnimacao(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Entrada de item de lista (VARIANTES_ITEM_LISTA do web): aparece subindo
/// [deslocamento] px e crescendo de 98% → 100%. [indice] escalona a entrada
/// dos itens (cascata curta, no máximo 240 ms de atraso).
class EntradaSuave extends StatefulWidget {
  final Widget child;
  final int indice;
  final double deslocamento;
  final double escalaInicial;
  final Duration duracao;
  final Curve curva;

  const EntradaSuave({
    super.key,
    required this.child,
    this.indice = 0,
    this.deslocamento = 12,
    this.escalaInicial = 0.98,
    this.duracao = duracaoItemLista,
    this.curva = Curves.easeOut,
  });

  @override
  State<EntradaSuave> createState() => _EntradaSuaveState();
}

class _EntradaSuaveState extends State<EntradaSuave> with SingleTickerProviderStateMixin {
  late final AnimationController _controle = AnimationController(vsync: this, duration: widget.duracao);
  late final Animation<double> _progresso = CurvedAnimation(parent: _controle, curve: widget.curva);
  Timer? _atraso;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controle.isAnimating || _controle.isCompleted || _atraso != null) return;
    if (_semAnimacao(context)) {
      _controle.value = 1;
      return;
    }
    final espera = Duration(milliseconds: (widget.indice * 40).clamp(0, 240));
    if (espera == Duration.zero) {
      _controle.forward();
    } else {
      _atraso = Timer(espera, () {
        if (mounted) _controle.forward();
      });
    }
  }

  @override
  void dispose() {
    _atraso?.cancel();
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progresso,
      child: widget.child,
      builder: (context, filho) {
        final v = _progresso.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, widget.deslocamento * (1 - v)),
            child: Transform.scale(scale: widget.escalaInicial + (1 - widget.escalaInicial) * v, child: filho),
          ),
        );
      },
    );
  }
}

/// Troca de tela (LayoutApp.jsx do web): a nova página aparece com fade
/// subindo 10 px. Registrada no tema, vale pro GoRouter e pro Navigator.
class TransicaoPaginaCuidaMed extends PageTransitionsBuilder {
  const TransicaoPaginaCuidaMed();

  @override
  Duration get transitionDuration => duracaoPagina;

  @override
  Duration get reverseTransitionDuration => duracaoPagina;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_semAnimacao(context)) return child;
    final curva = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curva,
      child: child,
      builder: (context, filho) => Opacity(
        opacity: curva.value,
        child: Transform.translate(offset: Offset(0, 10 * (1 - curva.value)), child: filho),
      ),
    );
  }
}

/// Caixa de diálogo com a animação dos modais do web: fundo escurece (fade) e
/// a caixa sobe 16 px crescendo de 97% → 100% com curva "elástica".
Future<T?> mostrarDialogoAnimado<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color barrierColor = const Color(0x800C2342),
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: _semAnimacao(context) ? Duration.zero : const Duration(milliseconds: 220),
    pageBuilder: (contexto, _, _) => builder(contexto),
    transitionBuilder: (contexto, animacao, _, filho) {
      final caixa = CurvedAnimation(parent: animacao, curve: curvaModal, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animacao, curve: Curves.easeOut),
        child: AnimatedBuilder(
          animation: caixa,
          child: filho,
          builder: (context, f) => Transform.translate(
            offset: Offset(0, 16 * (1 - caixa.value)),
            child: Transform.scale(scale: 0.97 + 0.03 * caixa.value, child: f),
          ),
        ),
      );
    },
  );
}

/// Para AnimatedSwitcher: o conteúdo novo entra com fade subindo [deslocamento]
/// px (como os `initial: {opacity: 0, y: 8}` do framer-motion no web).
AnimatedSwitcherTransitionBuilder transicaoTrocaSuave({double deslocamento = 8}) {
  return (filho, animacao) {
    final curva = CurvedAnimation(parent: animacao, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curva,
      child: AnimatedBuilder(
        animation: curva,
        child: filho,
        builder: (context, f) => Transform.translate(offset: Offset(0, deslocamento * (1 - curva.value)), child: f),
      ),
    );
  };
}
