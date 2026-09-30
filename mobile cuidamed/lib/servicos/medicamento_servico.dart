import '../modelos/medicamento.dart';
import 'api_cliente.dart';

class MedicamentoServico {
  final ApiCliente _api = ApiCliente.instancia;

  Future<List<Medicamento>> listarPorPaciente(int pacienteId) async {
    final resposta = await _api.get('/api/pacientes/$pacienteId/medicamentos') as List;
    return resposta.map((m) => Medicamento.fromJson(m)).toList();
  }

  Future<Medicamento> criar(Medicamento medicamento) async {
    final resposta = await _api.post('/api/medicamentos', medicamento.toJsonCriacao());
    return Medicamento.fromJson(resposta);
  }

  Future<Medicamento> atualizar(int id, Medicamento medicamento) async {
    final resposta = await _api.put('/api/medicamentos/$id', medicamento.toJsonCriacao());
    return Medicamento.fromJson(resposta);
  }

  Future<void> excluir(int id) => _api.delete('/api/medicamentos/$id');
}
