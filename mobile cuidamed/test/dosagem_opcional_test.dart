import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/paginas/formulario_medicamento.dart';
import 'package:cuidamed_mobile/utilitarios/whatsapp.dart';

import 'apoio.dart';

/// A dosagem saiu do formulário de medicamento e virou opcional na API.
void main() {
  testWidgets('Formulário de medicamento não pede dosagem', (tester) async {
    await montarPagina(tester, estadoPaciente(), '/agenda/novo', (_) => const FormularioMedicamento());
    expect(find.text('Nome do medicamento'), findsOneWidget);
    expect(find.text('Dosagem'), findsNothing);
  });

  test('Remédio sem dosagem vindo da API vira texto vazio (sem "null")', () {
    final medicamento = Medicamento.fromJson({
      'id': 1,
      'pacienteId': 1,
      'nome': 'Losartana',
      'dosagem': null,
      'forma': 'COMPRIMIDO',
      'frequencia': 'UMA_VEZ_AO_DIA',
      'dataInicio': '2026-10-01',
      'horarios': ['08:00'],
    });
    expect(medicamento.dosagem, '');
  });

  test('Lembrete do WhatsApp sem quantidade nem dosagem não mostra a linha "Quantidade"', () {
    final mensagem = montarMensagemLembrete(
      nomePaciente: 'Maria',
      medicamento: 'Pomada X',
      horario: '08:00',
      forma: 'POMADA',
      dosagem: '',
    );
    expect(mensagem, isNot(contains('Quantidade')));
    expect(mensagem, contains('Medicamento: Pomada X'));
  });
}
