import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cuidamed_mobile/app.dart';
import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/modelos/historico.dart';
import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/modelos/paciente.dart';
import 'package:cuidamed_mobile/utilitarios/tema.dart';

/// Estado já "logado", sem tocar na API — os testes montam as telas direto.
AppEstado estadoPaciente({int? cuidadorId, int? cuidadorSolicitadoId, bool permiteAlteracoes = true}) {
  final hoje = DateTime.now();
  final paciente = Paciente(
    id: 1,
    nome: 'Maria da Silva',
    email: 'maria@email.com',
    dataNascimento: DateTime(1950, 3, 10),
    sexo: 'FEMININO',
    telefone: '(79) 99999-0000',
    endereco: 'Rua A, 10',
    cuidadorId: cuidadorId,
    cuidadorSolicitadoId: cuidadorSolicitadoId,
    permiteAlteracoes: permiteAlteracoes,
  );
  final medicamentos = [
    Medicamento(
      id: 10,
      pacienteId: 1,
      nome: 'Losartana',
      dosagem: '50mg',
      forma: 'COMPRIMIDO',
      frequencia: '2x ao dia',
      dataInicio: hoje.subtract(const Duration(days: 10)),
      horarios: const ['08:00', '20:00'],
      quantidadeEstoque: 30,
      quantidadePorDose: 1,
    ),
    Medicamento(
      id: 11,
      pacienteId: 1,
      nome: 'Amoxicilina',
      dosagem: '500mg',
      forma: 'CAPSULA',
      frequencia: 'A cada 8 horas',
      dataInicio: hoje.subtract(const Duration(days: 20)),
      dataFim: hoje.subtract(const Duration(days: 5)),
      horarios: const ['06:00', '14:00', '22:00'],
    ),
  ];
  final historico = [
    Historico(
      id: 100,
      pacienteId: 1,
      medicamentoId: 10,
      data: DateTime(hoje.year, hoje.month, hoje.day),
      hora: '08:00',
      nomeMedicamento: 'Losartana',
      dosagem: '50mg',
      status: 'TOMADO',
    ),
  ];
  final estado = AppEstado()
    ..usuario = UsuarioLogado(id: 1, nome: paciente.nome, email: paciente.email, tipo: 'paciente')
    ..pacientes = [PacienteComDados(paciente: paciente, medicamentos: medicamentos, historico: historico)]
    ..pacienteFocoId = 1
    ..carregandoSessao = false;
  return estado;
}

AppEstado estadoCuidador() {
  final base = estadoPaciente(cuidadorId: 5);
  return AppEstado()
    ..usuario = UsuarioLogado(
      id: 5,
      nome: 'João Cuidador',
      email: 'joao@email.com',
      tipo: 'cuidador',
      profissao: 'Enfermeiro',
      telefone: '(79) 98888-1111',
    )
    ..pacientes = base.pacientes
    ..pacienteFocoId = 1
    ..carregandoSessao = false;
}

/// Monta [pagina] numa rota [rota] com router real (AndaimeApp lê o
/// GoRouterState) e a mesma escala de fonte do app. Tela de celular 360x800.
Future<void> montarPagina(
  WidgetTester tester,
  AppEstado estado,
  String rota,
  Widget Function(GoRouterState) pagina, {
  Size tamanho = const Size(360, 800),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: rota,
    routes: [
      GoRoute(path: rota.split('?').first, builder: (context, state) => pagina(state)),
      for (final outra in ['/painel', '/login', '/cadastro', '/definir-senha', '/agenda', '/acessibilidade', '/ciclos-encerrados', '/historico', '/chat', '/farmacias', '/perfil'])
        if (outra != rota) GoRoute(path: outra, builder: (context, state) => Scaffold(body: Text('rota $outra'))),
    ],
  );
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: estado,
      child: MaterialApp.router(theme: construirTema(), routerConfig: router, builder: aplicarEscalaFonte),
    ),
  );
  await tester.pumpAndSettle();
}

/// scrollUntilVisible no ListView principal (TextFields também são Scrollable).
/// O ListView constrói itens um pouco fora da tela (cache), então depois de
/// achar o alvo ainda garante que ele esteja de fato visível pra ser tocado.
Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
  await tester.scrollUntilVisible(alvo, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
}

/// Carrega a Nunito de verdade (por padrão os testes desenham texto com uma
/// fonte de blocos, mais larga) — pra medir larguras de texto realistas.
Future<void> carregarNunito(WidgetTester tester) => tester.runAsync(() async {
      final loader = FontLoader('Nunito');
      for (final peso in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
        loader.addFont(Future.value(ByteData.view(File('assets/fonts/Nunito-$peso.ttf').readAsBytesSync().buffer)));
      }
      await loader.load();
    });
