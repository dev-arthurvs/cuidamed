import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cuidamed_mobile/componentes/barra_navegacao_inferior.dart';
import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/estado/lembretes_agendados.dart';
import 'package:cuidamed_mobile/estado/monitor_alertas.dart';
import 'package:cuidamed_mobile/modelos/historico.dart';
import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/modelos/paciente.dart';
import 'package:cuidamed_mobile/paginas/definir_senha.dart';
import 'package:cuidamed_mobile/paginas/detalhe_paciente.dart';
import 'package:cuidamed_mobile/paginas/historico.dart';
import 'package:cuidamed_mobile/paginas/painel_idoso.dart';
import 'package:cuidamed_mobile/servicos/relatorio_pdf.dart';
import 'package:cuidamed_mobile/utilitarios/horarios.dart';

import 'apoio.dart';

Medicamento _med({
  int id = 1,
  String nome = 'Remédio',
  List<String> horarios = const ['08:00'],
  required DateTime inicio,
  DateTime? fim,
  String frequencia = 'UMA_VEZ_AO_DIA',
  int? estoque = 30,
}) =>
    Medicamento(
      id: id,
      pacienteId: 1,
      nome: nome,
      dosagem: '',
      forma: 'COMPRIMIDO',
      frequencia: frequencia,
      dataInicio: inicio,
      dataFim: fim,
      horarios: horarios,
      quantidadeEstoque: estoque,
      quantidadePorDose: 1,
    );

Historico _registro(int medicamentoId, DateTime dia, String hora, String status) => Historico(
      id: 7,
      pacienteId: 1,
      medicamentoId: medicamentoId,
      data: dia,
      hora: hora,
      nomeMedicamento: 'Remédio',
      dosagem: '',
      status: status,
    );

AppEstado _comRemedios(AppEstado estado, List<Medicamento> medicamentos, {List<Historico> historico = const []}) {
  final dados = estado.pacientes.first;
  estado.pacientes = [PacienteComDados(paciente: dados.paciente, medicamentos: medicamentos, historico: historico)];
  return estado;
}

