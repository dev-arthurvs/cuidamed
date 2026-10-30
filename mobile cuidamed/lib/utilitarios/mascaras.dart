import 'package:flutter/services.dart';

String _apenasDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

/// Telefone brasileiro: "(79) 99999-9999" (celular, 11 dígitos) ou
/// "(79) 3333-4444" (fixo, 10 dígitos) — mesma regra do web (mascaras.js).
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

/// Máscara de digitação do telefone: parêntese, espaço e hífen entram
/// sozinhos e o campo para no 11º dígito. Apagar um caractere de formatação
/// (o hífen, por exemplo) apaga o dígito anterior — senão ele voltaria na hora.
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
