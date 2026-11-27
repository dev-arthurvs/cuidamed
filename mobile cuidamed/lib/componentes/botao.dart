import 'package:flutter/material.dart';
import '../utilitarios/tema.dart';

enum VarianteBotao { primario, solido, secundario, contorno, perigo, perigoCheio, sobreAzul }

class Botao extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final VarianteBotao variante;
  final bool carregando;
  final IconData? icone;
  final bool larguraTotal;

  final bool compacto;

  const Botao({
    super.key,
    required this.texto,
    required this.onPressed,
    this.variante = VarianteBotao.primario,
    this.carregando = false,
    this.icone,
    this.larguraTotal = true,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final desabilitado = onPressed == null || carregando;
    final altura = compacto ? 44.0 : 56.0;
    final tamanhoTexto = compacto ? 15.0 : 17.0;
    final paddingLateral = EdgeInsets.symmetric(horizontal: compacto ? 16 : 22);
    final conteudo = carregando
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[Icon(icone, size: compacto ? 19 : 22), SizedBox(width: compacto ? 8 : 10)],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(texto, maxLines: 1, style: TextStyle(fontSize: tamanhoTexto, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          );

    final tamanhoMinimo = larguraTotal ? Size.fromHeight(altura) : Size(64, altura);

    Widget botao;
    switch (variante) {
      case VarianteBotao.primario:
      case VarianteBotao.solido:
        final solido = variante == VarianteBotao.solido;
        botao = Container(
          decoration: BoxDecoration(
            gradient: desabilitado || solido ? null : CorApp.gradienteAzul,
            color: desabilitado ? CorApp.textoSuave.withValues(alpha: 0.35) : (solido ? CorApp.azulSolido : null),
            borderRadius: BorderRadius.circular(RaioApp.medio),
            boxShadow: solido && !desabilitado
                ? const [BoxShadow(color: Color(0x470F3F80), blurRadius: 22, offset: Offset(0, 10))]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(RaioApp.medio),
              onTap: desabilitado ? null : onPressed,
              child: Container(
                height: altura,
                padding: larguraTotal ? null : paddingLateral,
                alignment: Alignment.center,
                child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.white), child: conteudo),
              ),
            ),
          ),
        );
        break;
      case VarianteBotao.secundario:
        botao = OutlinedButton(
          onPressed: desabilitado ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: tamanhoMinimo,
            padding: larguraTotal ? const EdgeInsets.symmetric(horizontal: 12) : paddingLateral,
            side: BorderSide(color: CorApp.azul, width: 2),
            backgroundColor: CorApp.azulFundo,
            foregroundColor: CorApp.azulTexto,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaioApp.medio)),
          ),
          child: conteudo,
        );
        break;
      case VarianteBotao.contorno:
        botao = OutlinedButton(
          onPressed: desabilitado ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: tamanhoMinimo,
            padding: larguraTotal ? const EdgeInsets.symmetric(horizontal: 12) : paddingLateral,
            side: BorderSide(color: CorApp.borda, width: 1.5),
            foregroundColor: CorApp.texto,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaioApp.medio)),
          ),
          child: conteudo,
        );
        break;
      case VarianteBotao.perigo:
        botao = OutlinedButton(
          onPressed: desabilitado ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: tamanhoMinimo,
            padding: larguraTotal ? const EdgeInsets.symmetric(horizontal: 12) : paddingLateral,
            side: BorderSide(color: CorApp.vermelho, width: 2),
            backgroundColor: CorApp.vermelhoFundo,
            foregroundColor: CorApp.vermelhoTexto,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaioApp.medio)),
          ),
          child: conteudo,
        );
        break;
      case VarianteBotao.sobreAzul:
        botao = OutlinedButton(
          onPressed: desabilitado ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: tamanhoMinimo,
            padding: larguraTotal ? const EdgeInsets.symmetric(horizontal: 12) : paddingLateral,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaioApp.medio)),
          ),
          child: conteudo,
        );
        break;
      case VarianteBotao.perigoCheio:
        botao = FilledButton(
          onPressed: desabilitado ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: tamanhoMinimo,
            padding: larguraTotal ? const EdgeInsets.symmetric(horizontal: 12) : paddingLateral,
            backgroundColor: CorApp.vermelho,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaioApp.medio)),
          ),
          child: conteudo,
        );
        break;
    }

    botao = _EfeitoPressionar(ativo: !desabilitado, child: botao);
    return larguraTotal ? SizedBox(width: double.infinity, child: botao) : botao;
  }
}

class _EfeitoPressionar extends StatefulWidget {
  final bool ativo;
  final Widget child;
  const _EfeitoPressionar({required this.ativo, required this.child});

  @override
  State<_EfeitoPressionar> createState() => _EfeitoPressionarState();
}

class _EfeitoPressionarState extends State<_EfeitoPressionar> {
  bool _pressionado = false;

  void _definir(bool valor) {
    if (_pressionado != valor && mounted) setState(() => _pressionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.ativo ? (_) => _definir(true) : null,
      onPointerUp: (_) => _definir(false),
      onPointerCancel: (_) => _definir(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        transform: Matrix4.translationValues(0, _pressionado ? 1 : 0, 0),
        child: widget.child,
      ),
    );
  }
}
