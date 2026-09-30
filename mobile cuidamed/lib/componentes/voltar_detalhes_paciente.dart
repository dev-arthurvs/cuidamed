import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';

/// Caminho da rota dos detalhes do paciente. O go_router usa o caminho como
/// nome da página quando a rota não tem nome, e é assim que o botão abaixo
/// encontra os detalhes na pilha de telas.
const rotaDetalhesPaciente = '/cuidador/paciente/:pacienteId';

/// "‹ Voltar para os detalhes do paciente" — no topo das telas abertas a partir
/// dos detalhes do paciente (agenda, histórico, ciclos encerrados e painel do
/// paciente), como no VoltarDetalhesPaciente.jsx do web. Só para o cuidador: o
/// paciente não tem a tela de detalhes.
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

  /// Se os detalhes já estão na pilha (caminho normal: detalhes → agenda →
  /// ciclos encerrados), volta até eles, mantendo o painel embaixo. Se a tela
  /// foi aberta por outro caminho (ex.: menu lateral), abre os detalhes por cima.
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
