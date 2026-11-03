import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/modelos/historico.dart';
import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/utilitarios/horarios.dart';

Medicamento _med(int id, String nome, List<String> horarios, {required DateTime inicio, DateTime? fim}) => Medicamento(
      id: id,
      pacienteId: 1,
      nome: nome,
      dosagem: '',
      forma: 'COMPRIMIDO',
      frequencia: 'TRES_VEZES_AO_DIA',
      dataInicio: inicio,
      dataFim: fim,
      horarios: horarios,
      quantidadeEstoque: 30,
      quantidadePorDose: 1,
    );

Historico _registro(int medId, String nome, DateTime dia, String hora, String status) => Historico(
      id: 1,
      pacienteId: 1,
      medicamentoId: medId,
      data: dia,
      hora: hora,
      nomeMedicamento: nome,
      dosagem: '',
      status: status,
    );

/// Mesmo caso da Margarida: 3 remédios, 7 doses no dia, só 2 registradas.
void main() {
  final hoje = DateTime(2026, 10, 30);
  final agora = DateTime(2026, 10, 30, 7, 20);
  final medicamentos = [
    _med(105, 'Teste 1', ['01:00'], inicio: hoje),
    _med(106, 'Teste 2', ['01:00', '02:00', '03:00'], inicio: hoje, fim: DateTime(2026, 11, 6)),
    _med(107, 'Teste 3', ['01:30', '02:30', '03:30', '09:00'], inicio: hoje, fim: DateTime(2026, 11, 2)),
  ];
  final historico = [
    _registro(105, 'Teste 1', hoje, '01:00', 'TOMADO'),
    _registro(106, 'Teste 2', hoje, '01:00', 'PERDIDO'),
  ];

  test('Doses que passaram do horário sem registro entram no histórico', () {
    final semRegistro = dosesSemRegistro(1, medicamentos, historico, hoje, hoje, agora: agora);
    // 02:00 e 03:00 do Teste 2; 01:30, 02:30 e 03:30 do Teste 3. O 09:00 ainda não chegou.
    expect(semRegistro.map((h) => '${h.nomeMedicamento} ${h.hora}'), [
      'Teste 2 02:00',
      'Teste 2 03:00',
      'Teste 3 01:30',
      'Teste 3 02:30',
      'Teste 3 03:30',
    ]);
    expect(semRegistro.every((h) => h.status == 'PERDIDO'), isTrue); // mais de 3 h de atraso
  });

  test('Hoje, dose com menos de 3 h de atraso aparece como atrasada', () {
    final semRegistro = dosesSemRegistro(1, medicamentos, historico, hoje, hoje, agora: DateTime(2026, 10, 30, 10, 0));
    expect(semRegistro.where((h) => h.hora == '09:00').single.status, 'ATRASADO');
  });

  test('Dias anteriores sem registro: perdida; antes do início do tratamento: nada', () {
    final ontem = hoje.subtract(const Duration(days: 1));
    final semRegistro = dosesSemRegistro(1, medicamentos, const [], ontem, ontem, agora: agora);
    expect(semRegistro, isEmpty); // os três começaram hoje
    final depois = dosesSemRegistro(1, medicamentos, const [], hoje, DateTime(2026, 10, 31),
        agora: DateTime(2026, 10, 31, 0, 30));
    expect(depois.where((h) => h.data == hoje).every((h) => h.status == 'PERDIDO'), isTrue);
  });
}
