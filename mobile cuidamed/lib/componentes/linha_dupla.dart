import 'package:flutter/material.dart';

class LinhaDupla extends StatelessWidget {
  final Widget esquerda;
  final Widget direita;
  final double larguraMinima;
  final double espaco;

  const LinhaDupla({
    super.key,
    required this.esquerda,
    required this.direita,
    this.larguraMinima = 680,
    this.espaco = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        if (restricoes.maxWidth < larguraMinima) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [esquerda, SizedBox(height: espaco), direita],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: esquerda), SizedBox(width: espaco), Expanded(child: direita)],
          ),
        );
      },
    );
  }
}
