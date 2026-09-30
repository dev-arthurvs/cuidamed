import 'package:flutter/material.dart';
import '../utilitarios/tema.dart';

/// perigo = contorno vermelho (ex.: "Excluir" nos cards); perigoCheio = vermelho
/// sólido com texto branco (botão de confirmar do ModalConfirmacao do web).
/// sobreAzul = texto e contorno brancos, pra botões em cima de cards com o
/// gradiente azul (ex.: "Registrar dose" no Início do paciente).
enum VarianteBotao { primario, secundario, contorno, perigo, perigoCheio, sobreAzul }

class Botao extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final VarianteBotao variante;
  final bool carregando;
  final IconData? icone;
  final bool larguraTotal;

  /// Versão menor (44 px, texto 15) — equivalente ao `tamanho="pequeno"` do web,
  /// pra botões no cabeçalho de cards.
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
    // Respiro lateral quando o botão tem a largura do conteúdo — sem isso o
    // texto encosta nas bordas (era o caso do "+ Cadastrar" no painel).
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
              // Encolhe o texto em vez de estourar quando o botão é estreito
              // (ex.: 3 botões lado a lado com fonte "Grande").
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(texto, maxLines: 1, style: TextStyle(fontSize: tamanhoTexto, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          );

    // Size.fromHeight = largura infinita: só serve quando o botão ocupa a
    // linha toda; compacto (ex.: dentro de uma Row) precisa de largura finita.
    final tamanhoMinimo = larguraTotal ? Size.fromHeight(altura) : Size(64, altura);

    Widget botao;
    switch (variante) {
      case VarianteBotao.primario:
        botao = Container(
          decoration: BoxDecoration(
            gradient: desabilitado ? null : CorApp.gradienteAzul,
            color: desabilitado ? CorApp.textoSuave.withValues(alpha: 0.35) : null,
            borderRadius: BorderRadius.circular(RaioApp.medio),
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
                // merge (e não DefaultTextStyle puro) pra manter a fonte do tema e só trocar a cor.
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
            side: const BorderSide(color: CorApp.azul, width: 2),
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
            side: const BorderSide(color: CorApp.borda, width: 1.5),
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
            side: const BorderSide(color: CorApp.vermelho, width: 2),
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

/// O botão "afunda" 1 px enquanto é pressionado — igual ao `.botao:active` do web.
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
