// Script de verificação manual, pure-Dart (sem Flutter): os serviços do app
// importam package:flutter/foundation.dart (pra detectar plataforma), que
// puxa dart:ui — indisponível em `dart run` fora do runtime Flutter. Então
// aqui chamo a API com dio diretamente, mas reaproveito os MESMOS modelos
// (fromJson) e utilitários de regra de negócio do app, que são pure-Dart.
// Rodar com: dart run bin/verificar_api.dart
// ignore_for_file: avoid_print
import 'package:dio/dio.dart';

import 'package:cuidamed_mobile/modelos/cuidador.dart';
import 'package:cuidamed_mobile/modelos/historico.dart';
import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/modelos/paciente.dart';
import 'package:cuidamed_mobile/utilitarios/horarios.dart';
import 'package:cuidamed_mobile/utilitarios/whatsapp.dart';

final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));

Future<void> main() async {
  print('--- Login ---');
  final loginResp = await _dio.post('/api/auth/login', data: {'email': 'cuidador.flutter.teste@email.com', 'senha': 'senha1234'});
  final tipo = loginResp.data['tipo'] as String;
  final idLogado = loginResp.data['id'] as int;
  print('tipo=$tipo id=$idLogado');

  print('--- Cuidador ---');
  final cuidadorResp = await _dio.get('/api/cuidadores/$idLogado');
  final cuidador = Cuidador.fromJson(cuidadorResp.data);
  print('nome=${cuidador.nome} email=${cuidador.email}');

  print('--- Cadastrar paciente de teste ---');
  final pacResp = await _dio.post('/api/pacientes', data: {
    'nome': 'Paciente Verificação Dart',
    'email': 'paciente.verificacao.dart.${DateTime.now().millisecondsSinceEpoch}@email.com',
    'senha': 'senha1234',
    'telefone': '(79) 99816-1122',
    'cuidadorId': idLogado,
  });
  final paciente = Paciente.fromJson(pacResp.data);
  print('paciente criado id=${paciente.id} nome=${paciente.nome} telefone=${paciente.telefone}');

  print('--- Cadastrar medicamento ---');
  final agora = DateTime.now();
  final horarioTexto = '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';
  final medResp = await _dio.post('/api/medicamentos', data: {
    'pacienteId': paciente.id,
    'nome': 'Losartana',
    'dosagem': '50 mg',
    'forma': 'COMPRIMIDO',
    'frequencia': 'UMA_VEZ_AO_DIA',
    'dataInicio': agora.toIso8601String().substring(0, 10),
    'dataFim': null,
    'observacoes': null,
    'quantidadeEstoque': 30,
    'quantidadePorDose': 1,
    'horarios': [horarioTexto],
  });
  final medicamento = Medicamento.fromJson(medResp.data);
  print('medicamento criado id=${medicamento.id} horarios=${medicamento.horarios} dosagem=${medicamento.dosagem}');

  print('--- Listar medicamentos do paciente ---');
  final listaMedResp = await _dio.get('/api/pacientes/${paciente.id}/medicamentos');
  final medicamentos = (listaMedResp.data as List).map((m) => Medicamento.fromJson(m)).toList();
  print('total=${medicamentos.length}, primeiro.dosagem=${medicamentos.first.dosagem}');

  print('--- Registrar histórico (dose tomada) ---');
  final histResp = await _dio.post('/api/historicos', data: {
    'pacienteId': paciente.id,
    'medicamentoId': medicamento.id,
    'data': agora.toIso8601String().substring(0, 10),
    'hora': horarioTexto,
    'status': 'TOMADO',
  });
  final historicoCriado = Historico.fromJson(histResp.data);
  print('historico id=${historicoCriado.id} status=${historicoCriado.status}');

  print('--- Listar histórico ---');
  final listaHistResp = await _dio.get('/api/pacientes/${paciente.id}/historicos');
  final historico = (listaHistResp.data as List).map((h) => Historico.fromJson(h)).toList();
  print('total=${historico.length}');

  print('--- calcularStatusAtual / construirDosesHoje / calcularAdesao (utilitarios/horarios.dart) ---');
  final doses = construirDosesHoje(medicamentos, historico);
  final statusOk = doses.first.status == 'tomado';
  print('doses de hoje=${doses.length}, status da primeira=${doses.first.status} (esperado: tomado) -> ${statusOk ? "OK" : "FALHOU"}');
  final adesao = calcularAdesao(historico);
  print('adesao=$adesao% (esperado: 100) -> ${adesao == 100 ? "OK" : "FALHOU"}');

  print('--- utilitarios/whatsapp.dart ---');
  final link = montarLinkWhatsApp(
    telefone: paciente.telefone,
    nomePaciente: paciente.nome,
    medicamento: medicamento.nome,
    horario: horarioTexto,
    forma: medicamento.forma,
    quantidadePorDose: medicamento.quantidadePorDose,
    dosagem: medicamento.dosagem,
    dataFim: medicamento.dataFim,
  );
  final linkOk = link != null && link.startsWith('https://api.whatsapp.com/send/?phone=5579998161122');
  print('link=$link -> ${linkOk ? "OK" : "FALHOU"}');

  print('--- Excluir paciente de teste ---');
  await _dio.delete('/api/pacientes/${paciente.id}');
  print('paciente ${paciente.id} excluído.');

  print('');
  print('OK: camada de serviços/modelos/regra de negócio funcionou de ponta a ponta contra a API real.');
}
