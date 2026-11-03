import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utilitarios/tema.dart';
import 'cabecalho.dart';
import 'secao_ajuda.dart';

/// Faixa branca fina no topo das telas internas — equivalente à barra
/// superior do web (BarraSuperior.jsx), acima do cabeçalho da página:
/// logo à esquerda; engrenagem (Configurações) e "?" (ajuda da tela) à direita.
/// Envolve o [abaixo] (o Cabecalho/AppBar da tela) num único appBar do Scaffold.
class BarraComLogo extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget abaixo;

  /// Toque na logo leva ao Início (como no web). Desligado onde sair no meio
  /// de uma ação seria ruim (ex.: formulário de medicamento).
  final bool logoLevaAoInicio;

  static const alturaFaixa = 52.0;

  const BarraComLogo({super.key, required this.abaixo, this.logoLevaAoInicio = true});

  @override
  Size get preferredSize => Size.fromHeight(alturaFaixa + abaixo.preferredSize.height);

  @override
  Widget build(BuildContext context) {
    // O Scaffold reserva a área da barra de status pro appBar: a faixa da logo
    // ocupa esse espaço e o cabeçalho de baixo não precisa repeti-lo.
    final topoSeguro = MediaQuery.paddingOf(context).top;
    const logo = LogoCuidaMed(tamanho: 30, tamanhoTexto: 18);
    final secaoAjuda = secaoAjudaDaRotaAtual(context);
    final botaoLogo = logoLevaAoInicio
        ? Semantics(
            button: true,
            label: 'Ir para o início',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.go('/painel'),
              child: const Padding(padding: EdgeInsets.all(4), child: logo),
            ),
          )
        : const Padding(padding: EdgeInsets.all(4), child: logo);

    return Material(
      color: CorApp.fundoCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: alturaFaixa + topoSeguro,
            // O "?" fica no canto, com o mesmo respiro da borda que o web (16 px).
            padding: EdgeInsets.fromLTRB(16, topoSeguro, 16, 0),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: CorApp.borda))),
            child: Row(
              children: [
                // A logo ocupa todo o espaço livre (alinhada à esquerda), o que
                // empurra a engrenagem e o "?" para o canto direito em qualquer
                // largura. Em tela estreita com fonte grande, ela encolhe para
                // caber logo + engrenagem + "?" na mesma linha.
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: botaoLogo),
                  ),
                ),
                // Engrenagem (Configurações) ao lado do "?", como no web. Some
                // onde sair no meio de uma ação seria ruim (mesma regra da logo).
                if (logoLevaAoInicio)
                  _BotaoRedondo(
                    rotulo: 'Configurações',
                    ativo: _rotaAtual(context) == '/configuracoes',
                    onPressed: () => context.go('/configuracoes'),
                    child: const Icon(Icons.settings_outlined, size: 19),
                  ),
                if (logoLevaAoInicio && secaoAjuda != null) const SizedBox(width: 8),
                if (secaoAjuda != null)
                  _BotaoRedondo(
                    rotulo: 'Ajuda desta tela',
                    onPressed: () => mostrarAjudaDaTela(context, secaoAjuda),
                    child: const Text('?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1)),
                  ),
              ],
            ),
          ),
          // O AppBar precisa de altura definida (numa Column ela seria ilimitada).
          SizedBox(
            height: abaixo.preferredSize.height,
            child: MediaQuery.removePadding(context: context, removeTop: true, child: abaixo),
          ),
        ],
      ),
    );
  }
}

String? _rotaAtual(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.path;
  } catch (_) {
    return null; // fora de uma rota do GoRouter (ex.: alguns testes)
  }
}

/// Botão redondo pequeno igual ao do web (.barra-superior__ajuda): 32 px de
/// fundo azul-claro com borda; na tela de Configurações a engrenagem fica
/// preenchida, como item ativo. A área de toque é maior que o círculo (40 px).
class _BotaoRedondo extends StatelessWidget {
  final String rotulo;
  final VoidCallback onPressed;
  final Widget child;
  final bool ativo;

  const _BotaoRedondo({required this.rotulo, required this.onPressed, required this.child, this.ativo = false});

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? CorApp.fundoCard : CorApp.azulTexto;
    return Tooltip(
      message: rotulo,
      child: Semantics(
        button: true,
        label: rotulo,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          radius: 22,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ativo ? CorApp.azulTexto : CorApp.azulFundo,
                  shape: BoxShape.circle,
                  border: Border.all(color: ativo ? CorApp.azulTexto : CorApp.bordaDestaque, width: 1.5),
                ),
                child: IconTheme(
                  data: IconThemeData(color: cor),
                  child: DefaultTextStyle.merge(style: TextStyle(color: cor), child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

