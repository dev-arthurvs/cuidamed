import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utilitarios/tema.dart';
import 'cabecalho.dart';
import 'secao_ajuda.dart';

/// Faixa branca fina no topo das telas internas — equivalente à barra
/// superior do web (BarraSuperior.jsx), acima do cabeçalho da página:
/// ☰ (abre o menu lateral) + logo à esquerda; "?" (ajuda da tela) à direita.
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
    final scaffold = Scaffold.maybeOf(context);
    final temMenu = scaffold?.hasDrawer ?? false;
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
            // Respiro nas laterais: o "?" não encosta na borda da tela.
            padding: EdgeInsets.fromLTRB(temMenu ? 6 : 16, topoSeguro, 12, 0),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CorApp.borda))),
            child: Row(
              children: [
                if (temMenu)
                  IconButton(
                    tooltip: 'Abrir menu',
                    icon: const Icon(Icons.menu, color: CorApp.texto),
                    onPressed: () => scaffold!.openDrawer(),
                  ),
                if (temMenu) const SizedBox(width: 2),
                botaoLogo,
                const Spacer(),
                if (secaoAjuda != null)
                  IconButton(
                    tooltip: 'Ajuda desta tela',
                    icon: const Icon(Icons.help_outline, color: CorApp.azulTexto),
                    onPressed: () => mostrarAjudaDaTela(context, secaoAjuda),
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
