import 'horarios.dart';
import '../modelos/medicamento.dart';

String formatarTelefoneWhatsApp(String? telefone) {
  final digitos = (telefone ?? '').replaceAll(RegExp(r'\D'), '');
  if (digitos.isEmpty) return '';
  if (digitos.startsWith('55') && digitos.length >= 12) return digitos;
  return '55$digitos';
}

String formatarQuantidadePorDose({required String forma, int? quantidadePorDose, required String dosagem}) {
  if (quantidadePorDose == null) return dosagem;
  final unidade = unidadeEstoquePorForma[forma] ?? 'unidades';
  return '$quantidadePorDose $unidade';
}

String montarMensagemLembrete({
  required String nomePaciente,
  required String medicamento,
  required String horario,
  required String forma,
  int? quantidadePorDose,
  required String dosagem,
  DateTime? dataFim,
}) {
  final primeiroNome = nomePaciente.trim().isEmpty ? nomePaciente : nomePaciente.trim().split(' ').first;
  final quantidadeTexto = formatarQuantidadePorDose(forma: forma, quantidadePorDose: quantidadePorDose, dosagem: dosagem);
  final diasRestantes = calcularDiasRestantesCiclo(dataFim);

  final linhas = <String>[
    'CUIDAMED💊💙',
    'Olá $primeiroNome! Está na hora do seu remédio das $horario.',
    'Medicamento: $medicamento',
    if (quantidadeTexto.isNotEmpty) 'Quantidade: $quantidadeTexto',
  ];
  if (diasRestantes != null) {
    linhas.add(diasRestantes <= 0
        ? 'Hoje é o último dia do ciclo deste medicamento.'
        : diasRestantes == 1
            ? 'Falta 1 dia para acabar o ciclo deste medicamento.'
            : 'Faltam $diasRestantes dias para acabar o ciclo deste medicamento.');
  }
  linhas.add('');
  linhas.add('Lembre-se, cuidar da saúde é muito importante!');
  return linhas.join('\n');
}

String? montarLinkWhatsApp({
  required String? telefone,
  required String nomePaciente,
  required String medicamento,
  required String horario,
  required String forma,
  int? quantidadePorDose,
  required String dosagem,
  DateTime? dataFim,
}) {
  final numero = formatarTelefoneWhatsApp(telefone);
  if (numero.isEmpty) return null;
  final mensagem = montarMensagemLembrete(
    nomePaciente: nomePaciente,
    medicamento: medicamento,
    horario: horario,
    forma: forma,
    quantidadePorDose: quantidadePorDose,
    dosagem: dosagem,
    dataFim: dataFim,
  );
  final mensagemCodificada = Uri.encodeComponent(mensagem);
  return 'https://api.whatsapp.com/send/?phone=$numero&text=$mensagemCodificada&type=phone_number&app_absent=0';
}
