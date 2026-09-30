import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/cuidador.dart';
import '../modelos/historico.dart';
import '../modelos/medicamento.dart';
import '../modelos/paciente.dart';
import '../servicos/api_cliente.dart';
import '../servicos/auth_servico.dart';
import '../servicos/cuidador_servico.dart';
import '../servicos/historico_servico.dart';
import '../servicos/medicamento_servico.dart';
import '../servicos/paciente_servico.dart';
import '../utilitarios/horarios.dart';

class UsuarioLogado {
  final int id;
  final String nome;
  final String email;
  final String tipo; // 'paciente' | 'cuidador'
  final String? profissao; // só cuidador
  final String? telefone; // só cuidador (o do paciente fica em Paciente)
  UsuarioLogado({required this.id, required this.nome, required this.email, required this.tipo, this.profissao, this.telefone});
}

/// Preferência de tamanho de fonte (acessibilidade) — mesmos valores e
/// fatores do web (utilitarios/preferenciaFonte.js).
const Map<String, double> escalaPorTamanhoFonte = {'pequena': 0.9, 'media': 1.0, 'grande': 1.15};
const List<({String valor, String rotulo})> opcoesTamanhoFonte = [
  (valor: 'pequena', rotulo: 'Pequena'),
  (valor: 'media', rotulo: 'Média'),
  (valor: 'grande', rotulo: 'Grande'),
];
const _chaveTamanhoFonte = 'tamanhoFonte';
// Sessão salva no aparelho (o app continua logado ao reabrir; o token expira em alguns dias).
const _chaveId = 'usuarioId';
const _chaveTipo = 'usuarioTipo';
const _chaveToken = 'tokenSessao';
const Map<String, String> sexoParaApi = {'Feminino': 'FEMININO', 'Masculino': 'MASCULINO', 'Outro': 'OUTRO'};

class PacienteComDados {
  final Paciente paciente;
  final List<Medicamento> medicamentos;
  final List<Historico> historico;

  PacienteComDados({required this.paciente, required this.medicamentos, required this.historico});

  List<Medicamento> medicamentosAtivos() =>
      medicamentos.where((m) => !medicamentoEncerrado(m, historico: historico)).toList();

  List<Historico> historicoHoje() {
    final hoje = dataAtualISO();
    return historico.where((h) => dataAtualISO(h.data) == hoje).toList();
  }
}

/// Estado central da aplicação — equivalente ao ContextoApp.jsx do web:
/// usuário logado, paciente em foco, lista de pacientes (do cuidador) e as
/// operações que os disparam. Widgets consomem via Provider/Consumer.
class AppEstado extends ChangeNotifier {
  /// Igual ao INTERVALO_VERIFICACAO_MS do web: a cada 30 s as telas se
  /// redesenham e recalculam os status das doses (pendente → atrasado →
  /// perdido) e a virada do dia — sem isso, uma dose das 08:00 ficava
  /// "A tomar" o dia todo até algo redesenhar a tela.
  static const intervaloAtualizacao = Duration(seconds: 30);
  Timer? _relogio;

  @visibleForTesting
  void iniciarRelogio() {
    _relogio?.cancel();
    _relogio = Timer.periodic(intervaloAtualizacao, (_) {
      notifyListeners();
      sincronizarDados();
    });
  }

  bool _sincronizando = false;

