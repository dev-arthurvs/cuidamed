import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/estado/monitor_alertas.dart';
import 'package:cuidamed_mobile/modelos/paciente.dart';

import 'apoio.dart';

Paciente _paciente({bool pendente = false, String? mensagem}) => Paciente(
      id: 1,
      nome: 'Maria da Silva',
      email: 'maria@email.com',
      alertaManualPendente: pendente,
      alertaManualMensagem: mensagem,
    );

class _ApiFalsa {
  Paciente resposta = _paciente();
  int buscas = 0;
  final List<int> confirmados = [];
  bool falhar = false;

  Future<Paciente> buscar(int id) async {
    buscas++;
    if (falhar) throw Exception('sem rede');
    return resposta;
  }

  Future<void> confirmar(int id) async {
    confirmados.add(id);
    resposta = _paciente(); // o servidor limpa o pendente ao confirmar
  }
}

void main() {
  late _ApiFalsa api;
  late List<AlertaPaciente> alertas;

  setUp(() {
    api = _ApiFalsa();
    alertas = [];
  });

  MonitorAlertas criar(estado, {DateTime Function()? agora}) => MonitorAlertas(
        estado: estado,
        buscarPaciente: api.buscar,
        confirmarAlertaManual: api.confirmar,
        aoAlertar: alertas.add,
        agora: agora ?? () => DateTime(2000, 1, 1, 3, 0), // madrugada: nenhuma dose no horário
      );

  testWidgets('Liga só para paciente e desliga ao sair', (tester) async {
    final cuidador = estadoCuidador();
    final monitorCuidador = criar(cuidador);
    expect(monitorCuidador.ativo, isFalse);
    monitorCuidador.dispose();

    final paciente = estadoPaciente();
    final monitor = criar(paciente);
    expect(monitor.ativo, isTrue);
    await tester.pump();
    expect(api.buscas, 1); // verifica logo ao entrar, sem esperar 30 s

    await tester.pump(const Duration(seconds: 30));
    expect(api.buscas, 2);

    paciente.usuario = null;
    paciente.notifyListeners();
    expect(monitor.ativo, isFalse);
    await tester.pump(const Duration(seconds: 60));
    expect(api.buscas, 2);
    monitor.dispose();
  });

  testWidgets('"Lembrar agora": avisa uma vez com a mensagem do cuidador e confirma', (tester) async {
    final monitor = criar(estadoPaciente());
    await tester.pump();
    expect(alertas, isEmpty);

    api.resposta = _paciente(pendente: true, mensagem: 'Tome o remédio da pressão, mãe!');
    await tester.pump(const Duration(seconds: 30));
    expect(alertas.single.titulo, 'Lembrete do seu cuidador 💊');
    expect(alertas.single.mensagem, 'Tome o remédio da pressão, mãe!');
    expect(api.confirmados, [1]);

    await tester.pump(const Duration(seconds: 30)); // já confirmado: não repete
    expect(alertas, hasLength(1));
    monitor.dispose();
  });

  testWidgets('"Lembrar agora" sem mensagem usa o texto padrão do web', (tester) async {
    api.resposta = _paciente(pendente: true);
    final monitor = criar(estadoPaciente());
    await tester.pump();
    expect(alertas.single.mensagem, MonitorAlertas.mensagemPadraoCuidador);
    monitor.dispose();
  });

  testWidgets('"Hora do remédio" avisa no horário da dose, uma única vez', (tester) async {
    final hoje = DateTime.now();
    var agora = DateTime(hoje.year, hoje.month, hoje.day, 20, 0, 5); // Losartana 20:00 (não tomada)
    final monitor = criar(estadoPaciente(), agora: () => agora);
    await tester.pump();
    expect(alertas.where((a) => a.titulo == 'Hora do remédio 💊').single.mensagem,
        'Está na hora de tomar Losartana (50mg).');

    agora = agora.add(const Duration(seconds: 30)); // ainda 20:00 — não repete
    await tester.pump(const Duration(seconds: 30));
    expect(alertas, hasLength(1));

    // A dose das 08:00 já está marcada como tomada no histórico: nunca avisa.
    agora = DateTime(hoje.year, hoje.month, hoje.day, 8, 0, 10);
    await tester.pump(const Duration(seconds: 30));
    expect(alertas, hasLength(1));
    monitor.dispose();
  });

  testWidgets('Falha de rede não derruba nem gera aviso', (tester) async {
    api.falhar = true;
    final monitor = criar(estadoPaciente());
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(alertas, isEmpty);
    expect(api.buscas, 2);

    api.falhar = false;
    api.resposta = _paciente(pendente: true);
    await tester.pump(const Duration(seconds: 30));
    expect(alertas, hasLength(1)); // volta a funcionar quando a rede volta
    monitor.dispose();
  });
}
