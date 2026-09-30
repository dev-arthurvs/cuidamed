/// Espelha CuidadorRespostaDTO (back-end cuidamed/.../cuidador/CuidadorRespostaDTO.java).
class Cuidador {
  final int id;
  final String nome;
  final String email;
  final String? profissao;
  final String? telefone;

  Cuidador({
    required this.id,
    required this.nome,
    required this.email,
    this.profissao,
    this.telefone,
  });

  factory Cuidador.fromJson(Map<String, dynamic> json) {
    return Cuidador(
      id: json['id'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String,
      profissao: json['profissao'] as String?,
      telefone: json['telefone'] as String?,
    );
  }
}
