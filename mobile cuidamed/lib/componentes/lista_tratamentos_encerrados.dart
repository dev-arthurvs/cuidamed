import 'package:flutter/material.dart';

import '../modelos/medicamento.dart';
import '../utilitarios/animacoes.dart';
import '../utilitarios/tema.dart';

/// Aba "Encerrados" da Agenda — equivalente a ListaTratamentosEncerrados.jsx
/// do web: remédios cujo tratamento já terminou, só para consulta (sem editar
/// nem excluir), com o período em que foram usados.
class ListaTratamentosEncerrados extends StatelessWidget {
  final List<Medicamento> medicamentos;
  const ListaTratamentosEncerrados({super.key, required this.medicamentos});

  @override
  Widget build(BuildContext context) {
    if (medicamentos.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Nenhum tratamento encerrado até o momento.', style: TextStyle(color: CorApp.textoSuave)),
      );
    }
    // Grade fixa: 3 por linha em tela larga, 2 em média, 1 no celular. Cada
    // card tem a largura de uma "vaga", então um card sozinho não estica.
    return LayoutBuilder(
      builder: (context, restricoes) {
        final colunas = restricoes.maxWidth >= 1000 ? 3 : (restricoes.maxWidth >= 640 ? 2 : 1);
        const espaco = 14.0;
        final largura = (restricoes.maxWidth - espaco * (colunas - 1)) / colunas;
        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            for (final (indice, medicamento) in medicamentos.indexed)
              SizedBox(
                width: largura,
                child: EntradaSuave(key: ValueKey(medicamento.id), indice: indice, child: _cartao(medicamento)),
              ),
          ],
        );
      },
    );
  }

  Widget _cartao(Medicamento medicamento) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CorApp.fundoCard,
        borderRadius: BorderRadius.circular(RaioApp.medio),
        border: Border.all(color: CorApp.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CorApp.textoSuave.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(RaioApp.pequeno),
                ),
                child: Icon(Icons.inventory_2_outlined, color: CorApp.textoSuave, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medicamento.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    Text(
                      [medicamento.dosagem, rotuloForma[medicamento.forma] ?? medicamento.forma].where((t) => t.isNotEmpty).join(' · '),
                      style: TextStyle(color: CorApp.textoSuave),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tratamento de ${_formatarData(medicamento.dataInicio)} até '
            '${medicamento.dataFim != null ? _formatarData(medicamento.dataFim!) : '—'}',
            style: TextStyle(color: CorApp.textoSuave, fontWeight: FontWeight.w600),
          ),
          if (medicamento.observacoes != null && medicamento.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              medicamento.observacoes!,
              style: TextStyle(color: CorApp.textoSuave, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}
