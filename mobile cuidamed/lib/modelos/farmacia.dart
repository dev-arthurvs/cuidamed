/// Espelha FarmaciaDTO e PontoOrigemDTO
/// (back-end cuidamed/.../farmacias/{FarmaciaDTO,PontoOrigemDTO}.java).
class PontoOrigem {
  final double latitude;
  final double longitude;
  final String enderecoFormatado;

  PontoOrigem({required this.latitude, required this.longitude, required this.enderecoFormatado});

  factory PontoOrigem.fromJson(Map<String, dynamic> json) => PontoOrigem(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        enderecoFormatado: json['enderecoFormatado'] as String? ?? '',
      );
}

class Farmacia {
  final String nome;
  final String endereco;
  final double latitude;
  final double longitude;
  final double distanciaMetros;

  Farmacia({
    required this.nome,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.distanciaMetros,
  });

  factory Farmacia.fromJson(Map<String, dynamic> json) => Farmacia(
        nome: json['nome'] as String,
        endereco: json['endereco'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        distanciaMetros: (json['distanciaMetros'] as num).toDouble(),
      );
}

class RespostaFarmacias {
  final PontoOrigem origem;
  final List<Farmacia> farmacias;

  RespostaFarmacias({required this.origem, required this.farmacias});

  factory RespostaFarmacias.fromJson(Map<String, dynamic> json) => RespostaFarmacias(
        origem: PontoOrigem.fromJson(json['origem']),
        farmacias: (json['farmacias'] as List).map((f) => Farmacia.fromJson(f)).toList(),
      );
}
