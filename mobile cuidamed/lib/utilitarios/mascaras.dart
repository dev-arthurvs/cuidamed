import 'package:flutter/services.dart';

String _apenasDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

bool telefoneCompleto(String texto) {
  final tamanho = _apenasDigitos(texto).length;
  return tamanho == 10 || tamanho == 11;
}

String formatarTelefone(String texto) {
  final digitos = _apenasDigitos(texto);
  final d = digitos.length > 11 ? digitos.substring(0, 11) : digitos;
  if (d.isEmpty) return '';
  if (d.length <= 2) return '($d';
  final ddd = d.substring(0, 2);
  final numero = d.substring(2);
  if (numero.length <= 4) return '($ddd) $numero';
  final tamanhoInicio = d.length == 11 ? 5 : 4;
  return '($ddd) ${numero.substring(0, tamanhoInicio)}-${numero.substring(tamanhoInicio)}';
}

class MascaraEmailOuTelefone extends TextInputFormatter {
  const MascaraEmailOuTelefone();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue novo) {
    if (RegExp(r'[^\d\s()-]').hasMatch(novo.text)) {
      if (!RegExp(r'^\(\d').hasMatch(anterior.text)) return novo;
      final texto = novo.text.replaceAll(RegExp(r'[()\s-]'), '');
      return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
    }
    return const MascaraTelefone().formatEditUpdate(anterior, novo);
  }
}

class MascaraTelefone extends TextInputFormatter {
  const MascaraTelefone();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue anterior, TextEditingValue novo) {
    var digitos = _apenasDigitos(novo.text);
    if (novo.text.length < anterior.text.length && digitos == _apenasDigitos(anterior.text) && digitos.isNotEmpty) {
      digitos = digitos.substring(0, digitos.length - 1);
    }
    final texto = formatarTelefone(digitos);
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
