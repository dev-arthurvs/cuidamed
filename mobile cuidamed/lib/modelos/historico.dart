/// Espelha HistoricoRespostaDTO (back-end cuidamed/.../historico/HistoricoRespostaDTO.java).
class Historico {
  final int id;
  final int pacienteId;
  final int medicamentoId;
  final DateTime data;
  final String hora; // "HH:mm"
  final String nomeMedicamento;
  final String dosagem;
  final String status; // TOMADO | ATRASADO | PERDIDO

  Historico({
    required this.id,
    required this.pacienteId,
    required this.medicamentoId,
    required this.data,
    required this.hora,
    required this.nomeMedicamento,
    required this.dosagem,
    required this.status,
  });

  factory Historico.fromJson(Map<String, dynamic> json) {
    return Historico(
      id: json['id'] as int,
      pacienteId: json['pacienteId'] as int,
      medicamentoId: json['medicamentoId'] as int,
      data: DateTime.parse(json['data']),
      hora: json['hora'] as String,
      nomeMedicamento: json['nomeMedicamento'] as String,
      dosagem: json['dosagem'] as String,
      status: json['status'] as String,
    );
  }
}
