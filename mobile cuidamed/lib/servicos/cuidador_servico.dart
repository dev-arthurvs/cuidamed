import '../modelos/cuidador.dart';
import 'api_cliente.dart';

class CuidadorServico {
  final ApiCliente _api = ApiCliente.instancia;

  Future<Cuidador> buscarPorId(int id) async {
    final resposta = await _api.get('/api/cuidadores/$id');
    return Cuidador.fromJson(resposta);
  }

  Future<Cuidador> criar({
    required String nome,
    required String email,
    required String senha,
    String? profissao,
    String? telefone,
  }) async {
    final resposta = await _api.post('/api/cuidadores', {
      'nome': nome,
      'email': email,
      'senha': senha,
      'profissao': profissao,
      'telefone': telefone,
    });
    return Cuidador.fromJson(resposta);
  }

  Future<Cuidador> atualizar(int id, Map<String, dynamic> dados) async {
    final resposta = await _api.put('/api/cuidadores/$id', dados);
    return Cuidador.fromJson(resposta);
  }

  Future<void> alterarSenha(int id, String senhaAtual, String novaSenha) =>
      _api.put('/api/cuidadores/$id/senha', {'senhaAtual': senhaAtual, 'novaSenha': novaSenha});
}
