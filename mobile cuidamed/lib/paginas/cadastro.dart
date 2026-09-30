import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../componentes/botao.dart';
import '../componentes/campo_texto.dart';
import '../componentes/layout_autenticacao.dart';
import '../estado/app_estado.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/tema.dart';
import '../utilitarios/animacoes.dart';

const _opcoesSexo = ['Feminino', 'Masculino', 'Outro'];

/// Frase do painel azul muda conforme o papel escolhido — igual ao web.
const _frasesImpacto = {
  'paciente': (
    titulo: 'O remédio certo, na hora certa, sempre com você.',
    subtitulo: 'Receba lembretes automáticos e nunca mais perca uma dose importante.',
  ),
  'cuidador': (
    titulo: 'Cuidado à distância, com tranquilidade total.',
    subtitulo: 'Acompanhe em tempo real a adesão aos medicamentos de quem você cuida.',
  ),
};

/// Equivalente a paginas/Cadastro.jsx do web.
class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  String _tipo = 'paciente';
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _profissaoController = TextEditingController();
  DateTime? _dataNascimento;
  String _sexo = _opcoesSexo[0];
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    for (final c in [
      _nomeController,
      _emailController,
      _senhaController,
      _telefoneController,
      _enderecoController,
      _profissaoController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _criarConta() async {
    if (_nomeController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      setState(() => _erro = 'Preencha nome e e-mail.');
      return;
    }
    if (_senhaController.text.length < 8) {
      setState(() => _erro = 'A senha deve ter no mínimo 8 caracteres.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AppEstado>().cadastrar(
            tipo: _tipo,
            nome: _nomeController.text.trim(),
            email: _emailController.text.trim(),
            senha: _senhaController.text,
            dataNascimentoIso: _dataNascimento != null
                ? '${_dataNascimento!.year.toString().padLeft(4, '0')}-${_dataNascimento!.month.toString().padLeft(2, '0')}-${_dataNascimento!.day.toString().padLeft(2, '0')}'
                : null,
            sexo: _tipo == 'paciente' ? sexoParaApi[_sexo] : null,
            telefone: _telefoneController.text.trim(),
            endereco: _tipo == 'paciente' ? _enderecoController.text.trim() : null,
            profissao: _tipo == 'cuidador' ? _profissaoController.text.trim() : null,
          );
      if (mounted) context.go('/painel');
    } catch (erro) {
      setState(() => _erro = erro is ApiExcecao ? erro.mensagem : 'Não foi possível criar a conta.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _escolherDataNascimento() async {
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(1960, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selecionada != null && mounted) setState(() => _dataNascimento = selecionada);
  }

  static const _estiloRotulo = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CorApp.textoLabel);

  @override
  Widget build(BuildContext context) {
    final frase = _frasesImpacto[_tipo]!;
    final ehPaciente = _tipo == 'paciente';

    return LayoutAutenticacao(
      soLogoNoCelular: true, // igual ao login: no celular, só a logo no painel azul
      heroTitulo: frase.titulo,
      heroSubtitulo: frase.subtitulo,
      rodape: '© 2026 CuidaMed · Protótipo de demonstração',
      cartao: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: LinkAutenticacao(
              texto: '‹ Voltar para entrar',
              destaque: false,
              tamanhoFonte: 14,
              onTap: () => context.go('/login'),
            ),
          ),
          const SizedBox(height: 10),
          const TituloAutenticacao(titulo: 'Criar cadastro'),
          const SizedBox(height: 18),
          _seletorPapel(),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: transicaoTrocaSuave(),
            child: Column(
              key: ValueKey(_tipo),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CampoTexto(
                  rotulo: 'Nome completo',
                  rotuloExterno: true,
                  placeholder: ehPaciente ? 'Maria Aparecida Souza' : 'Ana Lúcia Souza',
                  controller: _nomeController,
                ),
                const SizedBox(height: 18),
                if (ehPaciente) ...[
                  _linhaNascimentoSexo(),
                  const SizedBox(height: 18),
                  CampoTexto(
                    rotulo: 'Telefone',
                    rotuloExterno: true,
                    controller: _telefoneController,
                    tipoTeclado: TextInputType.phone,
                    placeholder: '(11) 98765-4321',
                  ),
                  const SizedBox(height: 18),
                  CampoTexto(
                    rotulo: 'Endereço',
                    rotuloExterno: true,
                    controller: _enderecoController,
                    placeholder: 'Rua, número, bairro - cidade/UF',
                  ),
                ] else ...[
                  CampoTexto(
                    rotulo: 'Profissão',
                    rotuloExterno: true,
                    controller: _profissaoController,
                    placeholder: 'Ex.: Médica, Enfermeira, Cuidadora',
                  ),
                  const SizedBox(height: 18),
                  CampoTexto(
                    rotulo: 'Telefone',
                    rotuloExterno: true,
                    controller: _telefoneController,
                    tipoTeclado: TextInputType.phone,
                    placeholder: '(11) 98765-4321',
                  ),
                ],
                const SizedBox(height: 18),
                CampoTexto(
                  rotulo: 'E-mail',
                  rotuloExterno: true,
                  controller: _emailController,
                  tipoTeclado: TextInputType.emailAddress,
                  placeholder: 'seu@email.com',
                ),
                const SizedBox(height: 18),
                CampoTexto(
                  rotulo: 'Senha',
                  rotuloExterno: true,
                  controller: _senhaController,
                  senha: true,
                  placeholder: 'Mínimo 8 caracteres',
                  onSubmitted: (_) => _criarConta(),
                ),
              ],
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 14),
            Text(_erro!, style: const TextStyle(color: CorApp.vermelho, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 24),
          Botao(texto: 'Criar conta e entrar', onPressed: _criarConta, carregando: _carregando),
        ],
      ),
    );
  }

  /// Caixa "Eu sou" com Paciente/Cuidador — mesmo visual do `.autenticacao__papel` do web.
  Widget _seletorPapel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CorApp.fundoDestaque,
        borderRadius: BorderRadius.circular(RaioApp.medio),
        border: Border.all(color: CorApp.bordaDestaque, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Eu sou', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: CorApp.textoLabel)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _opcaoPapel('paciente', 'Paciente')),
              const SizedBox(width: 10),
              Expanded(child: _opcaoPapel('cuidador', 'Cuidador')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opcaoPapel(String valor, String rotulo) {
    final ativo = _tipo == valor;
    return Semantics(
      selected: ativo,
      button: true,
      child: Material(
        color: ativo ? CorApp.azul : CorApp.fundoCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RaioApp.pequeno),
          side: BorderSide(color: ativo ? CorApp.azul : CorApp.bordaInput, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(RaioApp.pequeno),
          onTap: () => setState(() {
            _tipo = valor;
            _erro = null;
          }),
          child: SizedBox(
            height: 50,
            child: Center(
              child: Text(
                rotulo,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ativo ? Colors.white : CorApp.textoLabel),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _linhaNascimentoSexo() {
    final data = _dataNascimento;
    final campoData = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Data de nascimento', style: _estiloRotulo),
        const SizedBox(height: 8),
        InkWell(
          onTap: _escolherDataNascimento,
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
    // Lado a lado quando cabe (como o grid de 2 colunas do web); empilhado no celular estreito.
    return LayoutBuilder(
      builder: (context, restricoes) => restricoes.maxWidth >= 360
          ? Row(
              // Alinha pela base: se um rótulo quebrar em 2 linhas, os campos continuam na mesma altura.
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [Expanded(child: campoData), const SizedBox(width: 14), Expanded(child: campoSexo)],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [campoData, const SizedBox(height: 18), campoSexo],
            ),
    );
  }
}
