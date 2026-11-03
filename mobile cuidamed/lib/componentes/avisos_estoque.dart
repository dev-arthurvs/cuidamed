import 'package:flutter/material.dart';

import '../estado/app_estado.dart';
import '../utilitarios/horarios.dart';
import '../utilitarios/tema.dart';
import 'cartao.dart';

/// Remédios com estoque baixo ou esgotado, como em AvisosEstoque.jsx do web.
/// Sem nenhum, o card não aparece.
class AvisosEstoque extends StatelessWidget {
  final PacienteComDados dados;

  /// Espaço acima do card, só quando ele aparece.
  final double espacoAcima;

  const AvisosEstoque({super.key, required this.dados, this.espacoAcima = 20});

  @override
  Widget build(BuildContext context) {
    final avisos = avisosEstoque(dados.medicamentosAtivos(), dados.historico);
    if (avisos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: espacoAcima),
      child: Cartao(
        titulo: 'Estoque acabando',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (indice, aviso) in avisos.indexed)
              Container(
                margin: EdgeInsets.only(top: indice == 0 ? 0 : 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: aviso.esgotado ? CorApp.vermelhoFundo : CorApp.amareloFundo,
                  borderRadius: BorderRadius.circular(RaioApp.pequeno),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: aviso.esgotado ? CorApp.vermelhoTexto : CorApp.amareloTexto,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(aviso.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(aviso.texto),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
