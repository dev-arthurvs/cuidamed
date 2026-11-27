import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';
import '../modelos/paciente.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/tema.dart';
import 'botao.dart';

class CartaoObservacoes extends StatefulWidget {
  final Paciente paciente;
  const CartaoObservacoes({super.key, required this.paciente});

  @override
  State<CartaoObservacoes> createState() => _CartaoObservacoesState();
}

class _CartaoObservacoesState extends State<CartaoObservacoes> {
  late final TextEditingController _controller;
  late String _base;
  bool _salvando = false;

  String get _salvo => widget.paciente.observacoesClinicas ?? '';
  bool get _alterado => _controller.text.trim() != _salvo.trim();

  @override
  void initState() {
    super.initState();
    _base = _salvo;
    _controller = TextEditingController(text: _salvo);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant CartaoObservacoes antigo) {
    super.didUpdateWidget(antigo);
    if (_salvo != _base) {
      if (_controller.text == _base) _controller.text = _salvo;
      _base = _salvo;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await context.read<AppEstado>().atualizarObservacoesClinicas(widget.paciente.id, _controller.text);
      mensageiro.showSnackBar(const SnackBar(content: Text('Observações clínicas salvas.')));
    } catch (erro) {
      mensageiro.showSnackBar(
          SnackBar(content: Text(erro is ApiExcecao ? erro.mensagem : 'Não foi possível salvar as observações.')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CorApp.fundoDestaque,
        borderRadius: BorderRadius.circular(RaioApp.grande),
        border: Border.all(color: CorApp.bordaDestaque, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Observações clínicas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CorApp.textoLabel, height: 1.5),
            decoration: InputDecoration(
              fillColor: CorApp.fundoCard,
              hintText: 'Ex.: alergia a dipirona, toma os remédios em jejum, dificuldade para engolir comprimidos...',
              hintMaxLines: 3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 8,
            children: [
              if (_alterado)
                Botao(
                  texto: 'Descartar',
                  variante: VarianteBotao.contorno,
                  compacto: true,
                  larguraTotal: false,
                  onPressed: _salvando ? null : () => _controller.text = _salvo,
                ),
              Botao(
                texto: 'Salvar observações',
                compacto: true,
                larguraTotal: false,
                carregando: _salvando,
                onPressed: _alterado ? _salvar : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
