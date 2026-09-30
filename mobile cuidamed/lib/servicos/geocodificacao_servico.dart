import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Chama a Nominatim (OpenStreetMap) diretamente do cliente, sem passar pelo
/// back-end — mesmo padrão do front-end web (front-end cuidamed/src/paginas/Farmacias.jsx).
class SugestaoEndereco {
  final String displayName;
  final double lat;
  final double lon;
  SugestaoEndereco({required this.displayName, required this.lat, required this.lon});

  factory SugestaoEndereco.fromJson(Map<String, dynamic> json) => SugestaoEndereco(
        displayName: json['display_name'] as String,
        lat: double.parse(json['lat'] as String),
        lon: double.parse(json['lon'] as String),
      );
}

/// Resposta da ViaCEP já montada no formato "logradouro, número, bairro, cidade - UF".
class EnderecoCep {
  final String enderecoCompleto;
  final String? enderecoSemNumero; // fallback de geocodificação quando o número não é achado
  EnderecoCep({required this.enderecoCompleto, this.enderecoSemNumero});
}

class GeocodificacaoServico {
  static const _urlNominatim = 'https://nominatim.openstreetmap.org/search';
  static const _urlViaCep = 'https://viacep.com.br/ws';

  // A política de uso da Nominatim pede um User-Agent identificando o app;
  // no navegador (web) o cabeçalho é proibido e o próprio browser manda o dele.
  final Dio _dio = Dio(BaseOptions(
    headers: kIsWeb ? null : {'User-Agent': 'CuidaMed/1.0 (app mobile)'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// null quando o CEP não existe (ViaCEP responde {"erro": true}).
  Future<EnderecoCep?> buscarCep(String cepSomenteDigitos, {String numero = ''}) async {
    final resposta = await _dio.get('$_urlViaCep/$cepSomenteDigitos/json/');
    final dados = resposta.data;
    if (dados is! Map || dados['erro'] != null) return null;
    String? campo(String chave) {
      final valor = (dados[chave] as String?)?.trim();
      return (valor == null || valor.isEmpty) ? null : valor;
    }

    final cidadeUf = [campo('localidade'), campo('uf')].whereType<String>().join(' - ');
    String montar(String? numeroOuNulo) => [
          [campo('logradouro'), numeroOuNulo].whereType<String>().where((p) => p.isNotEmpty).join(', '),
          campo('bairro'),
          cidadeUf,
        ].whereType<String>().where((p) => p.isNotEmpty).join(', ');

    final numeroLimpo = numero.trim();
    return EnderecoCep(
      enderecoCompleto: montar(numeroLimpo),
      enderecoSemNumero: numeroLimpo.isEmpty ? null : montar(null),
    );
  }

  Future<List<SugestaoEndereco>> sugerir(String texto) async {
    final resposta = await _dio.get(_urlNominatim, queryParameters: {
      'q': texto,
      'format': 'json',
      'limit': 5,
      'countrycodes': 'br',
    });
    return (resposta.data as List).map((s) => SugestaoEndereco.fromJson(s)).toList();
  }

  Future<SugestaoEndereco?> geocodificar(String texto) async {
    final resposta = await _dio.get(_urlNominatim, queryParameters: {
      'q': texto,
      'format': 'json',
      'limit': 1,
      'countrycodes': 'br',
    });
    final lista = resposta.data as List;
    if (lista.isEmpty) return null;
    return SugestaoEndereco.fromJson(lista.first);
  }
}
