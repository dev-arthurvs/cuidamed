import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utilitarios/tema.dart';
import '../utilitarios/whatsapp.dart';

const Set<String> _statusVisiveis = {'pendente', 'atrasado', 'perdido'};

/// Ícone circular de lembrete via WhatsApp — mesma regra do web
/// (componentes/BotaoWhatsApp.jsx): só aparece pra doses ainda não tomadas,
/// desabilitado se o paciente não tiver telefone. Ícone genérico (telefone
/// em linha), não o logotipo oficial da WhatsApp.
class BotaoWhatsApp extends StatelessWidget {
  final String nomePaciente;
  final String? telefone;
  final String medicamento;
  final String dosagem;
  final String forma;
  final int? quantidadePorDose;
  final DateTime? dataFim;
  final String horario;
  final String status;

  const BotaoWhatsApp({
    super.key,
    required this.nomePaciente,
    required this.telefone,
    required this.medicamento,
    required this.dosagem,
    required this.forma,
    this.quantidadePorDose,
    this.dataFim,
    required this.horario,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (!_statusVisiveis.contains(status)) return const SizedBox.shrink();

    final link = montarLinkWhatsApp(
      telefone: telefone,
      nomePaciente: nomePaciente,
      medicamento: medicamento,
      horario: horario,
      forma: forma,
      quantidadePorDose: quantidadePorDose,
      dosagem: dosagem,
      dataFim: dataFim,
    );
    final desabilitado = link == null;

    return Tooltip(
      message: desabilitado ? 'Paciente sem telefone cadastrado' : 'Enviar lembrete por WhatsApp',
      child: Material(
        color: desabilitado ? CorApp.textoSuave.withValues(alpha: 0.12) : CorApp.verdeFundo,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: desabilitado
              ? null
              : () async {
                  final uri = Uri.parse(link);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.phone_outlined,
              size: 18,
              color: desabilitado ? CorApp.textoSuave.withValues(alpha: 0.6) : CorApp.verde,
            ),
          ),
        ),
      ),
    );
  }
}
