import 'package:flutter/material.dart';

import '../utilitarios/tema.dart';

class OpcaoSemEmail extends StatelessWidget {
  final bool marcado;
  final ValueChanged<bool> aoMudar;

  const OpcaoSemEmail({super.key, required this.marcado, required this.aoMudar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => aoMudar(!marcado),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: marcado,
                onChanged: (valor) => aoMudar(valor ?? false),
                activeColor: CorApp.azulSolido,
                visualDensity: VisualDensity.compact,
              ),
              Flexible(
                child: Text(
                  'Não tenho e-mail',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CorApp.textoLabel),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
        if (marcado)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              'O acesso ao app será feito pelo número de telefone.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CorApp.textoSuave),
            ),
          ),
      ],
    );
  }
}