  /// Sincronização entre web e mobile (igual ao web): busca de novo no servidor
  /// os dados de quem está logado — o paciente, ou todos os pacientes do
  /// cuidador — pra refletir o que foi alterado no outro app sem precisar
  /// puxar a tela. Roda a cada 30 s e ao voltar pro app. Falha de rede é
  /// ignorada (tenta de novo na próxima).
  Future<void> sincronizarDados() async {
    final atual = usuario;
    if (atual == null || _sincronizando) return;
    _sincronizando = true;
    try {
      if (atual.tipo == 'paciente') {
        final dados = await _hidratarPaciente(await _pacienteServico.buscarPorId(atual.id));
        if (usuario?.id != atual.id) return; // saiu/trocou de conta no meio
        pacientes = [dados];
      } else {
        final lista = await _pacienteServico.listarPorCuidador(atual.id);
        final hidratados = await Future.wait(lista.map(_hidratarPaciente));
        if (usuario?.id != atual.id) return;
        pacientes = hidratados;
        if (pacienteFocoId != null && !pacientes.any((p) => p.paciente.id == pacienteFocoId)) {
          pacienteFocoId = null; // paciente foi desvinculado em outro lugar
        }
      }
      notifyListeners();
    } catch (_) {
      // sem rede agora: mantém o que já está na tela
    } finally {
      _sincronizando = false;
    }
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  final AuthServico _authServico = AuthServico();
  final PacienteServico _pacienteServico = PacienteServico();
  final CuidadorServico _cuidadorServico = CuidadorServico();
  final MedicamentoServico _medicamentoServico = MedicamentoServico();
  final HistoricoServico _historicoServico = HistoricoServico();

  UsuarioLogado? usuario;
  List<PacienteComDados> pacientes = [];
  int? pacienteFocoId;
  bool carregandoSessao = true;
  String tamanhoFonte = 'media';

  double get escalaFonte => escalaPorTamanhoFonte[tamanhoFonte] ?? 1.0;

  bool get autenticado => usuario != null;

  PacienteComDados? get pacienteFoco {
    if (pacienteFocoId == null) return null;
    try {
      return pacientes.firstWhere((p) => p.paciente.id == pacienteFocoId);
    } catch (_) {
      return null;
    }
  }

  AppEstado() {
    ApiCliente.instancia.aoSessaoExpirar = _aoSessaoExpirar;
  }

  /// Aviso para a tela de login quando a sessão acabou sozinha (token vencido).
  String? avisoSessao;

  /// Lê e apaga o aviso (a tela de login mostra uma vez só).
  String? consumirAvisoSessao() {
    final aviso = avisoSessao;
    avisoSessao = null;
    return aviso;
  }

  void _aoSessaoExpirar() {
    if (usuario == null) return;
    avisoSessao = 'Sua sessão expirou. Entre novamente.';
    sair();
  }

  Future<void> restaurarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final fonteSalva = prefs.getString(_chaveTamanhoFonte);
    if (fonteSalva != null && escalaPorTamanhoFonte.containsKey(fonteSalva)) tamanhoFonte = fonteSalva;
    final id = prefs.getInt(_chaveId);
    final tipo = prefs.getString(_chaveTipo);
    final token = prefs.getString(_chaveToken);
    // Sessões antigas (de antes do login com token) não têm token: pedem login de novo.
    if (id != null && tipo != null && token != null) {
      ApiCliente.instancia.token = token;
      try {
        await _carregarAposLogin(tipo, id);
      } catch (_) {
        await _apagarSessaoSalva(prefs);
      }
    } else {
      await _apagarSessaoSalva(prefs);
    }
    carregandoSessao = false;
    notifyListeners();
  }

  Future<void> entrar(String email, String senha) async {
    final login = await _authServico.login(email, senha);
    ApiCliente.instancia.token = login.token;
    try {
      await _carregarAposLogin(login.tipo, login.id);
    } catch (_) {
      ApiCliente.instancia.token = null;
      rethrow;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chaveId, login.id);
    await prefs.setString(_chaveTipo, login.tipo);
    await prefs.setString(_chaveToken, login.token);
  }

  Future<void> _apagarSessaoSalva(SharedPreferences prefs) async {
    ApiCliente.instancia.token = null;
    await prefs.remove(_chaveId);
    await prefs.remove(_chaveTipo);
    await prefs.remove(_chaveToken);
  }

  Future<void> cadastrar({
    required String tipo, // 'paciente' | 'cuidador'
    required String nome,
    required String email,
    required String senha,
    String? dataNascimentoIso,
    String? sexo,
    String? telefone,
    String? endereco,
    String? profissao,
  }) async {
    if (tipo == 'paciente') {
      await _pacienteServico.criar(
        nome: nome,
        email: email,
        senha: senha,
        dataNascimento: dataNascimentoIso != null ? DateTime.parse(dataNascimentoIso) : null,
        sexo: sexo,
        telefone: telefone,
        endereco: endereco,
      );
    } else {
      await _cuidadorServico.criar(nome: nome, email: email, senha: senha, profissao: profissao, telefone: telefone);
    }
    // Depois de criar a conta, entra com o mesmo e-mail e senha (é o login que gera o token).
    await entrar(email, senha);
  }

