import '../modelos/paciente.dart';
import 'api_cliente.dart';

class PacienteServico {
  final ApiCliente _api = ApiCliente.instancia;

  Future<Paciente> buscarPorId(int id) async {
    final resposta = await _api.get('/api/pacientes/$id');
    return Paciente.fromJson(resposta);
  }

  Future<List<Paciente>> listarPorCuidador(int cuidadorId) async {
    final resposta = await _api.get('/api/cuidadores/$cuidadorId/pacientes') as List;
    return resposta.map((p) => Paciente.fromJson(p)).toList();
  }

  Future<List<Paciente>> listarSolicitacoes(int cuidadorId) async {
    final resposta = await _api.get('/api/cuidadores/$cuidadorId/solicitacoes') as List;
    return resposta.map((p) => Paciente.fromJson(p)).toList();
  }

  Future<Paciente> criar({
    required String nome,
    required String email,
    String? senha, // null quando o cuidador cadastra: o paciente cria a senha em "Ativar meu acesso"
    DateTime? dataNascimento,
    String? sexo,
    String? enfermidade,
    String? telefone,
    String? endereco,
    String? observacoesClinicas,
    int? cuidadorId,
  }) async {
    final resposta = await _api.post('/api/pacientes', {
      'nome': nome,
      'email': email,
      'senha': senha,
      'dataNascimento': dataNascimento != null ? _formatarData(dataNascimento) : null,
      'sexo': sexo,
      'enfermidade': enfermidade,
      'telefone': telefone,
      'endereco': endereco,
      'observacoesClinicas': observacoesClinicas,
      'cuidadorId': cuidadorId,
    });
    return Paciente.fromJson(resposta);
  }

  Future<Paciente> atualizar(int id, Map<String, dynamic> dados) async {
    final resposta = await _api.put('/api/pacientes/$id', dados);
    return Paciente.fromJson(resposta);
  }

  Future<void> alterarSenha(int id, String senhaAtual, String novaSenha) =>
      _api.put('/api/pacientes/$id/senha', {'senhaAtual': senhaAtual, 'novaSenha': novaSenha});

  Future<void> solicitarVinculo(int id, String cuidadorEmail) =>
      _api.post('/api/pacientes/$id/solicitar-vinculo', {'cuidadorEmail': cuidadorEmail});

  Future<void> aceitarVinculo(int id, int cuidadorId) =>
      _api.post('/api/pacientes/$id/aceitar-vinculo', {'cuidadorId': cuidadorId});

  Future<void> recusarVinculo(int id, int cuidadorId) =>
      _api.post('/api/pacientes/$id/recusar-vinculo', {'cuidadorId': cuidadorId});

  Future<void> desvincularCuidador(int id, int cuidadorId) =>
      _api.post('/api/pacientes/$id/desvincular-cuidador', {'cuidadorId': cuidadorId});

  Future<void> atualizarPermissaoAlteracoes(int id, int cuidadorId, bool permite) => _api.put(
      '/api/pacientes/$id/permissao-alteracoes', {'cuidadorId': cuidadorId, 'permiteAlteracoes': permite});

  Future<void> enviarAlertaManual(int id, int cuidadorId, String? mensagem) =>
      _api.post('/api/pacientes/$id/alerta-manual', {'cuidadorId': cuidadorId, 'mensagem': mensagem});

  Future<void> confirmarAlertaManual(int id) => _api.post('/api/pacientes/$id/alerta-manual/confirmar');

  Future<void> excluir(int id) => _api.delete('/api/pacientes/$id');

  static String _formatarData(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
}
