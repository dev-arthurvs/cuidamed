import 'package:flutter/material.dart';

import '../utilitarios/animacoes.dart';
import '../utilitarios/tema.dart';
import 'botao.dart';

/// Janela "Tem certeza?" — equivalente ao ModalConfirmacao.jsx do web: título,
/// mensagem, "Cancelar" com contorno e o botão de confirmar vermelho cheio.
/// Devolve true só quando o usuário confirma.
Future<bool> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Confirmar',
}) async {
  final confirmado = await mostrarDialogoAnimado<bool>(
    context: context,
    barrierColor: const Color(0x800C2342),
    builder: (contexto) => Dialog(
      backgroundColor: CorApp.fundoCard,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaioApp.grande)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: CorApp.texto)),
              const SizedBox(height: 10),
              Text(mensagem, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CorApp.textoSuave, height: 1.45)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Botao(
                      texto: 'Cancelar',
                      variante: VarianteBotao.contorno,
                      compacto: true,
                      onPressed: () => Navigator.of(contexto).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Botao(
                      texto: textoConfirmar,
                      variante: VarianteBotao.perigoCheio,
                      compacto: true,
                      onPressed: () => Navigator.of(contexto).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return confirmado == true;
}