  Future<void> _carregarAposLogin(String tipo, int id) async {
    if (tipo == 'PACIENTE') {
      final paciente = await _pacienteServico.buscarPorId(id);
      final dados = await _hidratarPaciente(paciente);
      pacientes = [dados];
      pacienteFocoId = paciente.id;
      usuario = UsuarioLogado(id: paciente.id, nome: paciente.nome, email: paciente.email, tipo: 'paciente');
    } else {
      final cuidador = await _cuidadorServico.buscarPorId(id);
      final listaPacientes = await _pacienteServico.listarPorCuidador(id);
      pacientes = await Future.wait(listaPacientes.map(_hidratarPaciente));
      pacienteFocoId = null;
      usuario = _usuarioDeCuidador(cuidador);
    }
    iniciarRelogio();
    notifyListeners();
  }

  UsuarioLogado _usuarioDeCuidador(Cuidador cuidador) => UsuarioLogado(
        id: cuidador.id,
        nome: cuidador.nome,
        email: cuidador.email,
        tipo: 'cuidador',
        profissao: cuidador.profissao,
        telefone: cuidador.telefone,
      );

  Future<PacienteComDados> _hidratarPaciente(Paciente paciente) async {
    final medicamentos = await _medicamentoServico.listarPorPaciente(paciente.id);
    final historico = await _historicoServico.listarPorPaciente(paciente.id);
    return PacienteComDados(paciente: paciente, medicamentos: medicamentos, historico: historico);
  }

  Future<void> recarregarPaciente(int pacienteId) async {
    final paciente = await _pacienteServico.buscarPorId(pacienteId);
    final dados = await _hidratarPaciente(paciente);
    final indice = pacientes.indexWhere((p) => p.paciente.id == pacienteId);
    if (indice >= 0) {
      pacientes[indice] = dados;
    } else {
      pacientes.add(dados);
    }
    notifyListeners();
  }

  Future<void> adicionarMedicamento(int pacienteId, Medicamento medicamento) async {
    await _medicamentoServico.criar(medicamento);
    await recarregarPaciente(pacienteId);
  }

  Future<void> editarMedicamento(int pacienteId, int medicamentoId, Medicamento medicamento) async {
    await _medicamentoServico.atualizar(medicamentoId, medicamento);
    await recarregarPaciente(pacienteId);
  }

  Future<void> excluirMedicamento(int pacienteId, int medicamentoId) async {
    await _medicamentoServico.excluir(medicamentoId);
    await recarregarPaciente(pacienteId);
  }

  void selecionarPaciente(int id) {
    pacienteFocoId = id;
    notifyListeners();
  }

  Future<void> marcarDoseComoTomada(int pacienteId, int medicamentoId, String horario, String statusAtual) async {
    final statusFinal = statusAtual == 'perdido' ? 'PERDIDO' : 'TOMADO';
    await _historicoServico.criar(
      pacienteId: pacienteId,
      medicamentoId: medicamentoId,
      data: DateTime.now(),
      hora: horario,
      status: statusFinal,
    );
    await recarregarPaciente(pacienteId);
  }

  /// Paciente: [sexo] vem no rótulo da tela ('Feminino'...) e é convertido
  /// pro enum da API. Campos que a tela não edita (enfermidade, observações,
  /// cuidador) são reenviados como estão, porque o PUT substitui tudo.
  Future<void> atualizarPerfil({
    required String nome,
    required String email,
    DateTime? dataNascimento,
    String? sexo,
    String? telefone,
    String? endereco,
    String? profissao,
  }) async {
    final atual = usuario!;
    String? vazioParaNulo(String? v) => (v == null || v.isEmpty) ? null : v;
    if (atual.tipo == 'paciente') {
      final paciente = pacienteFoco?.paciente;
      await _pacienteServico.atualizar(atual.id, {
        'nome': nome,
        'email': email,
        'dataNascimento': dataNascimento != null ? dataAtualISO(dataNascimento) : null,
        'sexo': sexo != null ? sexoParaApi[sexo] : null,
        'enfermidade': paciente?.enfermidade,
        'telefone': vazioParaNulo(telefone),
        'endereco': vazioParaNulo(endereco),
        'observacoesClinicas': paciente?.observacoesClinicas,
        'cuidadorId': paciente?.cuidadorId,
      });
      usuario = UsuarioLogado(id: atual.id, nome: nome, email: email, tipo: 'paciente');
      await recarregarPaciente(atual.id);
    } else {
      final cuidador = await _cuidadorServico.atualizar(atual.id, {
        'nome': nome,
        'email': email,
        'profissao': vazioParaNulo(profissao),
        'telefone': vazioParaNulo(telefone),
      });
      usuario = _usuarioDeCuidador(cuidador);
      notifyListeners();
    }
  }

