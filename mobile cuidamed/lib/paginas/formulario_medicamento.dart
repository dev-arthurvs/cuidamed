import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../componentes/barra_logo.dart';
import '../componentes/botao.dart';
import '../componentes/campo_texto.dart';
import '../estado/app_estado.dart';
import '../modelos/medicamento.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/horarios.dart';
import '../utilitarios/tema.dart';

class FormularioMedicamento extends StatefulWidget {
  final Medicamento? medicamentoExistente;
  const FormularioMedicamento({super.key, this.medicamentoExistente});

  @override
  State<FormularioMedicamento> createState() => _FormularioMedicamentoState();
}

class _FormularioMedicamentoState extends State<FormularioMedicamento> {
  final _nomeController = TextEditingController();
  final _dosagemController = TextEditingController();
  final _estoqueController = TextEditingController();
  final _porDoseController = TextEditingController();
  final _observacoesController = TextEditingController();

  String _forma = formasMedicamento.first;
  String _frequencia = frequenciasMedicamento.first;
  List<String> _horarios = [];
  DateTime _inicio = DateTime.now();
  DateTime? _fim;
  bool _salvando = false;
  String? _erro;

  bool get _ehEdicao => widget.medicamentoExistente != null;
  bool get _ehPomada => _forma == 'POMADA';

  @override
  void initState() {
    super.initState();
    final existente = widget.medicamentoExistente;
    if (existente != null) {
      _nomeController.text = existente.nome;
      _dosagemController.text = existente.dosagem;
      _forma = existente.forma;
      _frequencia = existente.frequencia;
      _horarios = List.of(existente.horarios);
      _inicio = existente.dataInicio;
      _fim = existente.dataFim;
      _observacoesController.text = existente.observacoes ?? '';
      _estoqueController.text = existente.quantidadeEstoque?.toString() ?? '';
      _porDoseController.text = existente.quantidadePorDose?.toString() ?? '';
    }
  }

  Future<void> _escolherHorario() async {
    final selecionado = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (selecionado == null || !mounted) return;
    final texto = '${selecionado.hour.toString().padLeft(2, '0')}:${selecionado.minute.toString().padLeft(2, '0')}';
    if (_horarios.contains(texto)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esse horário já foi adicionado.')));
      return;
    }
    setState(() => _horarios = [..._horarios, texto]..sort());
  }

  Future<void> _escolherData({required bool inicio}) async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: inicio ? _inicio : (_fim ?? _inicio),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selecionada == null) return;
    setState(() {
      if (inicio) {
        _inicio = selecionada;
      } else {
        _fim = selecionada;
      }
    });
  }

  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o nome do medicamento.');
      return;
    }
    if (_horarios.isEmpty) {
      setState(() => _erro = 'Adicione ao menos um horário de dose.');
      return;
    }
    if (_fim != null && dataAtualISO(_fim).compareTo(dataAtualISO(_inicio)) < 0) {
      setState(() => _erro = 'A data de fim não pode ser anterior à data de início.');
      return;
    }
    if (!_ehPomada && (_estoqueController.text.isEmpty || int.tryParse(_estoqueController.text) == null || int.parse(_estoqueController.text) < 0)) {
      setState(() => _erro = 'Informe a quantidade em estoque.');
      return;
    }
    if (!_ehPomada && (_porDoseController.text.isEmpty || int.tryParse(_porDoseController.text) == null || int.parse(_porDoseController.text) <= 0)) {
      setState(() => _erro = 'Informe a quantidade usada por dose.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final estado = context.read<AppEstado>();
    final pacienteId = estado.pacienteFoco!.paciente.id;
    final medicamento = Medicamento(
      id: widget.medicamentoExistente?.id ?? 0,
      pacienteId: pacienteId,
      nome: _nomeController.text.trim(),
      dosagem: _dosagemController.text.trim(),
      forma: _forma,
      frequencia: _frequencia,
      dataInicio: _inicio,
      dataFim: _fim,
      observacoes: _observacoesController.text.trim().isEmpty ? null : _observacoesController.text.trim(),
      quantidadeEstoque: _ehPomada ? null : int.parse(_estoqueController.text),
      quantidadePorDose: _ehPomada ? null : int.parse(_porDoseController.text),
      horarios: _horarios,
    );

    try {
      if (_ehEdicao) {
        await estado.editarMedicamento(pacienteId, widget.medicamentoExistente!.id, medicamento);
      } else {
        await estado.adicionarMedicamento(pacienteId, medicamento);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_ehEdicao ? 'Medicamento atualizado.' : 'Medicamento adicionado.')));
        context.pop();
      }
    } catch (erro) {
      setState(() => _erro = erro is ApiExcecao ? erro.mensagem : 'Não foi possível salvar o medicamento.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String _formatarData(DateTime data) => '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  @override
  Widget build(BuildContext context) {
    final unidade = unidadeEstoquePorForma[_forma] ?? 'unidades';

    return Scaffold(
      appBar: BarraComLogo(
        logoLevaAoInicio: false,
        abaixo: AppBar(title: Text(_ehEdicao ? 'Editar medicamento' : 'Novo medicamento')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTexto(rotulo: 'Nome do medicamento', controller: _nomeController, placeholder: 'Ex.: Losartana'),
              const SizedBox(height: 14),
              CampoTexto(
                rotulo: 'Dosagem',
                controller: _dosagemController,
                placeholder: _ehPomada ? 'Ex.: 1% (concentração)' : '50 mg',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _forma,
                decoration: const InputDecoration(labelText: 'Forma'),
                items: formasMedicamento.map((f) => DropdownMenuItem(value: f, child: Text(rotuloForma[f] ?? f))).toList(),
                onChanged: (valor) => setState(() => _forma = valor ?? _forma),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _frequencia,
                decoration: const InputDecoration(labelText: 'Frequência'),
                items: frequenciasMedicamento.map((f) => DropdownMenuItem(value: f, child: Text(rotuloFrequencia[f] ?? f))).toList(),
                onChanged: (valor) => setState(() => _frequencia = valor ?? _frequencia),
              ),
              if (!_ehPomada) ...[
                const SizedBox(height: 14),
                CampoTexto(
                  rotulo: 'Estoque atual ($unidade)',
                  controller: _estoqueController,
                  tipoTeclado: TextInputType.number,
                  placeholder: 'Ex.: 30',
                ),
                const SizedBox(height: 14),
                CampoTexto(
                  rotulo: 'Quantidade por dose ($unidade)',
                  controller: _porDoseController,
                  tipoTeclado: TextInputType.number,
                  placeholder: 'Ex.: 1',
                ),
              ],
              const SizedBox(height: 22),
              const Text('Horários das doses', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final horario in _horarios)
                    Chip(
                      label: Text(horario),
                      onDeleted: () => setState(() => _horarios = _horarios.where((h) => h != horario).toList()),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Botao(texto: '+ Adicionar horário', variante: VarianteBotao.secundario, larguraTotal: false, onPressed: _escolherHorario),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _escolherData(inicio: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Data de início'),
                        child: Text(_formatarData(_inicio)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _escolherData(inicio: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Data de fim (opcional)'),
                        child: Text(_fim == null ? 'Uso contínuo' : _formatarData(_fim!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _observacoesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Observações / prescrição', hintText: 'Ex.: tomar após o café da manhã'),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 14),
                Text(_erro!, style: const TextStyle(color: CorApp.vermelho, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 24),
              Botao(
                texto: _ehEdicao ? 'Salvar alterações' : 'Adicionar medicamento',
                onPressed: _salvar,
                carregando: _salvando,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
