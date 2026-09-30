import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../componentes/andaime_app.dart';
import '../componentes/botao.dart';
import '../componentes/cabecalho.dart';
import '../componentes/campo_texto.dart';
import '../componentes/cartao.dart';
import '../componentes/linha_dupla.dart';
import '../modelos/farmacia.dart';
import '../servicos/api_cliente.dart';
import '../servicos/farmacia_servico.dart';
import '../servicos/geocodificacao_servico.dart';
import '../utilitarios/tema.dart';

const _origemPadrao = LatLng(-10.911589, -37.0545059); // Aracaju — mesmo centro inicial do web
const _opcoesRaio = [(rotulo: '1 km', valor: 1000), (rotulo: '3 km', valor: 3000), (rotulo: '5 km', valor: 5000)];

String formatarDistancia(double metros) {
  if (metros < 1000) return '${metros.round()} m';
  return '${(metros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

class _Origem {
  final double latitude;
  final double longitude;
  final String rotulo;
  const _Origem(this.latitude, this.longitude, this.rotulo);
}

/// Equivalente a paginas/Farmacias.jsx: busca por endereço (com autocomplete
/// na Nominatim), CEP (ViaCEP) ou localização atual; raio de 1/3/5 km; mapa
/// OSM com marcadores + lista com distância e "Como chegar".
class Farmacias extends StatefulWidget {
  /// Dependências injetáveis pra teste; por padrão usam os serviços reais.
  final FarmaciaServico? farmaciaServico;
  final GeocodificacaoServico? geocodificacao;
  final Future<Position> Function()? obterPosicao;
  final bool exibirMapaBase;

  const Farmacias({
    super.key,
    this.farmaciaServico,
    this.geocodificacao,
    this.obterPosicao,
    this.exibirMapaBase = true,
  });

  @override
  State<Farmacias> createState() => _FarmaciasState();
}

class _FarmaciasState extends State<Farmacias> {
  late final FarmaciaServico _farmaciaServico = widget.farmaciaServico ?? FarmaciaServico();
  late final GeocodificacaoServico _geo = widget.geocodificacao ?? GeocodificacaoServico();
  final _mapa = MapController();
  bool _mapaPronto = false;

  final _buscaController = TextEditingController();
  final _cepController = TextEditingController();
  final _numeroController = TextEditingController();

  Timer? _debounce;
  int _sequenciaSugestoes = 0; // descarta respostas de autocomplete já obsoletas
  List<SugestaoEndereco> _sugestoes = [];
  bool _mostrarSugestoes = false;
  bool _carregandoSugestoes = false;

  bool _buscandoEndereco = false;
  bool _carregandoCep = false;
  bool _obtendoLocalizacao = false;

  _Origem? _origem;
  int _raioMetros = 3000;
  RespostaFarmacias? _dados;
  bool _carregando = false;
  String? _erro;
  int _sequenciaBusca = 0;
  int? _selecionada;

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaController.dispose();
    _cepController.dispose();
    _numeroController.dispose();
    _mapa.dispose();
    super.dispose();
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // ---------- Autocomplete ----------

  void _aoDigitarEndereco(String valor) {
    _debounce?.cancel();
    final texto = valor.trim();
    final sequencia = ++_sequenciaSugestoes;
    if (texto.length < 3) {
      setState(() {
        _sugestoes = [];
        _mostrarSugestoes = false;
        _carregandoSugestoes = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      setState(() {
        _carregandoSugestoes = true;
        _mostrarSugestoes = true;
      });
      List<SugestaoEndereco> lista;
      try {
        lista = await _geo.sugerir(texto);
      } catch (_) {
        lista = [];
      }
      if (!mounted || sequencia != _sequenciaSugestoes) return;
      setState(() {
        _sugestoes = lista;
        _carregandoSugestoes = false;
      });
    });
  }

  /// Invalida qualquer autocomplete pendente — uma busca explícita venceu.
  void _encerrarSugestoes() {
    _debounce?.cancel();
    _sequenciaSugestoes++;
    _sugestoes = [];
    _mostrarSugestoes = false;
    _carregandoSugestoes = false;
  }

  void _selecionarSugestao(SugestaoEndereco sugestao) {
    FocusScope.of(context).unfocus();
    setState(() {
      _encerrarSugestoes();
      _buscaController.text = sugestao.displayName;
    });
    _definirOrigem(_Origem(sugestao.lat, sugestao.lon, sugestao.displayName));
  }

  // ---------- Formas de definir a origem ----------

  Future<void> _buscarPorEndereco() async {
    final texto = _buscaController.text.trim();
    if (texto.length < 3) {
      _avisar('Digite pelo menos 3 letras do endereço.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _encerrarSugestoes();
      _buscandoEndereco = true;
    });
    try {
      final resultado = await _geo.geocodificar(texto);
      if (!mounted) return;
      if (resultado == null) {
        _avisar('Não encontramos esse endereço. Tente detalhar mais.');
        return;
      }
      _definirOrigem(_Origem(resultado.lat, resultado.lon, resultado.displayName));
    } catch (_) {
      if (mounted) _avisar('Não foi possível buscar esse endereço agora.');
    } finally {
      if (mounted) setState(() => _buscandoEndereco = false);
    }
  }

  Future<void> _buscarPorCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) {
      _avisar('Digite um CEP válido com 8 dígitos.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _carregandoCep = true);
    try {
      final endereco = await _geo.buscarCep(cep, numero: _numeroController.text);
      if (!mounted) return;
      if (endereco == null) {
        _avisar('CEP não encontrado.');
        return;
      }
      var resultado = await _geo.geocodificar(endereco.enderecoCompleto);
      if (resultado == null && endereco.enderecoSemNumero != null) {
        resultado = await _geo.geocodificar(endereco.enderecoSemNumero!);
      }
      if (!mounted) return;
      if (resultado == null) {
        _avisar('Encontramos o CEP, mas não foi possível localizá-lo no mapa.');
        return;
      }
      setState(() {
        _encerrarSugestoes();
        _buscaController.text = endereco.enderecoCompleto;
      });
      _definirOrigem(_Origem(resultado.lat, resultado.lon, endereco.enderecoCompleto));
    } catch (_) {
      if (mounted) _avisar('Não foi possível buscar esse CEP agora.');
    } finally {
      if (mounted) setState(() => _carregandoCep = false);
    }
  }

  Future<Position> _posicaoAtualReal() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const _ErroLocalizacao('Ative a localização do aparelho para usar essa opção.');
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) permissao = await Geolocator.requestPermission();
    if (permissao == LocationPermission.denied || permissao == LocationPermission.deniedForever) {
      throw const _ErroLocalizacao('Sem permissão de localização. Libere o acesso nas configurações do aparelho.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
    );
  }

  Future<void> _usarLocalizacaoAtual() async {
    FocusScope.of(context).unfocus();
    setState(() => _obtendoLocalizacao = true);
    try {
      final posicao = await (widget.obterPosicao ?? _posicaoAtualReal)();
      if (!mounted) return;
      setState(() {
        _encerrarSugestoes();
        _buscaController.text = 'Minha localização atual';
      });
      _definirOrigem(_Origem(posicao.latitude, posicao.longitude, 'Minha localização atual'));
    } on _ErroLocalizacao catch (erro) {
      if (mounted) _avisar(erro.mensagem);
    } catch (_) {
      if (mounted) _avisar('Não foi possível obter sua localização. Verifique a permissão do aplicativo.');
    } finally {
      if (mounted) setState(() => _obtendoLocalizacao = false);
    }
  }

  void _definirOrigem(_Origem origem) {
    _origem = origem;
    _buscarFarmacias();
  }

  void _definirRaio(int raio) {
    if (raio == _raioMetros) return;
    setState(() => _raioMetros = raio);
    if (_origem != null) _buscarFarmacias();
  }

  // ---------- Busca de farmácias ----------

  Future<void> _buscarFarmacias() async {
    final origem = _origem;
    if (origem == null) return;
    final sequencia = ++_sequenciaBusca;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resposta = await _farmaciaServico.buscarPorCoordenadas(origem.latitude, origem.longitude, _raioMetros);
      if (!mounted || sequencia != _sequenciaBusca) return;
      setState(() {
        _dados = resposta;
        _selecionada = null;
      });
      _enquadrarResultados(resposta);
    } catch (erro) {
      if (!mounted || sequencia != _sequenciaBusca) return;
      setState(() {
        _erro = erro is ApiExcecao ? erro.mensagem : 'Não foi possível buscar farmácias para esse local.';
        _dados = null;
      });
    } finally {
      if (mounted && sequencia == _sequenciaBusca) setState(() => _carregando = false);
    }
  }

  void _enquadrarResultados(RespostaFarmacias resposta) {
    if (!_mapaPronto) return;
    final origem = LatLng(resposta.origem.latitude, resposta.origem.longitude);
    if (resposta.farmacias.isEmpty) {
      _mapa.move(origem, 15);
      return;
    }
    // Centralizado na origem, com zoom que ainda mostra todas as farmácias: o
    // enquadramento é um retângulo simétrico em volta da origem (maior
    // distância em cada eixo, para os dois lados), então o centro é a origem.
    var deltaLat = 0.0;
    var deltaLon = 0.0;
    for (final f in resposta.farmacias) {
      deltaLat = math.max(deltaLat, (f.latitude - origem.latitude).abs());
      deltaLon = math.max(deltaLon, (f.longitude - origem.longitude).abs());
    }
    _mapa.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(origem.latitude - deltaLat, origem.longitude - deltaLon),
        LatLng(origem.latitude + deltaLat, origem.longitude + deltaLon),
      ),
      padding: const EdgeInsets.all(40),
      maxZoom: 17,
    ));
  }

  void _selecionar(int indice) {
    final farmacia = _dados?.farmacias[indice];
    if (farmacia == null) return;
    setState(() => _selecionada = indice);
    if (_mapaPronto) _mapa.move(LatLng(farmacia.latitude, farmacia.longitude), 16);
  }

  Future<void> _abrirComoChegar(Farmacia farmacia) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${farmacia.latitude},${farmacia.longitude}');
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) _avisar('Não foi possível abrir o mapa.');
  }

  // ---------- Interface ----------

  @override
  Widget build(BuildContext context) {
    return AndaimeApp(
      appBar: const Cabecalho(kicker: 'Localização', titulo: 'Farmácias'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _cartaoBusca(),
          const SizedBox(height: 16),
          LinhaDupla(larguraMinima: 760, esquerda: _cartaoMapa(), direita: _cartaoLista()),
        ],
      ),
    );
  }

  Widget _cartaoBusca() {
    return Cartao(
      titulo: 'Buscar farmácias próximas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _buscaController,
                  onChanged: _aoDigitarEndereco,
                  onSubmitted: (_) => _buscarPorEndereco(),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 17),
                  decoration: const InputDecoration(
                    labelText: 'Endereço de origem',
                    hintText: 'Digite ao menos 3 letras...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Botao(
                texto: 'Buscar',
                larguraTotal: false,
                variante: VarianteBotao.secundario,
                carregando: _buscandoEndereco,
                onPressed: _buscarPorEndereco,
              ),
            ],
          ),
          if (_mostrarSugestoes) _listaSugestoes(),
          const SizedBox(height: 12),
          Botao(
            texto: _obtendoLocalizacao ? 'Localizando...' : 'Usar minha localização atual',
            icone: Icons.my_location,
            variante: VarianteBotao.contorno,
            carregando: _obtendoLocalizacao,
            onPressed: _usarLocalizacaoAtual,
          ),
          const SizedBox(height: 16),
          const Text('Raio de busca', style: TextStyle(fontWeight: FontWeight.w800, color: CorApp.textoLabel)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _opcoesRaio.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _botaoRaio(_opcoesRaio[i].rotulo, _opcoesRaio[i].valor)),
              ],
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          const Text('Ou busque pelo CEP', style: TextStyle(fontWeight: FontWeight.w800, color: CorApp.textoLabel)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CampoTexto(
                  rotulo: 'CEP',
                  controller: _cepController,
                  tipoTeclado: TextInputType.number,
                  placeholder: '00000-000',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CampoTexto(rotulo: 'Número', controller: _numeroController, placeholder: 'Opcional'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Botao(
            texto: 'Buscar CEP',
            variante: VarianteBotao.secundario,
            carregando: _carregandoCep,
            onPressed: _buscarPorCep,
          ),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Buscando farmácias próximas... isso pode levar até 20 segundos.',
                        style: TextStyle(color: CorApp.textoSuave)),
                  ),
                ],
              ),
            ),
          if (_erro != null && !_carregando)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_erro!, style: const TextStyle(color: CorApp.vermelhoTexto, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _listaSugestoes() {
    Widget estado(String texto) => Padding(
          padding: const EdgeInsets.all(14),
          child: Text(texto, style: const TextStyle(color: CorApp.textoSuave)),
        );
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: CorApp.fundoCard,
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        border: Border.all(color: CorApp.bordaInput),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_carregandoSugestoes)
            estado('Buscando sugestões...')
          else if (_sugestoes.isEmpty)
            estado('Nenhum endereço encontrado, tente detalhar mais')
          else
            for (final sugestao in _sugestoes)
              InkWell(
                onTap: () => _selecionarSugestao(sugestao),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 20, color: CorApp.textoSuave),
                      const SizedBox(width: 10),
                      Expanded(child: Text(sugestao.displayName, maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _botaoRaio(String rotulo, int valor) {
    final ativo = _raioMetros == valor;
    return OutlinedButton(
      onPressed: () => _definirRaio(valor),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: ativo ? CorApp.azulFundo : null,
        foregroundColor: ativo ? CorApp.azulTexto : CorApp.textoSuave,
        side: BorderSide(color: ativo ? CorApp.azul : CorApp.borda, width: ativo ? 2 : 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaioApp.pequeno)),
      ),
      child: Text(rotulo, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Widget _cartaoMapa() {
    final dados = _dados;
    final selecionada = _selecionada != null ? dados?.farmacias[_selecionada!] : null;
    return Cartao(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        child: SizedBox(
          height: 340,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapa,
                options: MapOptions(
                  initialCenter: _origemPadrao,
                  initialZoom: 14,
                  onMapReady: () {
                    _mapaPronto = true;
                    if (_dados != null) _enquadrarResultados(_dados!);
                  },
                  onTap: (_, _) => setState(() => _selecionada = null),
                ),
                children: [
                  if (widget.exibirMapaBase)
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cuidamed.cuidamed_mobile',
                    ),
                  MarkerLayer(
                    markers: [
                      if (dados != null)
                        Marker(
                          point: LatLng(dados.origem.latitude, dados.origem.longitude),
                          width: 26,
                          height: 26,
                          child: const _Marcador(cor: CorApp.azul, tamanho: 22, rotulo: 'Ponto de origem'),
                        ),
                      if (dados != null)
                        for (var i = 0; i < dados.farmacias.length; i++)
                          Marker(
                            point: LatLng(dados.farmacias[i].latitude, dados.farmacias[i].longitude),
                            width: 32,
                            height: 32,
                            child: GestureDetector(
                              onTap: () => _selecionar(i),
                              child: _Marcador(
                                cor: _selecionada == i ? CorApp.vermelho : CorApp.verde,
                                tamanho: _selecionada == i ? 26 : 20,
                                rotulo: dados.farmacias[i].nome,
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
              // Atribuição exigida pela licença dos tiles do OpenStreetMap.
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: Colors.white.withValues(alpha: 0.85),
                  child: const Text('© OpenStreetMap colaboradores', style: TextStyle(fontSize: 11, color: CorApp.textoSuave)),
                ),
              ),
              if (selecionada != null)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 36,
                  child: Material(
                    elevation: 3,
                    color: CorApp.fundoCard,
                    borderRadius: BorderRadius.circular(RaioApp.pequeno),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(selecionada.nome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text(
                                  '${formatarDistancia(selecionada.distanciaMetros)} · ${selecionada.endereco}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: CorApp.textoSuave, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          TextButton(onPressed: () => _abrirComoChegar(selecionada), child: const Text('Como chegar')),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartaoLista() {
    final dados = _dados;
    return Cartao(
      titulo: 'Farmácias encontradas${dados != null ? ' (${dados.farmacias.length})' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_carregando && _erro == null && dados == null)
            const Text(
              'Digite um endereço, busque por CEP ou use sua localização atual para ver farmácias próximas.',
              style: TextStyle(color: CorApp.textoSuave),
            ),
          if (!_carregando && dados != null && dados.farmacias.isEmpty)
            const Text('Nenhuma farmácia encontrada nesse raio.', style: TextStyle(color: CorApp.textoSuave)),
          if (dados != null)
            for (var i = 0; i < dados.farmacias.length; i++) _itemFarmacia(dados.farmacias[i], i),
        ],
      ),
    );
  }

  Widget _itemFarmacia(Farmacia farmacia, int indice) {
    final selecionada = _selecionada == indice;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selecionada ? CorApp.azulFundo : CorApp.fundoDestaque,
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        border: Border.all(color: selecionada ? CorApp.azul : CorApp.borda, width: selecionada ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        onTap: () => _selecionar(indice),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farmacia.nome, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(farmacia.endereco, style: const TextStyle(color: CorApp.textoSuave, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatarDistancia(farmacia.distanciaMetros),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: CorApp.azulTexto)),
                  TextButton(
                    onPressed: () => _abrirComoChegar(farmacia),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                    child: const Text('Como chegar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Marcador extends StatelessWidget {
  final Color cor;
  final double tamanho;
  final String rotulo;
  const _Marcador({required this.cor, required this.tamanho, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: rotulo,
      child: Center(
        child: Container(
          width: tamanho,
          height: tamanho,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1))],
          ),
        ),
      ),
    );
  }
}

class _ErroLocalizacao implements Exception {
  final String mensagem;
  const _ErroLocalizacao(this.mensagem);
}
