import '../modelos/farmacia.dart';
import 'api_cliente.dart';

class FarmaciaServico {
  final ApiCliente _api = ApiCliente.instancia;

  Future<RespostaFarmacias> buscarPorCoordenadas(double lat, double lon, int raioMetros) async {
    final resposta = await _api.get('/api/farmacias', query: {'lat': lat, 'lon': lon, 'raio': raioMetros});
    return RespostaFarmacias.fromJson(resposta);
  }

  Future<RespostaFarmacias> buscarPorEndereco(String endereco, int raioMetros) async {
    final resposta = await _api.get('/api/farmacias', query: {'endereco': endereco, 'raio': raioMetros});
    return RespostaFarmacias.fromJson(resposta);
  }
}
