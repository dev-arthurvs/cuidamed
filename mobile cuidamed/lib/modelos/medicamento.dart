/// Espelha MedicamentoRespostaDTO (back-end cuidamed/.../medicamento/MedicamentoRespostaDTO.java).
class Medicamento {
  final int id;
  final int pacienteId;
  final String nome;
  final String dosagem;
  final String forma; // COMPRIMIDO | CAPSULA | GOTA | XAROPE | INJECAO | POMADA
  final String frequencia;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String? observacoes;
  final int? quantidadeEstoque;
  final int? quantidadePorDose;
  final List<String> horarios; // "HH:mm"

  Medicamento({
    required this.id,
    required this.pacienteId,
    required this.nome,
    required this.dosagem,
    required this.forma,
    required this.frequencia,
    required this.dataInicio,
    this.dataFim,
    this.observacoes,
    this.quantidadeEstoque,
    this.quantidadePorDose,
    required this.horarios,
  });

  factory Medicamento.fromJson(Map<String, dynamic> json) {
    return Medicamento(
      id: json['id'] as int,
      pacienteId: json['pacienteId'] as int,
      nome: json['nome'] as String,
      dosagem: json['dosagem'] as String,
      forma: json['forma'] as String,
      frequencia: json['frequencia'] as String,
      dataInicio: DateTime.parse(json['dataInicio']),
      dataFim: json['dataFim'] != null ? DateTime.parse(json['dataFim']) : null,
      observacoes: json['observacoes'] as String?,
      quantidadeEstoque: json['quantidadeEstoque'] as int?,
      quantidadePorDose: json['quantidadePorDose'] as int?,
      horarios: (json['horarios'] as List).map((h) => h as String).toList(),
    );
  }

  Map<String, dynamic> toJsonCriacao() => {
        'pacienteId': pacienteId,
        'nome': nome,
        'dosagem': dosagem,
        'forma': forma,
        'frequencia': frequencia,
        'dataInicio': _formatarData(dataInicio),
        'dataFim': dataFim != null ? _formatarData(dataFim!) : null,
        'observacoes': observacoes,
        'quantidadeEstoque': quantidadeEstoque,
        'quantidadePorDose': quantidadePorDose,
        'horarios': horarios,
      };

  static String _formatarData(DateTime data) =>
      '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
}

const List<String> formasMedicamento = ['COMPRIMIDO', 'CAPSULA', 'GOTA', 'XAROPE', 'INJECAO', 'POMADA'];

const Map<String, String> rotuloForma = {
  'COMPRIMIDO': 'Comprimido',
  'CAPSULA': 'Cápsula',
  'GOTA': 'Gota',
  'XAROPE': 'Xarope',
  'INJECAO': 'Injeção',
  'POMADA': 'Pomada',
};

const Map<String, String> unidadeEstoquePorForma = {
  'COMPRIMIDO': 'comp',
  'CAPSULA': 'cáp',
  'GOTA': 'gotas',
  'XAROPE': 'ml',
  'INJECAO': 'amp',
};

const List<String> frequenciasMedicamento = [
  'UMA_VEZ_AO_DIA',
  'DUAS_VEZES_AO_DIA',
  'TRES_VEZES_AO_DIA',
  'A_CADA_8_HORAS',
  'DIAS_ALTERNADOS',
  'SEMANAL',
];

const Map<String, String> rotuloFrequencia = {
  'UMA_VEZ_AO_DIA': '1x ao dia',
  'DUAS_VEZES_AO_DIA': '2x ao dia',
  'TRES_VEZES_AO_DIA': '3x ao dia',
  'A_CADA_8_HORAS': 'A cada 8 horas',
  'DIAS_ALTERNADOS': 'Dias alternados',
  'SEMANAL': 'Semanal',
};
