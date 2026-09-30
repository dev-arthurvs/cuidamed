import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';

import 'package:cuidamed_mobile/modelos/farmacia.dart';
import 'package:cuidamed_mobile/paginas/farmacias.dart';
import 'package:cuidamed_mobile/servicos/api_cliente.dart';
import 'package:cuidamed_mobile/servicos/farmacia_servico.dart';
import 'package:cuidamed_mobile/servicos/geocodificacao_servico.dart';

import 'apoio.dart';

class _FarmaciaFalsa implements FarmaciaServico {
  final List<(double, double, int)> chamadas = [];
  bool falhar = false;

  @override
  Future<RespostaFarmacias> buscarPorCoordenadas(double lat, double lon, int raioMetros) async {
    chamadas.add((lat, lon, raioMetros));
    if (falhar) throw ApiExcecao('Serviço de mapas indisponível.');
    return RespostaFarmacias(
      origem: PontoOrigem(latitude: lat, longitude: lon, enderecoFormatado: ''),
      farmacias: [
        Farmacia(nome: 'Drogasil Centro', endereco: 'Rua A, 1', latitude: lat + 0.001, longitude: lon, distanciaMetros: 350),
        Farmacia(nome: 'Pague Menos', endereco: 'Av. B, 200', latitude: lat, longitude: lon + 0.01, distanciaMetros: 1520),
      ],
    );
  }

  @override
  Future<RespostaFarmacias> buscarPorEndereco(String endereco, int raioMetros) => throw UnimplementedError();
}

class _GeoFalso implements GeocodificacaoServico {
  final List<String> geocodificados = [];

  @override
  Future<List<SugestaoEndereco>> sugerir(String texto) async => [
        SugestaoEndereco(displayName: 'Rua Laranjeiras, Aracaju, SE', lat: -10.91, lon: -37.05),
        SugestaoEndereco(displayName: 'Rua Laranjeiras, Salvador, BA', lat: -12.97, lon: -38.5),
      ];

  @override
  Future<SugestaoEndereco?> geocodificar(String texto) async {
    geocodificados.add(texto);
    if (texto.contains('inexistente')) return null;
    if (texto.contains(', 999,')) return null; // número não achado → cai no fallback sem número
    return SugestaoEndereco(displayName: texto, lat: -10.9, lon: -37.0);
  }

  @override
  Future<EnderecoCep?> buscarCep(String cep, {String numero = ''}) async {
    if (cep == '00000000') return null;
    final completo = numero.isEmpty ? 'Rua X, Centro, Aracaju - SE' : 'Rua X, $numero, Centro, Aracaju - SE';
    return EnderecoCep(enderecoCompleto: completo, enderecoSemNumero: numero.isEmpty ? null : 'Rua X, Centro, Aracaju - SE');
  }
}

Position _posicao(double lat, double lon) => Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime(2026),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

Future<(_FarmaciaFalsa, _GeoFalso)> _montar(WidgetTester tester, {Size tamanho = const Size(360, 800), String fonte = 'media'}) async {
  final farmacias = _FarmaciaFalsa();
  final geo = _GeoFalso();
  await montarPagina(
    tester,
    estadoPaciente()..tamanhoFonte = fonte,
    '/farmacias',
    (_) => Farmacias(
      farmaciaServico: farmacias,
      geocodificacao: geo,
      obterPosicao: () async => _posicao(-10.95, -37.07),
      exibirMapaBase: false,
    ),
    tamanho: tamanho,
  );
  return (farmacias, geo);
}

final _campoEndereco = find.widgetWithText(TextField, 'Endereço de origem');

