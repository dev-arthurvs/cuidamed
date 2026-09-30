import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/animacoes.dart';
import '../utilitarios/tema.dart';
import 'botao.dart';
import 'campo_texto.dart';

const _opcoesSexo = ['Feminino', 'Masculino', 'Outro'];

/// Largura a partir da qual o cadastro abre como janela centralizada (como o
/// modal do web); abaixo disso, sobe como painel inferior de tela quase cheia.
const _larguraJanela = 700.0;

/// Abre o "Cadastrar novo paciente" do cuidador — equivalente ao
/// paginas/CadastroPaciente.jsx do web: mesmos campos, textos e validações,
/// sem senha (o paciente cria a própria em "Ativar meu acesso").
Future<void> abrirCadastroPaciente(BuildContext context) async {
  final mensageiro = ScaffoldMessenger.of(context);
  final largo = MediaQuery.sizeOf(context).width >= _larguraJanela;
  final bool? cadastrou;
  if (largo) {
    cadastrou = await mostrarDialogoAnimado<bool>(
      context: context,
      barrierColor: const Color(0x800C2342),
      builder: (_) => Dialog(
        // Branco puro como o modal do web (o Material 3 tinge diálogos por padrão).
        backgroundColor: CorApp.fundoCard,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaioApp.grande)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: const _FormularioCadastroPaciente(),
        ),
      ),
    );
  } else {
    cadastrou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: CorApp.fundoCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(RaioApp.grande))),
      builder: (contexto) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(contexto).height * 0.92),
        child: const _FormularioCadastroPaciente(),
      ),
    );
  }
  if (cadastrou == true) {
    mensageiro.showSnackBar(const SnackBar(content: Text('Paciente cadastrado e vinculado com sucesso.')));
  }
}

class _FormularioCadastroPaciente extends StatefulWidget {
  const _FormularioCadastroPaciente();

  @override
  State<_FormularioCadastroPaciente> createState() => _FormularioCadastroPacienteState();
}

class _FormularioCadastroPacienteState extends State<_FormularioCadastroPaciente> {
  final _nome = TextEditingController();
  final _enfermidade = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _endereco = TextEditingController();
  DateTime? _dataNascimento;
  String _sexo = _opcoesSexo[0];
  bool _salvando = false;
  String? _erro;

  static const _estiloRotulo = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CorApp.textoLabel);

  @override
  void dispose() {
    for (final c in [_nome, _enfermidade, _email, _telefone, _endereco]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o nome do paciente.');
      return;
    }
    if (_email.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o e-mail do paciente.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await context.read<AppEstado>().cadastrarPacienteDoCuidador(
            nome: _nome.text.trim(),
            email: _email.text.trim(),
            dataNascimento: _dataNascimento,
            sexo: _sexo,
            enfermidade: _enfermidade.text,
            telefone: _telefone.text,
            endereco: _endereco.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (erro) {
      if (mounted) {
        setState(() {
          _erro = erro is ApiExcecao ? erro.mensagem : 'Não foi possível cadastrar o paciente.';
          _salvando = false;
        });
      }
    }
  }

  Future<void> _escolherData() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(1950, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selecionada != null && mounted) setState(() => _dataNascimento = selecionada);
  }

  @override
  Widget build(BuildContext context) {
    final tecladoAberto = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: tecladoAberto),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalho(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: LayoutBuilder(builder: (context, restricoes) => _campos(duasColunas: restricoes.maxWidth >= 520)),
            ),
          ),
          _rodape(),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PACIENTES',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: CorApp.azul, letterSpacing: 0.6)),
                SizedBox(height: 4),
                Text('Cadastrar novo paciente',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: CorApp.texto)),
              ],
            ),
          ),
          Material(
            color: CorApp.fundoDestaque,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _salvando ? null : () => Navigator.of(context).pop(false),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.close, size: 22, color: CorApp.textoSuave, semanticLabel: 'Fechar'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campos({required bool duasColunas}) {
    Widget par(Widget a, Widget b) => duasColunas
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)],
          )
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 16), b]);

    final data = _dataNascimento;
    final campoData = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Data de nascimento', style: _estiloRotulo),
        const SizedBox(height: 8),
        InkWell(
          onTap: _escolherData,
          borderRadius: BorderRadius.circular(RaioApp.pequeno),
          child: InputDecorator(
            decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 20)),
            child: Text(
              data == null
                  ? 'dd/mm/aaaa'
                  : '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
              style: TextStyle(fontSize: 17, color: data == null ? CorApp.textoSuave : CorApp.texto),
            ),
          ),
        ),
      ],
    );
    final campoSexo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sexo', style: _estiloRotulo),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _sexo,
          items: _opcoesSexo.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (valor) => setState(() => _sexo = valor ?? _sexo),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(rotulo: 'Nome completo', rotuloExterno: true, placeholder: 'Ex.: Maria Aparecida Souza', controller: _nome),
        const SizedBox(height: 16),
        // Lado a lado quando há espaço (como o grid do web); empilhados no celular,
        // onde a data espremida quebrava em duas linhas.
        LayoutBuilder(
          builder: (context, r) => r.maxWidth >= 420
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [Expanded(child: campoData), const SizedBox(width: 12), Expanded(child: campoSexo)],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [campoData, const SizedBox(height: 16), campoSexo],
                ),
        ),
        const SizedBox(height: 16),
        CampoTexto(
          rotulo: 'Enfermidade / condição principal',
          rotuloExterno: true,
          placeholder: 'Ex.: Hipertensão e diabetes tipo 2',
          controller: _enfermidade,
        ),
        const SizedBox(height: 16),
        par(
          CampoTexto(
            rotulo: 'E-mail',
            rotuloExterno: true,
            placeholder: 'paciente@email.com',
            controller: _email,
            tipoTeclado: TextInputType.emailAddress,
          ),
          CampoTexto(
            rotulo: 'Telefone',
            rotuloExterno: true,
            placeholder: '(11) 98765-4321',
            controller: _telefone,
            tipoTeclado: TextInputType.phone,
          ),
        ),
        const SizedBox(height: 16),
        CampoTexto(
          rotulo: 'Endereço',
          rotuloExterno: true,
          placeholder: 'Rua, número, bairro - cidade/UF',
          controller: _endereco,
          onSubmitted: (_) => _salvar(),
        ),
      ],
    );
  }

  Widget _rodape() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: CorApp.borda))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_erro != null) ...[
            Text(_erro!, style: const TextStyle(color: CorApp.vermelho, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Botao(
                  texto: 'Cancelar',
                  variante: VarianteBotao.contorno,
                  onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Botao(texto: 'Cadastrar paciente', carregando: _salvando, onPressed: _salvar),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