void main() {
  final hoje = DateTime.now();
  final diaHoje = DateTime(hoje.year, hoje.month, hoje.day);

  group('Lembretes agendados (app fechado)', () {
    final agora = DateTime(2026, 11, 2, 14, 0);
    final dia = DateTime(2026, 11, 2);

    test('Agenda as doses futuras, em ordem, sem as que já passaram ou foram registradas', () {
      final lembretes = lembretesParaAgendar(
        [
          _med(id: 1, nome: 'A', horarios: const ['08:00', '20:00'], inicio: dia),
          _med(id: 2, nome: 'B', horarios: const ['15:00', '18:00'], inicio: dia, fim: dia),
        ],
        [_registro(2, dia, '18:00', 'TOMADO')],
        agora: agora,
        dias: 2,
      );
      expect(lembretes.map((l) => l.quando), [
        DateTime(2026, 11, 2, 15, 0), // B hoje
        DateTime(2026, 11, 2, 20, 0), // A hoje; 08:00 já passou e 18:00 foi registrada
        DateTime(2026, 11, 3, 8, 0), // A amanhã (B terminou hoje)
        DateTime(2026, 11, 3, 20, 0),
      ]);
      expect(lembretes.first.corpo, 'Está na hora de tomar B.');
      expect(lembretes.map((l) => l.id).toSet(), hasLength(4));
    });

    test('Respeita o limite e os dias sem dose', () {
      final muitos = lembretesParaAgendar(
        [_med(horarios: const ['00:30', '06:00', '12:00', '18:00', '23:00'], inicio: dia)],
        const [],
        agora: agora,
        dias: 30,
        limite: 60,
      );
      expect(muitos, hasLength(60));

      final alternados = lembretesParaAgendar(
        [_med(frequencia: 'DIAS_ALTERNADOS', horarios: const ['20:00'], inicio: dia)],
        const [],
        agora: agora,
        dias: 5,
      );
      expect(alternados.map((l) => l.quando.day), [2, 4, 6]);
    });

    test('Agenda para o paciente logado, reagenda ao mudar e cancela ao sair', () async {
      SharedPreferences.setMockInitialValues({});
      final amanha = diaHoje.add(const Duration(days: 1));
      final estado = _comRemedios(estadoPaciente(), [_med(inicio: amanha)]);
      final agendamentos = <int>[];
      var cancelamentos = 0;
      final lembretes = LembretesAgendados(
        estado: estado,
        agendar: (lista) async => agendamentos.add(lista.length),
        cancelar: () async => cancelamentos++,
      );
      addTearDown(lembretes.dispose);
      expect(agendamentos, hasLength(1));
      expect(agendamentos.single, greaterThan(0));

      estado.notifyListeners(); // nada mudou: não agenda de novo
      expect(agendamentos, hasLength(1));

      _comRemedios(estado, []);
      estado.notifyListeners();
      expect(agendamentos, [agendamentos.first, 0]);

      await estado.sair();
      expect(cancelamentos, 1);
    });

    test('Cuidador não agenda lembretes de dose', () {
      final agendamentos = <int>[];
      final lembretes = LembretesAgendados(
        estado: estadoCuidador(),
        agendar: (lista) async => agendamentos.add(lista.length),
        cancelar: () async {},
      );
      addTearDown(lembretes.dispose);
      expect(agendamentos, isEmpty);
    });
  });

  group('Aviso ao cuidador', () {
    test('Dose atrasada avisa uma vez; a tomada e a ainda no horário, não', () async {
      final momento = DateTime(hoje.year, hoje.month, hoje.day, 14, 0);
      final estado = _comRemedios(
        estadoCuidador(),
        [
          _med(id: 1, nome: 'Atrasado', horarios: const ['13:30'], inicio: diaHoje),
          _med(id: 2, nome: 'Tomado', horarios: const ['13:00'], inicio: diaHoje),
          _med(id: 3, nome: 'Futuro', horarios: const ['15:00'], inicio: diaHoje),
          _med(id: 4, nome: 'Perdido', horarios: const ['08:00'], inicio: diaHoje),
        ],
        historico: [_registro(2, diaHoje, '13:00', 'TOMADO')],
      );
      final alertas = <AlertaPaciente>[];
      final monitor = MonitorAlertas(
        estado: estado,
        buscarPaciente: (_) async => throw UnimplementedError(),
        confirmarAlertaManual: (_) async {},
        aoAlertar: alertas.add,
        agora: () => momento,
      );
      addTearDown(monitor.dispose);
      await monitor.verificarAgora();
      await monitor.verificarAgora();
      expect(alertas, hasLength(1));
      expect(alertas.single.titulo, 'Dose atrasada ⏰');
      expect(alertas.single.mensagem, 'Maria: a dose das 13:30 (Atrasado) está atrasada.');
      expect(alertas.single.notificacaoAgendada, isFalse);
    });
  });

  group('Adesão', () {
    test('Dose perdida sem registro conta; atrasada e futura, não', () {
      final hojeIso = dataAtualISO();
      final ontem = diaHoje.subtract(const Duration(days: 1));
      final medicamento = _med(horarios: const ['08:00'], inicio: ontem, fim: ontem);
      // Ontem: 1 dose sem registro (perdida). Nenhuma tomada.
      expect(calcularAdesao(const [], medicamentos: [medicamento], hojeIso: hojeIso), 0);
      // Com o registro de tomada, a mesma dose vira 100%.
      expect(calcularAdesao([_registro(1, ontem, '08:00', 'TOMADO')], medicamentos: [medicamento], hojeIso: hojeIso), 100);
      // Sem remédios nem registros não há o que cobrar.
      expect(calcularAdesao(const [], hojeIso: hojeIso), 100);
    });
  });

  group('Estoque', () {
    test('Avisa o baixo e o esgotado; suficiente e pomada, não', () {
      final inicio = diaHoje.subtract(const Duration(days: 1));
      final avisos = avisosEstoque([
        _med(id: 1, nome: 'Baixo', inicio: inicio, estoque: 3),
        _med(id: 2, nome: 'Zerado', inicio: inicio, estoque: 0),
        _med(id: 3, nome: 'Cheio', inicio: inicio, estoque: 90),
      ], const []);
      expect(avisos.map((a) => a.nome), ['Baixo', 'Zerado']);
      expect(avisos.first.texto, 'Restam 3 comp (dura 3 dias).');
      expect(avisos.last.esgotado, isTrue);
    });

    testWidgets('Card aparece no Início só quando há aviso', (tester) async {
      final amanha = diaHoje.add(const Duration(days: 1));
      await montarPagina(tester, _comRemedios(estadoPaciente(), [_med(nome: 'Baixo', inicio: diaHoje, estoque: 2, horarios: const ['23:59'])]), '/painel',
          (_) => const PainelIdoso());
      for (var i = 0; i < 10 && find.text('Estoque acabando').evaluate().isEmpty; i++) {
        await tester.dragFrom(const Offset(8, 650), const Offset(0, -350));
        await tester.pumpAndSettle();
      }
      expect(find.text('Estoque acabando'), findsOneWidget);
      expect(find.textContaining('Restam 2'), findsOneWidget);

      await montarPagina(tester, _comRemedios(estadoPaciente(), [_med(inicio: amanha, estoque: 90)]), '/painel', (_) => const PainelIdoso());
      expect(avisosEstoque([_med(inicio: amanha, estoque: 90)], const []), isEmpty);
    });
  });

  group('Navegação sem menu', () {
    testWidgets('Barra inferior não tem mais "Menu"', (tester) async {
      await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
      final barra = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(barra.items.map((i) => i.label), ['Início', 'Agenda', 'Histórico', 'Chat']);
      expect(find.byType(BarraNavegacaoInferior), findsOneWidget);
      expect(find.byTooltip('Abrir menu'), findsNothing);
      expect(find.byType(Drawer), findsNothing);

      await montarPagina(tester, estadoCuidador(), '/historico', (_) => const HistoricoPagina());
      expect(tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).items.map((i) => i.label),
          ['Início', 'Agenda', 'Histórico']);
    });
  });

  group('Detalhes do paciente', () {
    AppEstado comCodigo(String? codigo, {bool novaSenha = false}) {
      final estado = estadoCuidador();
      final dados = estado.pacientes.first;
      final p = dados.paciente;
      estado.pacientes = [
        PacienteComDados(
          paciente: Paciente(
            id: p.id,
            nome: p.nome,
            email: p.email,
            cuidadorId: p.cuidadorId,
            permiteAlteracoes: p.permiteAlteracoes,
            codigoAtivacao: codigo,
            codigoNovaSenha: novaSenha,
          ),
          medicamentos: dados.medicamentos,
          historico: dados.historico,
        ),
      ];
      return estado;
    }

    Future<void> abrir(WidgetTester tester, AppEstado estado) =>
        montarPagina(tester, estado, '/detalhes', (_) => const DetalhePaciente(pacienteId: 1));

    testWidgets('Reúne permissão e desvínculo; sem botão "Painel do paciente"', (tester) async {
      await abrir(tester, comCodigo(null));
      expect(find.textContaining('Painel do paciente'), findsNothing);
      await rolarAte(tester, find.text('Permite alterações'));
      expect(find.textContaining('Maria pode adicionar'), findsOneWidget);
      await rolarAte(tester, find.widgetWithText(OutlinedButton, 'Desvincular paciente'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sem código: botão para gerar; com código de nova senha: mostra e avisa a validade', (tester) async {
      await abrir(tester, comCodigo(null));
      await rolarAte(tester, find.text('Gerar código de nova senha'));
      expect(find.textContaining('esqueceu a senha'), findsOneWidget);

      await abrir(tester, comCodigo('ABC234', novaSenha: true));
      await rolarAte(tester, find.text('ABC234'));
      expect(find.text('Gerar código de nova senha'), findsNothing);
      expect(find.textContaining('Vale por 24 horas'), findsOneWidget);

      await abrir(tester, comCodigo('XYZ789'));
      await rolarAte(tester, find.text('XYZ789'));
      expect(find.textContaining('Ainda não ativou'), findsOneWidget);
    });

    testWidgets('Desvincular pede confirmação e cancelar não faz nada', (tester) async {
      final estado = comCodigo(null);
      await abrir(tester, estado);
      final botao = find.widgetWithText(OutlinedButton, 'Desvincular paciente');
      await rolarAte(tester, botao);
      await tester.tap(botao);
      await tester.pumpAndSettle();
      expect(find.text('Desvincular paciente?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(estado.pacientes, hasLength(1));
    });

    testWidgets('Fonte grande em 360px não estoura', (tester) async {
      await abrir(tester, comCodigo('ABC234', novaSenha: true)..tamanhoFonte = 'grande');
      await rolarAte(tester, find.widgetWithText(OutlinedButton, 'Desvincular paciente'));
      expect(tester.takeException(), isNull);
    });
  });

  group('Esqueci minha senha', () {
    testWidgets('Tela de nova senha explica de onde vem o código', (tester) async {
      final estado = AppEstado()..carregandoSessao = false;
      await montarPagina(tester, estado, '/definir-senha?novaSenha=1', (_) => const DefinirSenha());
      expect(find.text('Criar nova senha'), findsOneWidget);
      expect(find.textContaining('Peça ao seu cuidador'), findsOneWidget);

      await montarPagina(tester, estado, '/definir-senha', (_) => const DefinirSenha());
      expect(find.text('Ativar meu acesso'), findsOneWidget);
    });
  });

  group('Relatório em PDF', () {
    test('Gera um PDF com e sem doses, com acentos', () async {
      final fonte = pw.Font.ttf(ByteData.view(File('assets/fonts/SourceSans3-Regular.ttf').readAsBytesSync().buffer));
      final negrito = pw.Font.ttf(ByteData.view(File('assets/fonts/SourceSans3-Bold.ttf').readAsBytesSync().buffer));
      final tema = pw.ThemeData.withFont(base: fonte, bold: negrito);
      final paciente = Paciente(id: 1, nome: 'José Conceição', email: '', dataNascimento: DateTime(1950, 3, 10));
      final comDoses = await gerarRelatorioPdf(
        paciente: paciente,
        medicamentosAtivos: [_med(nome: 'Losartana', inicio: diaHoje)],
        entradas: [_registro(1, diaHoje, '08:00', 'TOMADO'), _registro(1, diaHoje, '20:00', 'PERDIDO')],
        inicio: diaHoje,
        fim: diaHoje,
        tema: tema,
      );
      expect(ascii.decode(comDoses.sublist(0, 4)), '%PDF');
      final vazio = await gerarRelatorioPdf(
        paciente: paciente,
        medicamentosAtivos: const [],
        entradas: const [],
        inicio: diaHoje,
        fim: diaHoje,
        tema: tema,
      );
      expect(ascii.decode(vazio.sublist(0, 4)), '%PDF');
      expect(comDoses.length, greaterThan(1000));
    });

    testWidgets('Botão aparece no Histórico', (tester) async {
      await montarPagina(tester, estadoPaciente(), '/historico', (_) => const HistoricoPagina());
      await rolarAte(tester, find.text('Gerar relatório (PDF)'));
      expect(find.text('Gerar relatório (PDF)'), findsOneWidget);
    });
  });
}
