/// Modelo calculado no cliente (não vem direto da API) — uma linha de
/// "doses de hoje", juntando um horário de um Medicamento com o status
/// atual (calculado em utilitarios/horarios.dart) ou o registro já
/// confirmado em Historico, quando existir.
class Dose {
  final String id; // "${medicamentoId}-${horario}"
  final int medicamentoId;
  final String horario;
  final String nome;
  final String dosagem;
  final String forma;
  final int? quantidadePorDose;
  final DateTime? dataFim;
  final String status; // pendente | atrasado | perdido | tomado

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
