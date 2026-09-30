import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/cabecalho.dart';
import '../componentes/voltar_detalhes_paciente.dart';
import '../componentes/escolha_paciente.dart';
import '../estado/app_estado.dart';
import '../modelos/medicamento.dart';
import '../utilitarios/horarios.dart';
import '../utilitarios/tema.dart';
import '../utilitarios/animacoes.dart';

class CiclosEncerrados extends StatelessWidget {
  const CiclosEncerrados({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    if (deveEscolherPaciente(context)) {
      return const EscolhaPaciente(kicker: 'Ciclos encerrados', rotaDestino: '/ciclos-encerrados');
    }
    final dados = estado.pacienteFoco;

    if (dados == null) {
      return const AndaimeApp(
        appBar: Cabecalho(kicker: 'Agenda de medicamentos', titulo: 'Nenhum paciente selecionado'),
        body: Padding(padding: EdgeInsets.all(20), child: Text('Selecione um paciente para ver os ciclos encerrados.')),
      );
    }

    final encerrados = dados.medicamentos.where((m) => medicamentoEncerrado(m, historico: dados.historico)).toList();
    final titulo = estado.usuario!.tipo == 'cuidador' ? 'Ciclos encerrados de ${dados.paciente.nome}' : 'Ciclos encerrados';

    return AndaimeApp(
      appBar: Cabecalho(kicker: 'Agenda de medicamentos', titulo: titulo),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          VoltarDetalhesPaciente(pacienteId: dados.paciente.id),
          if (encerrados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Nenhum ciclo encerrado até o momento.', style: TextStyle(color: CorApp.textoSuave)),
            ),
          // Grade fixa: 3 por linha em tela larga, 2 em média, 1 no celular. Cada
          // card tem a largura de uma "vaga", então um card sozinho não estica.
          LayoutBuilder(
            builder: (context, restricoes) {
              final colunas = restricoes.maxWidth >= 1000 ? 3 : (restricoes.maxWidth >= 640 ? 2 : 1);
              const espaco = 14.0;
              final largura = (restricoes.maxWidth - espaco * (colunas - 1)) / colunas;
              return Wrap(
                spacing: espaco,
                runSpacing: espaco,
                children: [
                  for (final (indice, medicamento) in encerrados.indexed)
                    SizedBox(
                      width: largura,
                      child: EntradaSuave(key: ValueKey(medicamento.id), indice: indice, child: _cartao(medicamento)),
                    ),
                ],
              );
            },
          ),
        ],
      ),
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
                child: const Icon(Icons.inventory_2_outlined, color: CorApp.textoSuave, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medicamento.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    Text(
                      '${medicamento.dosagem} · ${rotuloForma[medicamento.forma] ?? medicamento.forma}',
                      style: const TextStyle(color: CorApp.textoSuave),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Ciclo de ${_formatarData(medicamento.dataInicio)} até ${medicamento.dataFim != null ? _formatarData(medicamento.dataFim!) : '—'}',
            style: const TextStyle(color: CorApp.textoSuave, fontWeight: FontWeight.w600),
          ),
          if (medicamento.observacoes != null && medicamento.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              medicamento.observacoes!,
              style: const TextStyle(color: CorApp.textoSuave, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  String _formatarData(DateTime data) => '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}
