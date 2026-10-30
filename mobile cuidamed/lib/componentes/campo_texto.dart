import 'package:flutter/material.dart';

import '../utilitarios/mascaras.dart';
import '../utilitarios/tema.dart';

class CampoTexto extends StatefulWidget {
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

  /// Ícone dentro do campo, à esquerda (ex.: envelope no e-mail).
  final IconData? icone;

  /// Em campos de senha: "olho" para mostrar/esconder o que foi digitado.
  final bool alternarSenha;

  /// Fundo branco com borda fina (campos das telas de login/cadastro), em vez
  /// do azul-claro padrão do tema.
  final bool fundoBranco;

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
    this.icone,
    this.alternarSenha = false,
    this.fundoBranco = false,
  });

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  bool _senhaVisivel = false;

  static const _bordaClara = Color(0xFFCFDCEC);

  @override
  Widget build(BuildContext context) {
    final comOlho = widget.senha && widget.alternarSenha;
    final bordaPadrao = OutlineInputBorder(
      borderRadius: BorderRadius.circular(RaioApp.pequeno),
      borderSide: const BorderSide(color: _bordaClara, width: 1.5),
    );

    final campo = TextFormField(
      controller: widget.controller,
      obscureText: widget.senha && !_senhaVisivel,
      keyboardType: widget.tipoTeclado,
      // Teclado de telefone = campo de telefone: máscara "(79) 99999-9999".
      inputFormatters: widget.tipoTeclado == TextInputType.phone ? const [MascaraTelefone()] : null,
      validator: widget.validador,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        labelText: widget.rotuloExterno ? null : widget.rotulo,
        hintText: widget.placeholder,
        prefixIcon: widget.icone == null ? null : Icon(widget.icone, size: 20),
        prefixIconColor: WidgetStateColor.resolveWith(
            (estados) => estados.contains(WidgetState.focused) ? CorApp.azul : CorApp.textoSuave),
        suffixIcon: comOlho
            ? IconButton(
                onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                tooltip: _senhaVisivel ? 'Esconder senha' : 'Mostrar senha',
                icon: Icon(_senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22),
                color: CorApp.textoSuave,
              )
            : widget.sufixo,
        fillColor: widget.fundoBranco ? Colors.white : null,
        enabledBorder: widget.fundoBranco ? bordaPadrao : null,
        border: widget.fundoBranco ? bordaPadrao : null,
      ),
    );
    if (!widget.rotuloExterno) return campo;
    return Semantics(
      label: widget.rotulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.rotulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF33506F))),
          const SizedBox(height: 8),
          campo,
        ],
      ),
    );
  }
}
