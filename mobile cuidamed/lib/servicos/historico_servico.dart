import '../modelos/historico.dart';
import 'api_cliente.dart';

class HistoricoServico {
  final ApiCliente _api = ApiCliente.instancia;

  Future<List<Historico>> listarPorPaciente(int pacienteId, {DateTime? data, int? medicamentoId}) async {
    final query = <String, dynamic>{};
    if (data != null) {
      query['data'] =
          '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    }
    if (medicamentoId != null) query['medicamentoId'] = medicamentoId;

    final resposta = await _api.get('/api/pacientes/$pacienteId/historicos', query: query) as List;
    return resposta.map((h) => Historico.fromJson(h)).toList();
  }

  Future<Historico> criar({
    required int pacienteId,
    required int medicamentoId,
    required DateTime data,
    required String hora,
    required String status,
  }) async {
    final resposta = await _api.post('/api/historicos', {
      'pacienteId': pacienteId,
      'medicamentoId': medicamentoId,
      'data':
          '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}',
      'hora': hora,
      'status': status,
    });
    return Historico.fromJson(resposta);
  }
}
