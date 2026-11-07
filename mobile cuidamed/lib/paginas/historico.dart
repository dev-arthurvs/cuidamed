import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/botao.dart';
import '../componentes/cabecalho.dart';
import '../componentes/rotulo_status.dart';
import '../componentes/voltar_detalhes_paciente.dart';
import '../componentes/escolha_paciente.dart';
import '../estado/app_estado.dart';
import '../modelos/historico.dart';
import '../servicos/relatorio_pdf.dart';
import '../utilitarios/horarios.dart';
import '../utilitarios/tema.dart';

class HistoricoPagina extends StatefulWidget {
  final int? pacienteId;

  /// Busca um período antigo; por padrão, no servidor. Trocado nos testes.
  final Future<List<Historico>> Function(int pacienteId, DateTime de, DateTime ate)? carregarAntigos;

  const HistoricoPagina({super.key, this.pacienteId, this.carregarAntigos});

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

  // O app guarda só os últimos dias do histórico; período mais antigo vem do
  // servidor. Até chegar, nada é calculado: sem os registros, doses tomadas
  // apareceriam como perdidas.
  String? _chaveAntigos;
  List<Historico>? _antigos;
  bool _erroAntigos = false;

  Future<void> _buscarAntigos(AppEstado estado, String chave, int pacienteId, DateTime de, DateTime ate) async {
    _chaveAntigos = chave;
    _antigos = null;
    _erroAntigos = false;
    final carregar = widget.carregarAntigos ?? estado.carregarHistoricoAntigo;
    List<Historico>? itens;
    try {
      itens = await carregar(pacienteId, de, ate);
    } catch (_) {
      // Mostra o aviso na lista, sem calcular nada com dados incompletos.
    }
    if (!mounted || _chaveAntigos != chave) return;
    setState(() {
      _antigos = itens;
      _erroAntigos = itens == null;
    });
  }

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
        appBar: Cabecalho(kicker: 'Registro de doses', titulo: 'Histórico de doses'),
        body: Padding(padding: EdgeInsets.all(20), child: Text('Nenhum paciente selecionado.')),
      );
    }

    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    final inicioJanela = inicioJanelaHistorico(hojeSemHora);
    final chaveAntigos = _inicio.isBefore(inicioJanela) ? '${dados.paciente.id}|${_inicio.toIso8601String()}' : null;
    if (chaveAntigos != null && chaveAntigos != _chaveAntigos) {
      _buscarAntigos(estado, chaveAntigos, dados.paciente.id, _inicio, inicioJanela.subtract(const Duration(days: 1)));
    }
    final periodoDisponivel = chaveAntigos == null || _antigos != null;
    final carregandoAntigos = !periodoDisponivel && !_erroAntigos;
    final historicoDoPeriodo = chaveAntigos != null && _antigos != null ? [..._antigos!, ...dados.historico] : dados.historico;

    final nomesMedicamentos =
        {...historicoDoPeriodo.map((h) => h.nomeMedicamento), ...dados.medicamentos.map((m) => m.nome)}.toList()..sort();

    // Registros do banco + doses que passaram do horário sem registro (as
    // mesmas que o Início mostra como atrasadas/perdidas).
    final semRegistro =
        periodoDisponivel ? dosesSemRegistro(dados.paciente.id, dados.medicamentos, historicoDoPeriodo, _inicio, _fim) : const <Historico>[];
    final entradas = [...(periodoDisponivel ? historicoDoPeriodo : const <Historico>[]), ...semRegistro]
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

    final titulo =
        estado.usuario!.tipo == 'cuidador' ? 'Histórico de doses de ${dados.paciente.nome}' : 'Histórico de doses';

    return AndaimeApp(
      appBar: Cabecalho(kicker: 'Registro de doses', titulo: titulo),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          VoltarDetalhesPaciente(pacienteId: dados.paciente.id),
          const Text('Período', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _campoData('De', _inicio, inicio: true)),
              const SizedBox(width: 10),
              Expanded(child: _campoData('Até', _fim, inicio: false)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Medicamento', style: TextStyle(fontWeight: FontWeight.w700)),
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
          const SizedBox(height: 14),
          Botao(
            texto: 'Gerar relatório (PDF)',
            variante: VarianteBotao.secundario,
            onPressed: periodoDisponivel ? () => _gerarRelatorio(dados!, entradas.map((e) => e.item).toList()) : null,
          ),
          const SizedBox(height: 20),
          if (entradas.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                carregandoAntigos
                    ? 'Carregando...'
                    : _erroAntigos
                        ? 'Não foi possível carregar esse período.'
                        : 'Nenhum registro para este filtro.',
                style: TextStyle(color: CorApp.textoSuave),
              ),
            ),
          for (var indice = 0; indice < entradas.length; indice++) ...[
            if (indice == 0 || entradas[indice - 1].item.data != entradas[indice].item.data)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  _rotuloDoDia(entradas[indice].item.data, entradas[indice].diferenca),
                  style: TextStyle(fontWeight: FontWeight.w700, color: CorApp.textoSuave, fontSize: 13),
                ),
              ),
            _linhaHistorico(entradas[indice].item),
          ],
        ],
      ),
    );
  }

  Future<void> _gerarRelatorio(PacienteComDados dados, List<Historico> entradas) async {
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      final tema = await carregarTemaRelatorio();
      await Printing.layoutPdf(
        name: 'Relatorio-CuidaMed.pdf',
        onLayout: (_) => gerarRelatorioPdf(
          paciente: dados.paciente,
          medicamentosAtivos: dados.medicamentosAtivos(),
          entradas: entradas,
          inicio: _inicio,
          fim: _fim,
          tema: tema,
        ),
      );
    } catch (_) {
      mensageiro.showSnackBar(const SnackBar(content: Text('Não foi possível gerar o relatório.')));
    }
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
          Text('$valor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cor)),
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
          SizedBox(width: 52, child: Text(item.hora, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nomeMedicamento, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (item.dosagem.isNotEmpty) Text(item.dosagem, style: TextStyle(color: CorApp.textoSuave, fontSize: 12)),
              ],
            ),
          ),
          RotuloStatus(status: item.status.toLowerCase()),
        ],
      ),
    );
  }
}