  Future<void> alterarSenha(String senhaAtual, String novaSenha) {
    final atual = usuario!;
    return atual.tipo == 'paciente'
        ? _pacienteServico.alterarSenha(atual.id, senhaAtual, novaSenha)
        : _cuidadorServico.alterarSenha(atual.id, senhaAtual, novaSenha);
  }

  Future<void> solicitarVinculoCuidador(String cuidadorEmail) async {
    await _pacienteServico.solicitarVinculo(usuario!.id, cuidadorEmail);
    await recarregarPaciente(usuario!.id);
  }

  /// Cuidador cadastra um paciente já vinculado a ele, sem senha — igual ao
  /// cadastrarPaciente do web. O paciente depois cria a própria senha em
  /// "Ativar meu acesso" (tela Definir senha).
  Future<void> cadastrarPacienteDoCuidador({
    required String nome,
    required String email,
    DateTime? dataNascimento,
    String? sexo, // rótulo da tela: 'Feminino' | 'Masculino' | 'Outro'
    String? enfermidade,
    String? telefone,
    String? endereco,
  }) async {
    String? vazioParaNulo(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    final novo = await _pacienteServico.criar(
      nome: nome,
      email: email,
      dataNascimento: dataNascimento,
      sexo: sexo != null ? sexoParaApi[sexo] : null,
      enfermidade: vazioParaNulo(enfermidade),
      telefone: vazioParaNulo(telefone),
      endereco: vazioParaNulo(endereco),
      cuidadorId: usuario!.id,
    );
    await recarregarPaciente(novo.id);
  }

  /// Salva só as observações clínicas: busca o paciente atual no servidor e
  /// reenvia todos os campos como estão (o PUT substitui tudo), trocando apenas
  /// as observações — assim nada que foi alterado em outro lugar é apagado.
  Future<void> atualizarObservacoesClinicas(int pacienteId, String texto) async {
    final atual = await _pacienteServico.buscarPorId(pacienteId);
    final limpo = texto.trim();
    await _pacienteServico.atualizar(pacienteId, {
      'nome': atual.nome,
      'email': atual.email,
      'dataNascimento': atual.dataNascimento != null ? dataAtualISO(atual.dataNascimento) : null,
      'sexo': atual.sexo,
      'enfermidade': atual.enfermidade,
      'telefone': atual.telefone,
      'endereco': atual.endereco,
      'observacoesClinicas': limpo.isEmpty ? null : limpo,
      'cuidadorId': atual.cuidadorId,
    });
    await recarregarPaciente(pacienteId);
  }

  Future<void> atualizarPermissaoAlteracoes(int pacienteId, bool permite) async {
    await _pacienteServico.atualizarPermissaoAlteracoes(pacienteId, usuario!.id, permite);
    await recarregarPaciente(pacienteId);
  }

  Future<void> desvincularPaciente(int pacienteId) async {
    await _pacienteServico.desvincularCuidador(pacienteId, usuario!.id);
    pacientes = pacientes.where((p) => p.paciente.id != pacienteId).toList();
    if (pacienteFocoId == pacienteId) pacienteFocoId = null;
    notifyListeners();
  }

  Future<Cuidador> buscarCuidador(int id) => _cuidadorServico.buscarPorId(id);

  Future<void> definirTamanhoFonte(String tamanho) async {
    if (!escalaPorTamanhoFonte.containsKey(tamanho)) return;
    tamanhoFonte = tamanho;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveTamanhoFonte, tamanho);
  }

  Future<void> sair() async {
    final prefs = await SharedPreferences.getInstance();
    await _apagarSessaoSalva(prefs);
    usuario = null;
    pacientes = [];
    pacienteFocoId = null;
    _relogio?.cancel();
    _relogio = null;
    notifyListeners();
  }
}
