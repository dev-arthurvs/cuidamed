import 'api_cliente.dart';

class ResultadoLogin {
  final String tipo; // PACIENTE | CUIDADOR
  final int id;
  final String token; // JWT: vai no cabeçalho Authorization das próximas chamadas
  ResultadoLogin({required this.tipo, required this.id, required this.token});
}

class AuthServico {
  final ApiCliente _api = ApiCliente.instancia;

  Future<ResultadoLogin> login(String email, String senha) async {
    final resposta = await _api.post('/api/auth/login', {'email': email, 'senha': senha});
    return ResultadoLogin(
      tipo: resposta['tipo'] as String,
      id: resposta['id'] as int,
      token: resposta['token'] as String,
    );
  }
}
