import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// URL base da API. Sobrescrita em tempo de build/execução com
/// `--dart-define=API_BASE_URL=http://SEU_IP:8080`. O default varia por
/// plataforma porque "localhost" não aponta pra máquina host a partir de um
/// emulador Android (lá, o host é 10.0.2.2); iOS simulator e desktop/web
/// usam localhost normalmente.
String _urlBasePadrao() {
  if (kIsWeb) return 'http://localhost:8080';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

const String _urlBaseDefinida = String.fromEnvironment('API_BASE_URL');

/// Wrapper fino sobre o dio — equivalente ao utilitarios/api.js do front-end
/// web: centraliza base URL, cabeçalhos e tradução de erro HTTP pra uma
/// mensagem amigável (o back-end sempre responde erro como {"message": "..."}).
class ApiCliente {
  ApiCliente._interno()
      : dio = Dio(BaseOptions(
          baseUrl: _urlBaseDefinida.isNotEmpty ? _urlBaseDefinida : _urlBasePadrao(),
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 25),
        ));

  static final ApiCliente instancia = ApiCliente._interno();

  final Dio dio;

  /// Token do login (JWT), enviado como "Authorization: Bearer ..." em toda
  /// chamada, menos no próprio login. Definido pelo AppEstado.
  String? token;

  /// Chamado quando o servidor recusa o token (expirado ou inválido): o
  /// AppEstado sai da conta e a tela volta para o login.
  VoidCallback? aoSessaoExpirar;

  static bool _ehRotaDeLogin(String caminho) => caminho.startsWith('/api/auth/');

  Options? _opcoes(String caminho) {
    final atual = token;
    if (atual == null || _ehRotaDeLogin(caminho)) return null;
    return Options(headers: {'Authorization': 'Bearer $atual'});
  }

  Future<dynamic> get(String caminho, {Map<String, dynamic>? query}) => _executar(
        caminho,
        () => dio.get(caminho, queryParameters: query, options: _opcoes(caminho)),
      );

  Future<dynamic> post(String caminho, [Map<String, dynamic>? dados]) => _executar(
        caminho,
        () => dio.post(caminho, data: dados, options: _opcoes(caminho)),
      );

  Future<dynamic> put(String caminho, [Map<String, dynamic>? dados]) => _executar(
        caminho,
        () => dio.put(caminho, data: dados, options: _opcoes(caminho)),
      );

  Future<dynamic> delete(String caminho) => _executar(
        caminho,
        () => dio.delete(caminho, options: _opcoes(caminho)),
      );

  Future<dynamic> _executar(String caminho, Future<Response> Function() chamada) async {
    try {
      final resposta = await chamada();
      if (resposta.statusCode == 204) return null;
      return resposta.data;
    } on DioException catch (erro) {
      if (erro.response?.statusCode == 401 && token != null && !_ehRotaDeLogin(caminho)) {
        aoSessaoExpirar?.call();
      }
      final corpo = erro.response?.data;
      final mensagem = (corpo is Map && corpo['message'] != null)
          ? corpo['message'] as String
          : _mensagemPorTipo(erro.type);
      throw ApiExcecao(mensagem);
    }
  }

  String _mensagemPorTipo(DioExceptionType tipo) {
    switch (tipo) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'O servidor demorou demais para responder. Tente novamente.';
      case DioExceptionType.connectionError:
        return 'Não foi possível conectar ao servidor. Verifique sua conexão.';
      default:
        return 'Não foi possível completar a operação. Tente novamente.';
    }
  }
}

class ApiExcecao implements Exception {
  final String mensagem;
  ApiExcecao(this.mensagem);

  @override
  String toString() => mensagem;
}
