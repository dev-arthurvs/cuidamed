import 'api_cliente.dart';

class ChatServico {
  final ApiCliente _api = ApiCliente.instancia;

  Future<String> perguntar(int pacienteId, String mensagem) async {
    final resposta = await _api.post('/api/chat/$pacienteId', {'mensagem': mensagem});
    return resposta['resposta'] as String;
  }
}
