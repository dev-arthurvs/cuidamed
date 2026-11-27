class Dose {
  final String id;
  final int medicamentoId;
  final String horario;
  final String nome;
  final String dosagem;
  final String forma;
  final int? quantidadePorDose;
  final DateTime? dataFim;
  final String status;

  Dose({
    required this.id,
    required this.medicamentoId,
    required this.horario,
    required this.nome,
    required this.dosagem,
    required this.forma,
    this.quantidadePorDose,
    this.dataFim,
    required this.status,
  });

  Dose copiarComStatus(String novoStatus) => Dose(
        id: id,
        medicamentoId: medicamentoId,
        horario: horario,
        nome: nome,
        dosagem: dosagem,
        forma: forma,
        quantidadePorDose: quantidadePorDose,
        dataFim: dataFim,
        status: novoStatus,
      );
}
