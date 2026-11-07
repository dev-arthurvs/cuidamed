import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/modelos/historico.dart';
import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/paginas/painel_idoso.dart';

import 'apoio.dart';

Medicamento _med(int id, String nome, String horario, {DateTime? fim}) {
  final hoje = DateTime.now();
  return Medicamento(
    id: id,
    pacienteId: 1,
    nome: nome,
    dosagem: '',
    forma: 'COMPRIMIDO',
    frequencia: 'UMA_VEZ_AO_DIA',
    dataInicio: DateTime(hoje.year, hoje.month, hoje.day - 5),
    dataFim: fim,
    horarios: [horario],
    quantidadeEstoque: 30,
    quantidadePorDose: 1,
  );
}

void main() {
  testWidgets('Último dia do tratamento: a dose tomada continua no Início, mas o remédio sai de "Em uso"',
      (tester) async {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final estado = estadoPaciente();
    final dados = estado.pacientes.first;
    final antibiotico = _med(71, 'Antibiotico', '00:00', fim: hoje);
    dados.medicamentos
      ..clear()
      ..addAll([antibiotico, _med(72, 'Vitamina', '23:59')]);
    dados.historico
      ..clear()
      ..add(Historico(
        id: 700, pacienteId: 1, medicamentoId: 71, data: hoje, hora: '00:00',
        nomeMedicamento: 'Antibiotico', dosagem: '', status: 'TOMADO',
      ));

    // Na Agenda, a regra de "Em uso" e "Encerrados" continua a mesma.
    expect(dados.medicamentosAtivos().map((m) => m.nome), ['Vitamina']);

    await montarPagina(tester, estado, '/painel', (_) => const PainelIdoso());
    // A dose tomada aparece como anterior no carrossel e dá para voltar até ela.
    final anterior = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Antibiotico'));
    expect(anterior, findsWidgets);
    await tester.tap(find.byTooltip('Dose anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Antibiotico'), findsOneWidget);
    expect(find.text('Tomada'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);
  });
}
