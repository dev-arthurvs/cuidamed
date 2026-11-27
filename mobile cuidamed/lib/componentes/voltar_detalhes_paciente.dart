import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';

const rotaDetalhesPaciente = '/cuidador/paciente/:pacienteId';

class VoltarDetalhesPaciente extends StatelessWidget {
  final int? pacienteId;
  const VoltarDetalhesPaciente({super.key, required this.pacienteId});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AppEstado>().usuario;
    final id = pacienteId;
    if (usuario?.tipo != 'cuidador' || id == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextButton.icon(
          onPressed: () => voltar(context, id),
          icon: const Icon(Icons.chevron_left),
          label: const Text('Voltar para os detalhes do paciente'),
        ),
      ),
    );
  }

  static void voltar(BuildContext context, int pacienteId) {
    final roteador = GoRouter.of(context);
    var encontrouDetalhes = false;
    Navigator.of(context).popUntil((rota) {
      if (rota.settings.name == rotaDetalhesPaciente) {
        encontrouDetalhes = true;
        return true;
      }
      return rota.isFirst;
    });
    if (!encontrouDetalhes) roteador.push('/cuidador/paciente/$pacienteId');
  }
}
