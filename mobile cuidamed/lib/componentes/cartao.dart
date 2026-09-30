import 'package:flutter/material.dart';
import '../utilitarios/tema.dart';

class Cartao extends StatelessWidget {
  final String? titulo;
  final Widget child;
  final Widget? acao;
  final EdgeInsetsGeometry padding;

  const Cartao({
    super.key,
    this.titulo,
    required this.child,
    this.acao,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CorApp.fundoCard,
        borderRadius: BorderRadius.circular(RaioApp.medio),
        border: Border.all(color: CorApp.borda),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titulo != null || acao != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (titulo != null)
                    Expanded(
                      child: Text(titulo!, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: CorApp.texto)),
                    ),
                  ?acao,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}
