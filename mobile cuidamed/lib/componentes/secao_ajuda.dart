import 'package:flutter/material.dart';

import '../utilitarios/ajuda_conteudo.dart';
import '../utilitarios/tema.dart';

/// "Para que serve" + passo a passo numerado — equivalente a SecaoAjuda.jsx.
class SecaoAjudaConteudo extends StatelessWidget {
  final SecaoAjuda secao;
  final bool mostrarTitulo;
  const SecaoAjudaConteudo({super.key, required this.secao, this.mostrarTitulo = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mostrarTitulo) ...[
          Text(secao.titulo, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
        ],
        Text(secao.paraQueServe, style: const TextStyle(color: CorApp.textoLabel, height: 1.4)),
        const SizedBox(height: 12),
        for (var i = 0; i < secao.passos.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 10, top: 1),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: CorApp.azulFundo, shape: BoxShape.circle),
                  child: Text('${i + 1}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: CorApp.azulTexto)),
                ),
                Expanded(child: Text(secao.passos[i], style: const TextStyle(height: 1.4))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Abre a ajuda da tela atual numa folha inferior (botão "?" do cabeçalho).
void mostrarAjudaDaTela(BuildContext context, SecaoAjuda secao) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: CorApp.fundoCard,
    builder: (contexto) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(contexto).size.height * 0.8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SecaoAjudaConteudo(secao: secao),
        ),
      ),
    ),
  );
}
