import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/botao.dart';
import '../componentes/cabecalho.dart';
import '../componentes/campo_texto.dart';
import '../componentes/cartao.dart';
import '../componentes/linha_dupla.dart';
import '../componentes/opcao_sem_email.dart';
import '../estado/app_estado.dart';
import '../modelos/cuidador.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/mascaras.dart';
import '../utilitarios/tema.dart';

const _opcoesSexo = ['Feminino', 'Masculino', 'Outro'];

String _iniciais(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '';
  final primeira = partes.first[0];
  final ultima = partes.length > 1 ? partes.last[0] : '';
  return (primeira + ultima).toUpperCase();
}

String _formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

/// Tela de Configurações — equivalente a paginas/EdicaoPerfil.jsx do web: dados
/// pessoais, senha, aparência (tamanho da fonte; o tema entra com o modo escuro
/// do mobile) e (paciente) cuidador responsável/vínculo.
class EdicaoPerfil extends StatefulWidget {
  const EdicaoPerfil({super.key});

  @override
  State<EdicaoPerfil> createState() => _EdicaoPerfilState();
}

class _EdicaoPerfilState extends State<EdicaoPerfil> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _profissaoController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _emailCuidadorController = TextEditingController();

  DateTime? _dataNascimento;
  String _sexo = _opcoesSexo[0];
  bool _semEmail = false;
  bool _salvandoDados = false;
  bool _salvandoSenha = false;
  bool _enviandoSolicitacao = false;

  Cuidador? _cuidadorResponsavel;
  int? _cuidadorCarregadoId;

  @override
  void initState() {
    super.initState();
    final estado = context.read<AppEstado>();
    final usuario = estado.usuario!;
    _nomeController.text = usuario.nome;
    _emailController.text = usuario.email;
    _semEmail = usuario.email.isEmpty;
    if (usuario.tipo == 'paciente') {
      final paciente = estado.pacienteFoco?.paciente;
      _dataNascimento = paciente?.dataNascimento;
      final sexoApi = paciente?.sexo;
      _sexo = sexoParaApi.entries.firstWhere((e) => e.value == sexoApi, orElse: () => sexoParaApi.entries.first).key;
      _telefoneController.text = formatarTelefone(paciente?.telefone ?? '');
    } else {
      _profissaoController.text = usuario.profissao ?? '';
      _telefoneController.text = formatarTelefone(usuario.telefone ?? '');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregarCuidadorSeNecessario();
  }

  void _carregarCuidadorSeNecessario() {
    final estado = context.read<AppEstado>();
    if (estado.usuario?.tipo != 'paciente') return;
    final cuidadorId = estado.pacienteFoco?.paciente.cuidadorId;
    if (cuidadorId == null || cuidadorId == _cuidadorCarregadoId) return;
    _cuidadorCarregadoId = cuidadorId;
    estado.buscarCuidador(cuidadorId).then((cuidador) {
      if (mounted) setState(() => _cuidadorResponsavel = cuidador);
    }).catchError((_) {
      if (mounted) setState(() => _cuidadorResponsavel = null);
    });
  }

  @override
  void dispose() {
    for (final c in [
      _nomeController,
      _emailController,
      _telefoneController,
      _profissaoController,
      _senhaAtualController,
      _novaSenhaController,
      _confirmarSenhaController,
      _emailCuidadorController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String _mensagemErro(Object erro, String padrao) => erro is ApiExcecao ? erro.mensagem : padrao;

  Future<void> _salvarDados() async {
    final nome = _nomeController.text.trim();
    final email = _semEmail ? '' : _emailController.text.trim();
    if (nome.isEmpty) {
      _avisar('Preencha o nome.');
      return;
    }
    if (_semEmail ? !telefoneCompleto(_telefoneController.text) : email.isEmpty) {
      _avisar(_semEmail ? 'Sem e-mail, informe o telefone com DDD.' : 'Preencha o e-mail ou marque "Não tenho e-mail".');
      return;
    }
    final estado = context.read<AppEstado>();
    final ehPaciente = estado.usuario!.tipo == 'paciente';
    setState(() => _salvandoDados = true);
    try {
      await estado.atualizarPerfil(
        nome: nome,
        email: email,
        dataNascimento: ehPaciente ? _dataNascimento : null,
        sexo: ehPaciente ? _sexo : null,
        telefone: _telefoneController.text.trim(),
        profissao: ehPaciente ? null : _profissaoController.text.trim(),
      );
      _avisar('Dados atualizados.');
    } catch (erro) {
      _avisar(_mensagemErro(erro, 'Não foi possível atualizar os dados.'));
    } finally {
      if (mounted) setState(() => _salvandoDados = false);
    }
  }

  Future<void> _atualizarSenha() async {
    final nova = _novaSenhaController.text;
    if (nova.length < 8) {
      _avisar('A nova senha deve ter no mínimo 8 caracteres.');
      return;
    }
    if (nova != _confirmarSenhaController.text) {
      _avisar('As senhas não coincidem.');
      return;
    }
    setState(() => _salvandoSenha = true);
    try {
      await context.read<AppEstado>().alterarSenha(_senhaAtualController.text, nova);
      _senhaAtualController.clear();
      _novaSenhaController.clear();
      _confirmarSenhaController.clear();
      _avisar('Senha atualizada.');
    } catch (erro) {
      _avisar(_mensagemErro(erro, 'Não foi possível atualizar a senha.'));
    } finally {
      if (mounted) setState(() => _salvandoSenha = false);
    }
  }

  Future<void> _enviarSolicitacaoVinculo() async {
    final email = _emailCuidadorController.text.trim();
    if (email.isEmpty) {
      _avisar('Informe o e-mail ou telefone do cuidador.');
      return;
    }
    setState(() => _enviandoSolicitacao = true);
    try {
      await context.read<AppEstado>().solicitarVinculoCuidador(email);
      _emailCuidadorController.clear();
      _avisar('Solicitação enviada! Aguarde a confirmação do cuidador.');
    } catch (erro) {
      _avisar(_mensagemErro(erro, 'Não foi possível enviar a solicitação.'));
    } finally {
      if (mounted) setState(() => _enviandoSolicitacao = false);
    }
  }

  Future<void> _sairDaConta() async {
    await context.read<AppEstado>().sair();
    if (mounted) context.go('/login');
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

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    final usuario = estado.usuario;
    if (usuario == null) return const SizedBox.shrink();
    final ehPaciente = usuario.tipo == 'paciente';
    final paciente = estado.pacienteFoco?.paciente;

    // Paciente: card do cuidador (vinculado, pedido pendente ou formulário de
    // vínculo), ao lado da Aparência.
    Widget? cartaoCuidador;
    if (ehPaciente) {
      if (_cuidadorResponsavel != null && paciente?.cuidadorId != null) {
        cartaoCuidador = _cartaoCuidadorResponsavel(_cuidadorResponsavel!);
      } else if (paciente?.cuidadorSolicitadoId != null) {
        cartaoCuidador = Cartao(
          titulo: 'Cuidador(a) responsável',
          child: Text(
            'Solicitação enviada — aguardando confirmação do cuidador. Assim que ele aceitar, os dados aparecem aqui.',
            style: TextStyle(color: CorApp.textoSuave),
          ),
        );
      } else if (paciente?.cuidadorId == null) {
        cartaoCuidador = _cartaoVincularCuidador();
      }
    }

    return AndaimeApp(
      appBar: const Cabecalho(kicker: 'Minha conta', titulo: 'Configurações'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LinhaDupla(esquerda: _cartaoDados(usuario, ehPaciente), direita: _cartaoSenha()),
          const SizedBox(height: 16),
          if (cartaoCuidador != null)
            LinhaDupla(esquerda: _cartaoAparencia(estado), direita: cartaoCuidador)
          else
            _cartaoAparencia(estado),
        ],
      ),
    );
  }

  Widget _avatar(String nome) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(gradient: CorApp.gradienteAzul, shape: BoxShape.circle),
      child: Text(_iniciais(nome), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
    );
  }

  Widget _cabecalhoPessoa(String nome, String papel) {
    return Row(
      children: [
        _avatar(nome),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(papel, style: TextStyle(color: CorApp.textoSuave, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cartaoDados(UsuarioLogado usuario, bool ehPaciente) {
    return Cartao(
      titulo: 'Dados pessoais',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalhoPessoa(usuario.nome, ehPaciente ? 'Paciente' : 'Cuidador(a) / Médico(a)'),
          const SizedBox(height: 20),
          CampoTexto(rotulo: 'Nome de usuário', controller: _nomeController),
          const SizedBox(height: 14),
          if (ehPaciente) ...[
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _escolherDataNascimento,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data de nascimento'),
                      child: Text(_dataNascimento == null ? 'Selecionar' : _formatarData(_dataNascimento!)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sexo,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Sexo'),
                    items: _opcoesSexo.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (valor) => setState(() => _sexo = valor ?? _sexo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CampoTexto(
              rotulo: 'Telefone',
              controller: _telefoneController,
              tipoTeclado: TextInputType.phone,
              placeholder: '(11) 98765-4321',
            ),
          ] else ...[
            CampoTexto(
              rotulo: 'Profissão',
              controller: _profissaoController,
              placeholder: 'Ex.: Médica, Enfermeira, Cuidadora',
            ),
            const SizedBox(height: 14),
            CampoTexto(
              rotulo: 'Telefone',
              controller: _telefoneController,
              tipoTeclado: TextInputType.phone,
              placeholder: '(11) 98765-4321',
            ),
          ],
          const SizedBox(height: 14),
          if (!_semEmail) ...[
            CampoTexto(rotulo: 'E-mail', controller: _emailController, tipoTeclado: TextInputType.emailAddress),
            const SizedBox(height: 6),
          ],
          OpcaoSemEmail(marcado: _semEmail, aoMudar: (valor) => setState(() => _semEmail = valor)),
          const SizedBox(height: 18),
          Botao(texto: 'Salvar alterações', carregando: _salvandoDados, onPressed: _salvarDados),
        ],
      ),
    );
  }

  Widget _cartaoSenha() {
    return Cartao(
      titulo: 'Senha',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoTexto(rotulo: 'Senha atual', controller: _senhaAtualController, senha: true, placeholder: '••••••••'),
          const SizedBox(height: 14),
          CampoTexto(rotulo: 'Nova senha', controller: _novaSenhaController, senha: true, placeholder: 'Mínimo 8 caracteres'),
          const SizedBox(height: 14),
          CampoTexto(
            rotulo: 'Confirmar nova senha',
            controller: _confirmarSenhaController,
            senha: true,
            placeholder: 'Repita a nova senha',
          ),
          const SizedBox(height: 18),
          Botao(
            texto: 'Atualizar senha',
            variante: VarianteBotao.secundario,
            carregando: _salvandoSenha,
            onPressed: _atualizarSenha,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Divider(height: 1)),
          Botao(texto: 'Sair da conta', variante: VarianteBotao.perigo, onPressed: _sairDaConta),
        ],
      ),
    );
  }

  Widget _cartaoAparencia(AppEstado estado) {
    return Cartao(
      titulo: 'Aparência',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tamanho da fonte', style: TextStyle(fontWeight: FontWeight.w700, color: CorApp.textoLabel)),
          const SizedBox(height: 10),
          SeletorTamanhoFonte(estado: estado),
          const SizedBox(height: 16),
          Text('Tema', style: TextStyle(fontWeight: FontWeight.w700, color: CorApp.textoLabel)),
          const SizedBox(height: 10),
          _SeletorTema(estado: estado),
          const SizedBox(height: 18),
          Botao(
            texto: 'Ajuda e acessibilidade',
            variante: VarianteBotao.secundario,
            onPressed: () => context.push('/acessibilidade'),
          ),
        ],
      ),
    );
  }

  Widget _cartaoCuidadorResponsavel(Cuidador cuidador) {
    Widget linha(String rotulo, String valor) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(rotulo, style: TextStyle(fontWeight: FontWeight.w700, color: CorApp.textoLabel)),
              ),
              Expanded(child: Text(valor)),
            ],
          ),
        );

    return Cartao(
      titulo: 'Cuidador(a) responsável',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalhoPessoa(cuidador.nome, cuidador.profissao ?? 'Cuidador(a) / Médico(a)'),
          const SizedBox(height: 16),
          linha('E-mail', cuidador.email.isEmpty ? '—' : cuidador.email),
          linha('Telefone', (cuidador.telefone ?? '').isEmpty ? '—' : cuidador.telefone!),
          const SizedBox(height: 6),
          Text(
            'Seu cuidador(a) vê no painel e recebe um aviso, com o app aberto, quando uma dose fica atrasada.',
            style: TextStyle(color: CorApp.textoSuave),
          ),
        ],
      ),
    );
  }

  Widget _cartaoVincularCuidador() {
    return Cartao(
      titulo: 'Vincular cuidador(a)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informe o e-mail ou telefone do seu cuidador(a) já cadastrado — ele(a) precisa confirmar antes do vínculo valer.',
            style: TextStyle(color: CorApp.textoSuave),
          ),
          const SizedBox(height: 14),
          CampoTexto(
            rotulo: 'E-mail ou telefone do cuidador',
            controller: _emailCuidadorController,
            tipoTeclado: TextInputType.emailAddress,
            placeholder: 'cuidador@email.com ou (79) 99999-9999',
          ),
          const SizedBox(height: 16),
          Botao(
            texto: 'Enviar solicitação',
            variante: VarianteBotao.secundario,
            carregando: _enviandoSolicitacao,
            onPressed: _enviarSolicitacaoVinculo,
          ),
        ],
      ),
    );
  }
}

