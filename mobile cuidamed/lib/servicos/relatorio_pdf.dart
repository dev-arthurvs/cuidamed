
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../modelos/historico.dart';
import '../modelos/medicamento.dart';
import '../modelos/paciente.dart';

const _rotuloStatus = {'TOMADO': 'Tomada', 'ATRASADO': 'Atrasada', 'PERDIDO': 'Perdida'};

String _data(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Fontes do app, para os acentos saírem certos no PDF.
Future<pw.ThemeData> carregarTemaRelatorio() async {
  final normal = await rootBundle.load('assets/fonts/SourceSans3-Regular.ttf');
  final negrito = await rootBundle.load('assets/fonts/SourceSans3-Bold.ttf');
  return pw.ThemeData.withFont(base: pw.Font.ttf(normal), bold: pw.Font.ttf(negrito));
}

/// Relatório para levar ao médico — mesmo conteúdo de RelatorioDoses.jsx do web.
/// [entradas]: as doses já filtradas pela tela de Histórico de doses.
Future<Uint8List> gerarRelatorioPdf({
  required Paciente paciente,
  required List<Medicamento> medicamentosAtivos,
  required List<Historico> entradas,
  required DateTime inicio,
  required DateTime fim,
  pw.ThemeData? tema,
}) async {
  int contar(String status) => entradas.where((e) => e.status == status).length;
  final tomadas = contar('TOMADO');
  final adesao = entradas.isEmpty ? '—' : '${(tomadas / entradas.length * 100).round()}%';
  final emOrdem = [...entradas]
    ..sort((a, b) {
      final porData = a.data.compareTo(b.data);
      return porData != 0 ? porData : a.hora.compareTo(b.hora);
    });

  pw.Widget titulo(String texto) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(texto, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      );

  final documento = pw.Document(theme: tema);
  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text('CuidaMed — Relatório de doses', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Paciente: ${paciente.nome}'),
        if (paciente.dataNascimento != null) pw.Text('Nascimento: ${_data(paciente.dataNascimento!)}'),
        if ((paciente.enfermidade ?? '').isNotEmpty) pw.Text('Condição: ${paciente.enfermidade}'),
        pw.Text('Período: ${_data(inicio)} a ${_data(fim)}'),
        titulo('Resumo'),
        pw.Text('Adesão no período: $adesao · Tomadas: $tomadas · Atrasadas: ${contar('ATRASADO')} · Perdidas: ${contar('PERDIDO')}'),
        titulo('Medicamentos em uso'),
        if (medicamentosAtivos.isEmpty) pw.Text('Nenhum.'),
        for (final m in medicamentosAtivos)
          pw.Bullet(
            text: '${[m.nome, m.dosagem, rotuloForma[m.forma] ?? m.forma].where((t) => t.isNotEmpty).join(' · ')} — ${m.horarios.join(', ')}',
          ),
        titulo('Doses'),
        if (emOrdem.isEmpty)
          pw.Text('Nenhuma dose no período.')
        else
          pw.TableHelper.fromTextArray(
            headers: const ['Data', 'Hora', 'Medicamento', 'Situação'],
            data: [
              for (final e in emOrdem) [_data(e.data), e.hora, e.nomeMedicamento, _rotuloStatus[e.status] ?? e.status],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          ),
        pw.SizedBox(height: 10),
        pw.Text('Doses que passaram do horário sem registro contam como atrasadas ou perdidas.', style: const pw.TextStyle(fontSize: 9)),
      ],
    ),
  );
  return documento.save();
}
