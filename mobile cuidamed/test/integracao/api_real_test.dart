import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/estado/monitor_alertas.dart';
import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/utilitarios/horarios.dart';
import 'package:cuidamed_mobile/servicos/api_cliente.dart';
import 'package:cuidamed_mobile/servicos/auth_servico.dart';
import 'package:cuidamed_mobile/servicos/chat_servico.dart';
import 'package:cuidamed_mobile/servicos/cuidador_servico.dart';
import 'package:cuidamed_mobile/servicos/paciente_servico.dart';

const _url = String.fromEnvironment('API_BASE_URL');

Future<void> _como(String email, String senha) async {
  ApiCliente.instancia.token = (await AuthServico().login(email, senha)).token;
}

String _fone(int carimbo, int n) {
  final oito = ((carimbo % 10000000) * 10 + n).toString().padLeft(8, '0');
  return '(79) 9${oito.substring(0, 4)}-${oito.substring(4)}';
}

void main() {
  final carimbo = DateTime.now().millisecondsSinceEpoch;
  final emailPaciente = 'paciente.integracao.$carimbo@email.com';
  final emailCuidador = 'cuidador.integracao.$carimbo@email.com';
  late int pacienteId;
  late int cuidadorId;

  setUpAll(() async {
    if (_url.isEmpty) return;
    SharedPreferences.setMockInitialValues({});
    final cuidador = await CuidadorServico().criar(
      nome: 'Cuidador Teste Integração',
      email: emailCuidador,
      senha: 'senha1234',
      profissao: 'Enfermeiro',
    );
    cuidadorId = cuidador.id;
  });

  tearDownAll(() async {
    if (_url.isEmpty) return;
    try {
      await _como(emailPaciente, 'novaSenha99');
      await PacienteServico().excluir(pacienteId);
    } catch (_) {}
  });

  test('Paciente: cadastro, edição de perfil e troca de senha', () async {
    final estado = AppEstado();
    await estado.cadastrar(tipo: 'paciente', nome: 'Paciente Teste Integração', email: emailPaciente, senha: 'senha1234');
    pacienteId = estado.usuario!.id;

    await estado.atualizarPerfil(
      nome: 'Paciente Integração Editado',
      email: emailPaciente,
      dataNascimento: DateTime(1948, 7, 2),
      sexo: 'Masculino',
      telefone: _fone(carimbo, 1),
      endereco: 'Rua Teste, 1',
    );
    final paciente = estado.pacienteFoco!.paciente;
    expect(estado.usuario!.nome, 'Paciente Integração Editado');
    expect(paciente.nome, 'Paciente Integração Editado');
    expect(paciente.sexo, 'MASCULINO');
    expect(paciente.telefone, _fone(carimbo, 1));
    expect(paciente.dataNascimento, DateTime(1948, 7, 2));

    await expectLater(estado.alterarSenha('senha-errada', 'novaSenha99'), throwsA(isA<ApiExcecao>()));
    await estado.alterarSenha('senha1234', 'novaSenha99');
    final login = await AuthServico().login(emailPaciente, 'novaSenha99');
    expect(login.id, pacienteId);
    expect(login.token, isNotEmpty);
  }, skip: _url.isEmpty ? 'defina --dart-define=API_BASE_URL' : null);

  test('Vínculo: paciente solicita, cuidador aceita, altera permissão e desvincula', () async {
    final estadoPaciente = AppEstado();
    await estadoPaciente.entrar(emailPaciente, 'novaSenha99');
    await estadoPaciente.solicitarVinculoCuidador(emailCuidador);
    expect(estadoPaciente.pacienteFoco!.paciente.cuidadorSolicitadoId, cuidadorId);

    await _como(emailCuidador, 'senha1234');
    await PacienteServico().aceitarVinculo(pacienteId, cuidadorId);

    final estadoCuidador = AppEstado();
    await estadoCuidador.entrar(emailCuidador, 'senha1234');
    expect(estadoCuidador.usuario!.profissao, 'Enfermeiro');
    expect(estadoCuidador.pacientes.map((p) => p.paciente.id), contains(pacienteId));
    final codigo = estadoCuidador.pacientes.firstWhere((p) => p.paciente.id == pacienteId).paciente.codigoVinculo;
    expect(codigo, isNotNull);
    await _como(emailPaciente, 'novaSenha99');
    expect((await PacienteServico().buscarPorId(pacienteId)).codigoVinculo, codigo);
    await _como(emailCuidador, 'senha1234');

    await estadoCuidador.atualizarPerfil(
      nome: 'Cuidador Teste Integração',
      email: emailCuidador,
      profissao: 'Médica',
      telefone: _fone(carimbo, 2),
    );
    expect(estadoCuidador.usuario!.profissao, 'Médica');
    expect((await CuidadorServico().buscarPorId(cuidadorId)).telefone, _fone(carimbo, 2));

    await estadoCuidador.atualizarPermissaoAlteracoes(pacienteId, true);
    expect(estadoCuidador.pacientes.firstWhere((p) => p.paciente.id == pacienteId).paciente.permiteAlteracoes, isTrue);

    await estadoCuidador.desvincularPaciente(pacienteId);
    expect(estadoCuidador.pacientes.where((p) => p.paciente.id == pacienteId), isEmpty);
    await expectLater(
      PacienteServico().buscarPorId(pacienteId),
      throwsA(isA<ApiExcecao>().having((e) => e.mensagem, 'mensagem', contains('não tem acesso'))),
    );
    await _como(emailPaciente, 'novaSenha99');
    final desvinculado = await PacienteServico().buscarPorId(pacienteId);
    expect(desvinculado.cuidadorId, isNull);
    expect(desvinculado.codigoVinculo, isNull);
  }, skip: _url.isEmpty ? 'defina --dart-define=API_BASE_URL' : null);

  test('Cuidador cadastra paciente sem senha e o paciente ativa o acesso', () async {
    final estadoCuidador = AppEstado();
    await estadoCuidador.entrar(emailCuidador, 'senha1234');
    final emailNovo = 'paciente.semsenha.$carimbo@email.com';
    await estadoCuidador.cadastrarPacienteDoCuidador(
      nome: 'Paciente Sem Senha Teste',
      email: emailNovo,
      dataNascimento: DateTime(1945, 5, 20),
      sexo: 'Feminino',
      enfermidade: 'Hipertensão',
      telefone: _fone(carimbo, 3),
      endereco: 'Rua Teste, 2',
    );
    final novo = estadoCuidador.pacientes.firstWhere((p) => p.paciente.email == emailNovo).paciente;
    try {
      expect(novo.cuidadorId, cuidadorId);
      expect(novo.sexo, 'FEMININO');
      expect(novo.enfermidade, 'Hipertensão');
      await expectLater(AuthServico().login(emailNovo, 'qualquer123'), throwsA(isA<ApiExcecao>()));
      final codigo = novo.codigoAtivacao!;
      expect(codigo, hasLength(6));
      await expectLater(
        ApiCliente.instancia.post('/api/pacientes/definir-senha', {'email': emailNovo, 'novaSenha': 'minhasenha1'}),
        throwsA(isA<ApiExcecao>().having((e) => e.mensagem, 'mensagem', contains('código de ativação'))),
      );
      await expectLater(
        ApiCliente.instancia.post('/api/pacientes/definir-senha', {'email': emailNovo, 'codigo': 'ERRADO', 'novaSenha': 'minhasenha1'}),
        throwsA(isA<ApiExcecao>()),
      );
      await ApiCliente.instancia.post('/api/pacientes/definir-senha',
          {'email': emailNovo, 'codigo': codigo.toLowerCase(), 'novaSenha': 'minhasenha1'});
      expect((await AuthServico().login(emailNovo, 'minhasenha1')).id, novo.id);
      expect((await PacienteServico().buscarPorId(novo.id)).codigoAtivacao, isNull);
      await expectLater(
        ApiCliente.instancia.post('/api/pacientes/definir-senha', {'email': emailNovo, 'codigo': codigo, 'novaSenha': 'outra12345'}),
        throwsA(isA<ApiExcecao>()),
      );
    } finally {
      await PacienteServico().excluir(novo.id);
    }
  }, skip: _url.isEmpty ? 'defina --dart-define=API_BASE_URL' : null);

  test('"Lembrar agora": cuidador envia e o app do paciente recebe e confirma', () async {
    final estadoCuidador = AppEstado();
    await estadoCuidador.entrar(emailCuidador, 'senha1234');
    final emailAlerta = 'paciente.alerta.$carimbo@email.com';
    await estadoCuidador.cadastrarPacienteDoCuidador(nome: 'Paciente Alerta Teste', email: emailAlerta);
    final novo = estadoCuidador.pacientes.firstWhere((p) => p.paciente.email == emailAlerta).paciente;
    MonitorAlertas? monitor;
    try {
      await ApiCliente.instancia.post(
          '/api/pacientes/definir-senha', {'email': emailAlerta, 'codigo': novo.codigoAtivacao, 'novaSenha': 'alerta1234'});
      final estadoPaciente = AppEstado();
      await estadoPaciente.entrar(emailAlerta, 'alerta1234');

      final recebidos = <AlertaPaciente>[];
      final servico = PacienteServico();
      monitor = MonitorAlertas(
        estado: estadoPaciente,
        buscarPaciente: servico.buscarPorId,
        confirmarAlertaManual: servico.confirmarAlertaManual,
        aoAlertar: recebidos.add,
        agora: () => DateTime(2000, 1, 1, 3),
      );
      await monitor.verificarAgora();
      expect(recebidos, isEmpty);

      await _como(emailCuidador, 'senha1234');
      await servico.enviarAlertaManual(novo.id, cuidadorId, 'Hora do remédio, vó!');
      expect((await servico.buscarPorId(novo.id)).alertaManualPendente, isTrue);

      await _como(emailAlerta, 'alerta1234');
      await monitor.verificarAgora();
      expect(recebidos.single.titulo, 'Lembrete do seu cuidador 💊');
      expect(recebidos.single.mensagem, 'Hora do remédio, vó!');
      expect((await servico.buscarPorId(novo.id)).alertaManualPendente, isFalse);

      await monitor.verificarAgora();
      expect(recebidos, hasLength(1));
    } finally {
      monitor?.dispose();
      await PacienteServico().excluir(novo.id);
    }
  }, skip: _url.isEmpty ? 'defina --dart-define=API_BASE_URL' : null);

  test('Sincronismo: o que um app altera aparece no outro sem novo login', () async {
    final estadoCuidador = AppEstado();
    await estadoCuidador.entrar(emailCuidador, 'senha1234');
    final emailSync = 'paciente.sync.$carimbo@email.com';
    await estadoCuidador.cadastrarPacienteDoCuidador(nome: 'Paciente Sync Teste', email: emailSync);
    final novo = estadoCuidador.pacientes.firstWhere((p) => p.paciente.email == emailSync).paciente;
    try {
      await ApiCliente.instancia.post(
          '/api/pacientes/definir-senha', {'email': emailSync, 'codigo': novo.codigoAtivacao, 'novaSenha': 'sync12345'});
      final estadoPaciente = AppEstado();
      await estadoPaciente.entrar(emailSync, 'sync12345');
      expect(estadoPaciente.pacienteFoco!.medicamentos, isEmpty);

      final hoje = DateTime.now();
      await _como(emailCuidador, 'senha1234');
      await estadoCuidador.adicionarMedicamento(
        novo.id,
        Medicamento(
          id: 0, pacienteId: novo.id, nome: 'Sincronil', dosagem: '5mg', forma: 'COMPRIMIDO',
          frequencia: 'UMA_VEZ_AO_DIA', dataInicio: DateTime(hoje.year, hoje.month, hoje.day),
          horarios: const ['23:59'], quantidadeEstoque: 10, quantidadePorDose: 1,
        ),
      );
      await _como(emailSync, 'sync12345');
      await estadoPaciente.sincronizarDados();
      final remedio = estadoPaciente.pacienteFoco!.medicamentos.single;
      expect(remedio.nome, 'Sincronil');

      await estadoPaciente.marcarDoseComoTomada(novo.id, remedio.id, '23:59', 'pendente');
      await _como(emailCuidador, 'senha1234');
      await estadoCuidador.sincronizarDados();
      final visto = estadoCuidador.pacientes.firstWhere((p) => p.paciente.id == novo.id);
      expect(visto.historico.single.status, 'TOMADO');
      expect(visto.medicamentos.single.quantidadeEstoque, 9);
    } finally {
      await PacienteServico().excluir(novo.id);
    }
  }, skip: _url.isEmpty ? 'defina --dart-define=API_BASE_URL' : null);

  test('Frequência: back-end recusa dose em dia sem dose (semanal)', () async {
    final estadoCuidador = AppEstado();
    await estadoCuidador.entrar(emailCuidador, 'senha1234');
    final emailFreq = 'paciente.freq.$carimbo@email.com';
    await estadoCuidador.cadastrarPacienteDoCuidador(nome: 'Paciente Freq Teste', email: emailFreq);
    final novo = estadoCuidador.pacientes.firstWhere((p) => p.paciente.email == emailFreq).paciente;
    try {
      final hoje = DateTime.now();
      final ontem = DateTime(hoje.year, hoje.month, hoje.day).subtract(const Duration(days: 1));
      await estadoCuidador.adicionarMedicamento(
        novo.id,
        Medicamento(
          id: 0, pacienteId: novo.id, nome: 'Semanalina', dosagem: '5mg', forma: 'COMPRIMIDO',
          frequencia: 'SEMANAL', dataInicio: ontem, horarios: const ['09:00'],
          quantidadeEstoque: 10, quantidadePorDose: 1,
        ),
      );
      final med = estadoCuidador.pacientes.firstWhere((p) => p.paciente.id == novo.id).medicamentos.single;
      await expectLater(
        estadoCuidador.marcarDoseComoTomada(novo.id, med.id, '09:00', 'pendente'),
        throwsA(isA<ApiExcecao>().having((e) => e.mensagem, 'mensagem', contains('não tem dose'))),
      );
      expect(construirDosesHoje([med], const []), isEmpty);
    } finally {
      await PacienteServico().excluir(novo.id);
    }
  }, skip: _url.isEmpty ? 'defina --dart-define=API_BASE_URL' : null);

  test('Observações clínicas: salvar não altera os outros dados do paciente', () async {
    final estadoCuidador = AppEstado();
    await estadoCuidador.entrar(emailCuidador, 'senha1234');
    final emailObs = 'paciente.obs.$carimbo@email.com';
    await estadoCuidador.cadastrarPacienteDoCuidador(
      nome: 'Paciente Obs Teste', email: emailObs, dataNascimento: DateTime(1940, 2, 3), sexo: 'Masculino',
      enfermidade: 'Diabetes', telefone: _fone(carimbo, 4), endereco: 'Rua das Flores, 1',
    );
    final antes = estadoCuidador.pacientes.firstWhere((p) => p.paciente.email == emailObs).paciente;
    try {
      await estadoCuidador.atualizarObservacoesClinicas(antes.id, '  Alergia a dipirona.  ');
      final depois = await PacienteServico().buscarPorId(antes.id);
      expect(depois.observacoesClinicas, 'Alergia a dipirona.');
      expect(depois.nome, antes.nome);
      expect(depois.email, antes.email);
      expect(depois.dataNascimento, antes.dataNascimento);
      expect(depois.sexo, 'MASCULINO');
      expect(depois.enfermidade, 'Diabetes');
      expect(depois.telefone, antes.telefone);
      expect(depois.endereco, antes.endereco);
      expect(depois.cuidadorId, cuidadorId);
      expect(estadoCuidador.pacientes.firstWhere((p) => p.paciente.id == antes.id).paciente.observacoesClinicas,
          'Alergia a dipirona.');
      await estadoCuidador.atualizarObservacoesClinicas(antes.id, '   ');
      expect((await PacienteServico().buscarPorId(antes.id)).observacoesClinicas, isNull);
    } finally {
      await PacienteServico().excluir(antes.id);
    }
  }, skip: _url.isEmpty ? 'defina --dart-define=API_BASE_URL' : null);

  test('Segurança: sem token ou com token inválido a API recusa; paciente não vê outro paciente', () async {
    ApiCliente.instancia.token = null;
    await expectLater(
      PacienteServico().buscarPorId(pacienteId),
      throwsA(isA<ApiExcecao>().having((e) => e.mensagem, 'mensagem', contains('sessão expirou'))),
    );
    ApiCliente.instancia.token = 'token.falso.qualquer';
    await expectLater(PacienteServico().buscarPorId(pacienteId), throwsA(isA<ApiExcecao>()));

    final emailOutro = 'paciente.outro.$carimbo@email.com';
    ApiCliente.instancia.token = null;
    await ApiCliente.instancia.post('/api/pacientes', {'nome': 'Outro Paciente', 'email': emailOutro, 'senha': 'outro1234'});
    await _como(emailOutro, 'outro1234');
    try {
      await expectLater(PacienteServico().buscarPorId(pacienteId), throwsA(isA<ApiExcecao>()));
      await expectLater(ChatServico().perguntar(pacienteId, 'oi'), throwsA(isA<ApiExcecao>()));
    } finally {
      final outro = await AuthServico().login(emailOutro, 'outro1234');
      await PacienteServico().excluir(outro.id);
    }
  }, skip: _url.isEmpty ? 'defina --dart-define=API_BASE_URL' : null);

  test('Chat responde sobre o paciente', () async {
    await _como(emailPaciente, 'novaSenha99');
    final resposta = await ChatServico().perguntar(pacienteId, 'Quais remédios eu preciso tomar?');
    expect(resposta.trim(), isNotEmpty);
    // ignore: avoid_print
    print('Chat respondeu: ${resposta.length > 120 ? '${resposta.substring(0, 120)}…' : resposta}');
  }, skip: _url.isEmpty ? 'defina --dart-define=API_BASE_URL' : null, timeout: const Timeout(Duration(seconds: 60)));

}