void main() {
  test('formatarDistancia', () {
    expect(formatarDistancia(349.6), '350 m');
    expect(formatarDistancia(1520), '1,5 km');
  });

  testWidgets('Estado inicial orienta o usuário', (tester) async {
    await _montar(tester);
    await rolarAte(tester, find.textContaining('Digite um endereço, busque por CEP'));
  });

  testWidgets('Autocomplete: digitar mostra sugestões e escolher busca farmácias', (tester) async {
    final (farmacias, _) = await _montar(tester);
    await tester.enterText(_campoEndereco, 'Rua Lar');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Rua Laranjeiras, Salvador, BA'), findsOneWidget);

    await tester.tap(find.text('Rua Laranjeiras, Aracaju, SE'));
    await tester.pumpAndSettle();
    expect(farmacias.chamadas.single, (-10.91, -37.05, 3000));
    expect(find.text('Rua Laranjeiras, Salvador, BA'), findsNothing);
    await rolarAte(tester, find.text('Farmácias encontradas (2)'));
    await rolarAte(tester, find.text('Drogasil Centro'));
    expect(find.text('350 m'), findsOneWidget);
    expect(find.text('1,5 km'), findsOneWidget);
  });

  testWidgets('Menos de 3 letras não busca; endereço inexistente avisa', (tester) async {
    final (farmacias, _) = await _montar(tester);
    await tester.enterText(_campoEndereco, 'Ru');
    await tester.tap(find.text('Buscar'));
    await tester.pump();
    expect(find.text('Digite pelo menos 3 letras do endereço.'), findsOneWidget);

    await tester.enterText(_campoEndereco, 'endereco inexistente');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.text('Não encontramos esse endereço. Tente detalhar mais.'), findsOneWidget);
    expect(farmacias.chamadas, isEmpty);
  });

  testWidgets('Após a busca, o mapa fica centralizado no endereço de origem', (tester) async {
    // As farmácias falsas ficam todas ao norte/leste da origem: o enquadramento
    // antigo (origem + farmácias) deslocaria o centro; agora o centro é a origem.
    await _montar(tester, tamanho: const Size(1200, 900));
    await tester.tap(find.text('Usar minha localização atual'));
    await tester.pumpAndSettle();
    final centro = tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!.camera.center;
    expect(centro.latitude, closeTo(-10.95, 0.0001));
    expect(centro.longitude, closeTo(-37.07, 0.0001));
  });

  testWidgets('Localização atual busca e trocar o raio refaz a busca', (tester) async {
    final (farmacias, _) = await _montar(tester);
    await tester.tap(find.text('Usar minha localização atual'));
    await tester.pumpAndSettle();
    expect(farmacias.chamadas.last, (-10.95, -37.07, 3000));
    expect(find.text('Minha localização atual'), findsOneWidget);

    await tester.tap(find.text('5 km'));
    await tester.pumpAndSettle();
    expect(farmacias.chamadas.last, (-10.95, -37.07, 5000));
    expect(farmacias.chamadas.length, 2);
  });

  testWidgets('CEP: inválido, não encontrado e fallback sem número', (tester) async {
    final (farmacias, geo) = await _montar(tester);
    final cep = find.widgetWithText(TextFormField, 'CEP');
    final botaoCep = find.text('Buscar CEP');

    await tester.enterText(cep, '4900');
    await rolarAte(tester, botaoCep);
    await tester.tap(botaoCep);
    await tester.pump();
    expect(find.text('Digite um CEP válido com 8 dígitos.'), findsOneWidget);

    await tester.enterText(cep, '00000-000');
    await tester.tap(botaoCep);
    await tester.pumpAndSettle();
    expect(find.text('CEP não encontrado.'), findsOneWidget);

    await tester.enterText(cep, '49000-000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Número'), '999');
    await tester.tap(botaoCep);
    await tester.pumpAndSettle();
    expect(geo.geocodificados, ['Rua X, 999, Centro, Aracaju - SE', 'Rua X, Centro, Aracaju - SE']);
    expect(farmacias.chamadas, hasLength(1));
  });

  testWidgets('Erro da API aparece na tela', (tester) async {
    final (farmacias, _) = await _montar(tester);
    farmacias.falhar = true;
    await tester.tap(find.text('Usar minha localização atual'));
    await tester.pumpAndSettle();
    expect(find.text('Serviço de mapas indisponível.'), findsOneWidget);
  });

  testWidgets('Tocar numa farmácia da lista destaca no mapa', (tester) async {
    await _montar(tester);
    await tester.tap(find.text('Usar minha localização atual'));
    await tester.pumpAndSettle();
    await rolarAte(tester, find.text('Pague Menos'));
    await tester.tap(find.text('Pague Menos'));
    await tester.pumpAndSettle();
    // Cartão flutuante sobre o mapa com a farmácia selecionada.
    expect(find.textContaining('1,5 km · Av. B, 200'), findsOneWidget);
  });

  testWidgets('Fonte grande em 360px e tela larga não estouram', (tester) async {
    await _montar(tester, fonte: 'grande');
    await tester.tap(find.text('Usar minha localização atual'));
    await tester.pumpAndSettle();
    await rolarAte(tester, find.text('Pague Menos'));
    expect(tester.takeException(), isNull);

    await _montar(tester, tamanho: const Size(1100, 900));
    await tester.tap(find.text('Usar minha localização atual'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Mapa e lista lado a lado na tela larga.
    final lista = tester.getTopLeft(find.textContaining('Farmácias encontradas'));
    expect(lista.dx, greaterThan(500));
  });
}
