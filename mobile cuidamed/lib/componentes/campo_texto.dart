import 'package:flutter/material.dart';

class CampoTexto extends StatelessWidget {
  final String rotulo;
  final TextEditingController controller;
  final bool senha;
  final TextInputType? tipoTeclado;
  final String? placeholder;
  final Widget? sufixo;
  final String? Function(String?)? validador;
  final void Function(String)? onChanged;
  /// Rótulo em negrito acima do campo (padrão do web), em vez de flutuante dentro dele.
  final bool rotuloExterno;
  final void Function(String)? onSubmitted;

  const CampoTexto({
    super.key,
    required this.rotulo,
    required this.controller,
    this.senha = false,
    this.tipoTeclado,
    this.placeholder,
    this.sufixo,
    this.validador,
    this.onChanged,
    this.rotuloExterno = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final campo = TextFormField(
      controller: controller,
      obscureText: senha,
      keyboardType: tipoTeclado,
      validator: validador,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        labelText: rotuloExterno ? null : rotulo,
        hintText: placeholder,
        suffixIcon: sufixo,
      ),
    );
    if (!rotuloExterno) return campo;
    return Semantics(
      label: rotulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rotulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF33506F))),
          const SizedBox(height: 8),
          campo,
        ],
      ),
    );
  }
}
