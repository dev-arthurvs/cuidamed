import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/cabecalho.dart';
import '../componentes/rotulo_status.dart';
import '../componentes/voltar_detalhes_paciente.dart';
import '../componentes/escolha_paciente.dart';
import '../estado/app_estado.dart';
import '../modelos/historico.dart';
import '../utilitarios/tema.dart';

class HistoricoPagina extends StatefulWidget {
  final int? pacienteId;
  const HistoricoPagina({super.key, this.pacienteId});

  @override
  State<HistoricoPagina> createState() => _HistoricoPaginaState();
}

const _mesesPtBr = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

class _HistoricoPaginaState extends State<HistoricoPagina> {
  // Período por datas "De" e "Até" (as duas começam em hoje), como no web.
  // Datas futuras não são aceitas e, se uma passar da outra, a outra acompanha.
  late DateTime _inicio;
  late DateTime _fim;
  String _filtroMedicamento = 'todos';

  static DateTime _semHora(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _inicio = _fim = _semHora(DateTime.now());
  }

  Future<void> _escolherData({required bool inicio}) async {
    final hoje = _semHora(DateTime.now());
    final selecionada = await showDatePicker(
      context: context,
      initialDate: inicio ? _inicio : _fim,
      firstDate: DateTime(2000),
      lastDate: hoje,
      helpText: inicio ? 'Mostrar a partir de' : 'Mostrar até',
    );
    if (selecionada == null || !mounted) return;
    setState(() {
      if (inicio) {
        _inicio = selecionada;
        if (_inicio.isAfter(_fim)) _fim = _inicio;
      } else {
        _fim = selecionada;
        if (_fim.isBefore(_inicio)) _inicio = _fim;
      }
    });
  }

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatarDiaMes(DateTime data) => '${data.day} de ${_mesesPtBr[data.month - 1]}';

  String _rotuloDoDia(DateTime data, int diferenca) {
    if (diferenca == 0) return 'Hoje, ${_formatarDiaMes(data)}';
    if (diferenca == 1) return 'Ontem, ${_formatarDiaMes(data)}';
    return _formatarDiaMes(data);
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    if (widget.pacienteId == null && deveEscolherPaciente(context)) {
      return const EscolhaPaciente(kicker: 'Registro de doses', rotaDestino: '/historico');
    }
    PacienteComDados? dados = estado.pacienteFoco;
    if (widget.pacienteId != null) {
      final encontrados = estado.pacientes.where((p) => p.paciente.id == widget.pacienteId);
      dados = encontrados.isEmpty ? null : encontrados.first;
    }

    if (dados == null) {
      return const AndaimeApp(
        appBar: Cabecalho(kicker: 'Registro de doses', titulo: 'Histórico'),
        body: Padding(padding: EdgeInsets.all(20), child: Text('Nenhum paciente selecionado.')),
      );
    }

    final nomesMedicamentos = dados.historico.map((h) => h.nomeMedicamento).toSet().toList()..sort();
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    final entradas = dados.historico
        .map((item) => (item: item, diferenca: hojeSemHora.difference(DateTime(item.data.year, item.data.month, item.data.day)).inDays))
        .where((e) {
          final dia = _semHora(e.item.data);
          return !dia.isBefore(_inicio) && !dia.isAfter(_fim);
        })
        .where((e) => _filtroMedicamento == 'todos' || e.item.nomeMedicamento == _filtroMedicamento)
        .toList()
      ..sort((a, b) {
        final cmpData = b.item.data.compareTo(a.item.data);
        if (cmpData != 0) return cmpData;
        return b.item.hora.compareTo(a.item.hora);
      });

    final tomadas = entradas.where((e) => e.item.status == 'TOMADO').length;
    final atrasadas = entradas.where((e) => e.item.status == 'ATRASADO').length;
    final perdidas = entradas.where((e) => e.item.status == 'PERDIDO').length;

    final titulo = estado.usuario!.tipo == 'cuidador' ? 'Histórico de ${dados.paciente.nome}' : 'Histórico';

    return AndaimeApp(
      appBar: Cabecalho(kicker: 'Registro de doses', titulo: titulo),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          VoltarDetalhesPaciente(pacienteId: dados.paciente.id),
          const Text('Período', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _campoData('De', _inicio, inicio: true)),
              const SizedBox(width: 10),
              Expanded(child: _campoData('Até', _fim, inicio: false)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Medicamento', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _filtroMedicamento,
            items: [
              const DropdownMenuItem(value: 'todos', child: Text('Todos os medicamentos')),
              ...nomesMedicamentos.map((nome) => DropdownMenuItem(value: nome, child: Text(nome))),
            ],
            onChanged: (valor) => setState(() => _filtroMedicamento = valor ?? 'todos'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _cartaoResumo('Tomadas', tomadas, CorApp.verdeFundo, CorApp.verdeTexto)),
              const SizedBox(width: 10),
              Expanded(child: _cartaoResumo('Atrasadas', atrasadas, CorApp.amareloFundo, CorApp.amareloTexto)),
              const SizedBox(width: 10),
              Expanded(child: _cartaoResumo('Perdidas', perdidas, CorApp.vermelhoFundo, CorApp.vermelhoTexto)),
            ],
          ),
          const SizedBox(height: 20),
          if (entradas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Nenhum registro para este filtro.', style: TextStyle(color: CorApp.textoSuave)),
            ),
          for (var indice = 0; indice < entradas.length; indice++) ...[
            if (indice == 0 || entradas[indice - 1].item.data != entradas[indice].item.data)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  _rotuloDoDia(entradas[indice].item.data, entradas[indice].diferenca),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: CorApp.textoSuave, fontSize: 13),
                ),
              ),
            _linhaHistorico(entradas[indice].item),
          ],
        ],
      ),
    );
  }

  Widget _campoData(String rotulo, DateTime valor, {required bool inicio}) {
    return InkWell(
      borderRadius: BorderRadius.circular(RaioApp.pequeno),
      onTap: () => _escolherData(inicio: inicio),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: rotulo,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(_formatarData(valor), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _cartaoResumo(String rotulo, int valor, Color fundo, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(RaioApp.medio)),
      child: Column(
        children: [
          Text('$valor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cor)),
          Text(rotulo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cor)),
        ],
      ),
    );
  }

  Widget _linhaHistorico(Historico item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: CorApp.fundoCard, borderRadius: BorderRadius.circular(RaioApp.pequeno), border: Border.all(color: CorApp.borda)),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text(item.hora, style: const TextStyle(fontWeight: FontWeight.w800))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nomeMedicamento, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(item.dosagem, style: const TextStyle(color: CorApp.textoSuave, fontSize: 12)),
              ],
            ),
          ),
          RotuloStatus(status: item.status.toLowerCase()),
        ],
      ),
    );
  }
}