/// Botões Pequena / Média / Grande — reaproveitado na tela de Acessibilidade.
class SeletorTamanhoFonte extends StatelessWidget {
  final AppEstado estado;
  const SeletorTamanhoFonte({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < opcoesTamanhoFonte.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              selected: estado.tamanhoFonte == opcoesTamanhoFonte[i].valor,
              child: Botao(
                texto: opcoesTamanhoFonte[i].rotulo,
                variante: estado.tamanhoFonte == opcoesTamanhoFonte[i].valor ? VarianteBotao.primario : VarianteBotao.secundario,
                onPressed: () => estado.definirTamanhoFonte(opcoesTamanhoFonte[i].valor),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Botões Claro / Escuro — mesma escolha da chave do menu (como no web).
class _SeletorTema extends StatelessWidget {
  final AppEstado estado;
  const _SeletorTema({required this.estado});

  @override
  Widget build(BuildContext context) {
    Widget opcao(String valor, String rotulo) => Expanded(
          child: Semantics(
            selected: estado.tema == valor,
            child: Botao(
              texto: rotulo,
              variante: estado.tema == valor ? VarianteBotao.primario : VarianteBotao.secundario,
              onPressed: () => estado.definirTema(valor),
            ),
          ),
        );
    return Row(children: [opcao('claro', 'Claro'), const SizedBox(width: 8), opcao('escuro', 'Escuro')]);
  }
}
