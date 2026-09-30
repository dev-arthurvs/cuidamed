/// Espelha PacienteRespostaDTO (back-end cuidamed/.../paciente/PacienteRespostaDTO.java).
class Paciente {
  final int id;
  final String nome;
  final String email;
  final DateTime? dataNascimento;
  final String? sexo; // FEMININO | MASCULINO | OUTRO
  final String? enfermidade;
  final String? telefone;
  final String? endereco;
  final String? observacoesClinicas;
  final int? cuidadorId;
  final int? cuidadorSolicitadoId;
  final bool alertaManualPendente;
  final String? alertaManualMensagem;
  final bool permiteAlteracoes;
  /// Só enquanto o paciente cadastrado pelo cuidador não ativou o acesso.
  final String? codigoAtivacao;

  Paciente({
    required this.id,
    required this.nome,
    required this.email,
    this.dataNascimento,
    this.sexo,
    this.enfermidade,
    this.telefone,
    this.endereco,
    this.observacoesClinicas,
    this.cuidadorId,
    this.cuidadorSolicitadoId,
    this.alertaManualPendente = false,
    this.alertaManualMensagem,
    this.permiteAlteracoes = false,
    this.codigoAtivacao,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String,
      dataNascimento: json['dataNascimento'] != null ? DateTime.parse(json['dataNascimento']) : null,
      sexo: json['sexo'] as String?,
      enfermidade: json['enfermidade'] as String?,
      telefone: json['telefone'] as String?,
      endereco: json['endereco'] as String?,
      observacoesClinicas: json['observacoesClinicas'] as String?,
      cuidadorId: json['cuidadorId'] as int?,
      cuidadorSolicitadoId: json['cuidadorSolicitadoId'] as int?,
      alertaManualPendente: json['alertaManualPendente'] as bool? ?? false,
      alertaManualMensagem: json['alertaManualMensagem'] as String?,
      permiteAlteracoes: json['permiteAlteracoes'] as bool? ?? false,
      codigoAtivacao: json['codigoAtivacao'] as String?,
    );
  }

  int calcularIdade() {
    if (dataNascimento == null) return 0;
    final hoje = DateTime.now();
    var idade = hoje.year - dataNascimento!.year;
    final aindaNaoFezAniversario = hoje.month < dataNascimento!.month ||
        (hoje.month == dataNascimento!.month && hoje.day < dataNascimento!.day);
    if (aindaNaoFezAniversario) idade -= 1;
    return idade;
  }

  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+'));
    final primeira = partes.isNotEmpty ? partes.first[0] : '';
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }
}
