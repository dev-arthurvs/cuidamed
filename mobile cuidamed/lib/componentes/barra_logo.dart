import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utilitarios/tema.dart';
import 'cabecalho.dart';
import 'secao_ajuda.dart';

class BarraComLogo extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget abaixo;

  final bool logoLevaAoInicio;

  static const alturaFaixa = 52.0;

  const BarraComLogo({super.key, required this.abaixo, this.logoLevaAoInicio = true});

  @override
  Size get preferredSize => Size.fromHeight(alturaFaixa + abaixo.preferredSize.height);

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.fromLTRB(16, topoSeguro, 16, 0),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: CorApp.borda))),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: botaoLogo),
                  ),
                ),
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
    return null;
  }
}

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

