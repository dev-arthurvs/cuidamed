import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { MapContainer, Marker, Popup, TileLayer, useMap } from 'react-leaflet'
import { useOutletContext } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Cabecalho from '../componentes/Cabecalho'
import Campo from '../componentes/Campo'
import Cartao from '../componentes/Cartao'
import Spinner from '../componentes/Spinner'
import { useApp } from '../contexto/useApp'
import { api } from '../utilitarios/api'
import './Farmacias.css'

const URL_NOMINATIM = 'https://nominatim.openstreetmap.org/search'
const URL_VIACEP = 'https://viacep.com.br/ws'
const ORIGEM_PADRAO = {
  latitude: -10.911589,
  longitude: -37.0545059,
  rotulo: 'Rua Laranjeiras, 100, Aracaju, SE',
}
const OPCOES_RAIO = [
  { rotulo: '1 km', valor: 1000 },
  { rotulo: '3 km', valor: 3000 },
  { rotulo: '5 km', valor: 5000 },
]

const iconeOrigem = L.divIcon({
  className: 'farmacias__marcador farmacias__marcador--origem',
  html: '<span></span>',
  iconSize: [22, 22],
  iconAnchor: [11, 11],
  popupAnchor: [0, -12],
})

function criarIconeFarmacia(selecionado) {
  return L.divIcon({
    className: `farmacias__marcador farmacias__marcador--farmacia${selecionado ? ' farmacias__marcador--selecionado' : ''}`,
    html: '<span></span>',
    iconSize: [20, 20],
    iconAnchor: [10, 10],
    popupAnchor: [0, -10],
  })
}

function formatarDistancia(metros) {
  if (metros < 1000) return `${Math.round(metros)} m`
  return `${(metros / 1000).toFixed(1)} km`
}

function abrirComoChegar(farmacia) {
  const url = `https://www.google.com/maps/dir/?api=1&destination=${farmacia.latitude},${farmacia.longitude}`
  window.open(url, '_blank', 'noopener,noreferrer')
}

function ControladorMapa({ aoInicializar }) {
  const mapa = useMap()
  useEffect(() => {
    aoInicializar(mapa)
  }, [mapa, aoInicializar])
  return null
}

export default function Farmacias() {
  const { abrirMenu } = useOutletContext()
  const { mostrarToast } = useApp()

  const [textoBusca, setTextoBusca] = useState('')
  const [sugestoes, setSugestoes] = useState([])
  const [mostrarSugestoes, setMostrarSugestoes] = useState(false)
  const [carregandoSugestoes, setCarregandoSugestoes] = useState(false)
  const [obtendoLocalizacao, setObtendoLocalizacao] = useState(false)
  const [buscandoEndereco, setBuscandoEndereco] = useState(false)

  const [cep, setCep] = useState('')
  const [numeroCep, setNumeroCep] = useState('')
  const [carregandoCep, setCarregandoCep] = useState(false)

  const [origem, setOrigem] = useState(null)
  const [raioMetros, setRaioMetros] = useState(3000)
  const [dados, setDados] = useState(null)
  const [carregando, setCarregando] = useState(false)
  const [erro, setErro] = useState(null)
  const [farmaciaSelecionada, setFarmaciaSelecionada] = useState(null)

  const digitadoPeloUsuarioRef = useRef(false)
  const campoBuscaRef = useRef(null)
  const mapaRef = useRef(null)
  const marcadoresRef = useRef({})

  const definirMapa = useCallback((mapa) => {
    mapaRef.current = mapa
  }, [])

  // Autocomplete: busca sugestões de endereço na Nominatim a partir de 3 caracteres.
  useEffect(() => {
    if (!digitadoPeloUsuarioRef.current) return undefined

    const texto = textoBusca.trim()
    if (texto.length < 3) return undefined

    const controlador = new AbortController()
    const idTimeout = setTimeout(async () => {
      // Se o usuário já disparou uma busca explícita (botão "Buscar" ou clique
      // numa sugestão) enquanto esse debounce esperava, descarta o resultado —
      // senão ele "vaza" por cima da busca que já foi feita.
      if (!digitadoPeloUsuarioRef.current) return
      setCarregandoSugestoes(true)
      try {
        const resposta = await fetch(
          `${URL_NOMINATIM}?q=${encodeURIComponent(texto)}&format=json&limit=5&countrycodes=br`,
          { signal: controlador.signal },
        )
        if (!digitadoPeloUsuarioRef.current) return
        const lista = resposta.ok ? await resposta.json() : []
        setSugestoes(lista)
        setMostrarSugestoes(true)
      } catch (erroRequisicao) {
        if (erroRequisicao.name === 'AbortError' || !digitadoPeloUsuarioRef.current) return
        setSugestoes([])
        setMostrarSugestoes(true)
      } finally {
        setCarregandoSugestoes(false)
      }
    }, 450)

    return () => {
      clearTimeout(idTimeout)
      controlador.abort()
    }
  }, [textoBusca])

  // Fecha o dropdown de sugestões ao clicar fora do campo de busca.
  useEffect(() => {
    function aoClicarFora(evento) {
      if (campoBuscaRef.current && !campoBuscaRef.current.contains(evento.target)) {
        setMostrarSugestoes(false)
      }
    }
    document.addEventListener('mousedown', aoClicarFora)
    return () => document.removeEventListener('mousedown', aoClicarFora)
  }, [])

  // Busca as farmácias sempre que o ponto de origem ou o raio mudarem.
  // A origem já vem com lat/lon resolvidos (sugestão ou geolocalização), sem nova geocodificação.
  useEffect(() => {
    if (!origem) return undefined

    const controlador = new AbortController()
    ;(async () => {
      setCarregando(true)
      setErro(null)
      try {
        const json = await api.get(
          `/api/farmacias?lat=${origem.latitude}&lon=${origem.longitude}&raio=${raioMetros}`,
          { signal: controlador.signal },
        )
        setDados(json)
        setFarmaciaSelecionada(null)
      } catch (erroRequisicao) {
        if (erroRequisicao.name === 'AbortError') return
        setErro(erroRequisicao.message || 'Não foi possível conectar ao servidor.')
        setDados(null)
      } finally {
        setCarregando(false)
      }
    })()

    return () => controlador.abort()
  }, [origem, raioMetros])

  // A cada busca, o mapa fica centralizado no endereço de origem, com zoom
  // suficiente para mostrar todas as farmácias encontradas: o enquadramento é
  // um retângulo simétrico em volta da origem (a maior distância em cada eixo,
  // para os dois lados), então o centro dele é sempre a própria origem.
  useEffect(() => {
    if (!mapaRef.current || !dados?.origem) return
    const { latitude, longitude } = dados.origem
    if (dados.farmacias.length === 0) {
      mapaRef.current.flyTo([latitude, longitude], 15, { duration: 0.5 })
      return
    }
    const deltaLat = Math.max(...dados.farmacias.map((f) => Math.abs(f.latitude - latitude)))
    const deltaLon = Math.max(...dados.farmacias.map((f) => Math.abs(f.longitude - longitude)))
    mapaRef.current.flyToBounds(
      [
        [latitude - deltaLat, longitude - deltaLon],
        [latitude + deltaLat, longitude + deltaLon],
      ],
      { padding: [40, 40], maxZoom: 17, duration: 0.5 },
    )
  }, [dados])

  useEffect(() => {
    if (farmaciaSelecionada == null || !mapaRef.current || !dados) return
    const farmacia = dados.farmacias[farmaciaSelecionada]
    if (!farmacia) return
    mapaRef.current.flyTo([farmacia.latitude, farmacia.longitude], 16, { duration: 0.5 })
    marcadoresRef.current[farmaciaSelecionada]?.openPopup()
  }, [farmaciaSelecionada, dados])

  function selecionarSugestao(sugestao) {
    digitadoPeloUsuarioRef.current = false
    setTextoBusca(sugestao.display_name)
    setSugestoes([])
    setMostrarSugestoes(false)
    setOrigem({ latitude: Number(sugestao.lat), longitude: Number(sugestao.lon), rotulo: sugestao.display_name })
  }

  function usarLocalizacaoAtual() {
    if (!navigator.geolocation) {
      mostrarToast('Seu navegador não suporta geolocalização.')
      return
    }
    setObtendoLocalizacao(true)
    navigator.geolocation.getCurrentPosition(
      (posicao) => {
        const { latitude, longitude } = posicao.coords
        digitadoPeloUsuarioRef.current = false
        setTextoBusca('Minha localização atual')
        setSugestoes([])
        setMostrarSugestoes(false)
        setOrigem({ latitude, longitude, rotulo: 'Minha localização atual' })
        setObtendoLocalizacao(false)
      },
      () => {
        mostrarToast('Não foi possível obter sua localização. Verifique a permissão do navegador.')
        setObtendoLocalizacao(false)
      },
      { enableHighAccuracy: true, timeout: 10000 },
    )
  }

  async function buscarPorEndereco() {
    const texto = textoBusca.trim()
    if (texto.length < 3) {
      mostrarToast('Digite pelo menos 3 letras do endereço.')
      return
    }

    setMostrarSugestoes(false)
    setBuscandoEndereco(true)
    try {
      const resultado = await geocodificarTexto(texto)
      if (!resultado) {
        mostrarToast('Não encontramos esse endereço. Tente detalhar mais.')
        return
      }
      digitadoPeloUsuarioRef.current = false
      setSugestoes([])
      setOrigem({ latitude: Number(resultado.lat), longitude: Number(resultado.lon), rotulo: resultado.display_name || texto })
    } catch {
      mostrarToast('Não foi possível buscar esse endereço agora.')
    } finally {
      setBuscandoEndereco(false)
    }
  }

  async function geocodificarTexto(texto) {
    const resposta = await fetch(`${URL_NOMINATIM}?q=${encodeURIComponent(texto)}&format=json&limit=1&countrycodes=br`)
    if (!resposta.ok) return null
    const lista = await resposta.json()
    return lista[0] || null
  }

  async function buscarPorCep() {
    const cepLimpo = cep.replace(/\D/g, '')
    if (cepLimpo.length !== 8) {
      mostrarToast('Digite um CEP válido com 8 dígitos.')
      return
    }

    setCarregandoCep(true)
    try {
      const respostaCep = await fetch(`${URL_VIACEP}/${cepLimpo}/json/`)
      const dadosCep = await respostaCep.json()
      if (!respostaCep.ok || dadosCep.erro) {
        mostrarToast('CEP não encontrado.')
        return
      }

      const numero = numeroCep.trim()
      const enderecoCompleto = [
        [dadosCep.logradouro, numero].filter(Boolean).join(', '),
        dadosCep.bairro,
        [dadosCep.localidade, dadosCep.uf].filter(Boolean).join(' - '),
      ]
        .filter(Boolean)
        .join(', ')

      let resultado = await geocodificarTexto(enderecoCompleto)

      if (!resultado && numero) {
        const enderecoSemNumero = [dadosCep.logradouro, dadosCep.bairro, [dadosCep.localidade, dadosCep.uf].filter(Boolean).join(' - ')]
          .filter(Boolean)
          .join(', ')
        resultado = await geocodificarTexto(enderecoSemNumero)
      }

      if (!resultado) {
        mostrarToast('Encontramos o CEP, mas não foi possível localizá-lo no mapa.')
        return
      }

      digitadoPeloUsuarioRef.current = false
      setTextoBusca(enderecoCompleto)
      setSugestoes([])
      setMostrarSugestoes(false)
      setOrigem({ latitude: Number(resultado.lat), longitude: Number(resultado.lon), rotulo: enderecoCompleto })
    } catch {
      mostrarToast('Não foi possível buscar esse CEP agora.')
    } finally {
      setCarregandoCep(false)
    }
  }

  const centroInicial = useMemo(() => [ORIGEM_PADRAO.latitude, ORIGEM_PADRAO.longitude], [])
  const semSugestoes = mostrarSugestoes && !carregandoSugestoes && sugestoes.length === 0 && textoBusca.trim().length >= 3

  return (
    <>
      <Cabecalho kicker="Localização" titulo="Farmácias" aoAbrirMenu={abrirMenu} />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo farmacias">
          <Cartao titulo="Buscar farmácias próximas" className="farmacias__busca">
            <div className="farmacias__campos">
              <div className="farmacias__campo-busca-wrap" ref={campoBuscaRef}>
                <div className="farmacias__campo-busca-linha">
                  <Campo
                    className="farmacias__campo-endereco"
                    rotulo="Endereço de origem"
                    placeholder="Digite ao menos 3 letras..."
                    value={textoBusca}
                    onChange={(e) => {
                      const valor = e.target.value
                      digitadoPeloUsuarioRef.current = true
                      setTextoBusca(valor)
                      if (valor.trim().length < 3) {
                        setSugestoes([])
                        setMostrarSugestoes(false)
                      }
                    }}
                    onFocus={() => sugestoes.length > 0 && setMostrarSugestoes(true)}
                    onKeyDown={(e) => e.key === 'Enter' && buscarPorEndereco()}
                    autoComplete="off"
                  />
                  <Botao
                    variante="secundario"
                    tamanho="pequeno"
                    className="farmacias__botao-buscar-endereco"
                    onClick={buscarPorEndereco}
                    disabled={buscandoEndereco}
                  >
                    {buscandoEndereco ? (
                      <>
                        <Spinner tamanho={16} /> Buscando...
                      </>
                    ) : (
                      'Buscar'
                    )}
                  </Botao>
                </div>
                {mostrarSugestoes && (
                  <div className="farmacias__sugestoes">
                    {carregandoSugestoes && <div className="farmacias__sugestoes-estado">Buscando sugestões...</div>}
                    {!carregandoSugestoes &&
                      sugestoes.map((sugestao) => (
                        <button
                          key={`${sugestao.place_id}`}
                          type="button"
                          className="farmacias__sugestao"
                          onClick={() => selecionarSugestao(sugestao)}
                        >
                          {sugestao.display_name}
                        </button>
                      ))}
                    {semSugestoes && (
                      <div className="farmacias__sugestoes-estado">Nenhum endereço encontrado, tente detalhar mais</div>
                    )}
                  </div>
                )}
              </div>

              <Botao
                variante="contorno"
                tamanho="pequeno"
                className="farmacias__botao-localizacao"
                onClick={usarLocalizacaoAtual}
                disabled={obtendoLocalizacao}
              >
                {obtendoLocalizacao ? (
                  <Spinner tamanho={16} />
                ) : (
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="12" cy="12" r="3" />
                    <path d="M12 2v3M12 19v3M2 12h3M19 12h3" />
                  </svg>
                )}
                {obtendoLocalizacao ? 'Localizando...' : 'Usar minha localização atual'}
              </Botao>

              <div className="farmacias__raio">
                <label className="campo__rotulo">Raio de busca</label>
                <div className="farmacias__opcoes-raio">
                  {OPCOES_RAIO.map((opcao) => (
                    <button
                      key={opcao.valor}
                      type="button"
                      className={`farmacias__opcao-raio${raioMetros === opcao.valor ? ' farmacias__opcao-raio--ativa' : ''}`}
                      onClick={() => setRaioMetros(opcao.valor)}
                    >
                      {opcao.rotulo}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="farmacias__cep">
              <span className="farmacias__cep-rotulo">Ou busque pelo CEP</span>
              <div className="farmacias__cep-campos">
                <Campo
                  className="farmacias__cep-campo"
                  rotulo="CEP"
                  placeholder="00000-000"
                  maxLength={9}
                  value={cep}
                  onChange={(e) => setCep(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && buscarPorCep()}
                />
                <Campo
                  className="farmacias__cep-numero"
                  rotulo="Número"
                  placeholder="Opcional"
                  value={numeroCep}
                  onChange={(e) => setNumeroCep(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && buscarPorCep()}
                />
                <Botao variante="secundario" tamanho="pequeno" onClick={buscarPorCep} disabled={carregandoCep}>
                  {carregandoCep ? (
                    <>
                      <Spinner tamanho={16} /> Buscando...
                    </>
                  ) : (
                    'Buscar CEP'
                  )}
                </Botao>
              </div>
            </div>

            {carregando && (
              <p className="farmacias__estado farmacias__estado--carregando">
                <Spinner tamanho={18} /> Buscando farmácias próximas... isso pode levar até 20 segundos.
              </p>
            )}
            {erro && !carregando && <p className="farmacias__estado farmacias__estado--erro">{erro}</p>}
          </Cartao>

          <Cartao className="farmacias__mapa-cartao">
            <MapContainer center={centroInicial} zoom={14} className="farmacias__mapa">
              <ControladorMapa aoInicializar={definirMapa} />
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> colaboradores'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              {dados?.origem && (
                <Marker position={[dados.origem.latitude, dados.origem.longitude]} icon={iconeOrigem}>
                  <Popup>
                    <strong>Ponto de origem</strong>
                    <br />
                    {origem?.rotulo}
                  </Popup>
                </Marker>
              )}
              {dados?.farmacias.map((farmacia, indice) => (
                <Marker
                  key={`${farmacia.latitude}-${farmacia.longitude}-${indice}`}
                  position={[farmacia.latitude, farmacia.longitude]}
                  icon={criarIconeFarmacia(farmaciaSelecionada === indice)}
                  ref={(instancia) => {
                    if (instancia) marcadoresRef.current[indice] = instancia
                  }}
                  eventHandlers={{ click: () => setFarmaciaSelecionada(indice) }}
                >
                  <Popup>
                    <strong>{farmacia.nome}</strong>
                    <br />
                    {farmacia.endereco}
                    <br />
                    {formatarDistancia(farmacia.distanciaMetros)}
                    <br />
                    <button type="button" className="farmacias__popup-rota" onClick={() => abrirComoChegar(farmacia)}>
                      Como chegar
                    </button>
                  </Popup>
                </Marker>
              ))}
            </MapContainer>
          </Cartao>

          <Cartao
            titulo={`Farmácias encontradas${dados ? ` (${dados.farmacias.length})` : ''}`}
            className="farmacias__lista-cartao"
          >
            {!carregando && !erro && !dados && (
              <p className="farmacias__estado">
                Digite um endereço, busque por CEP ou use sua localização atual para ver farmácias próximas.
              </p>
            )}
            {!carregando && dados && dados.farmacias.length === 0 && (
              <p className="farmacias__estado">Nenhuma farmácia encontrada nesse raio.</p>
            )}
            <div className="farmacias__lista">
              {dados?.farmacias.map((farmacia, indice) => (
                <div
                  key={`${farmacia.latitude}-${farmacia.longitude}-${indice}`}
                  className={`farmacias__item${farmaciaSelecionada === indice ? ' farmacias__item--selecionado' : ''}`}
                  role="button"
                  tabIndex={0}
                  onClick={() => setFarmaciaSelecionada(indice)}
                  onKeyDown={(evento) => evento.key === 'Enter' && setFarmaciaSelecionada(indice)}
                >
                  <div className="farmacias__item-info">
                    <div className="farmacias__item-nome">{farmacia.nome}</div>
                    <div className="farmacias__item-endereco">{farmacia.endereco}</div>
                  </div>
                  <div className="farmacias__item-lado">
                    <div className="farmacias__item-distancia">{formatarDistancia(farmacia.distanciaMetros)}</div>
                    <button
                      type="button"
                      className="farmacias__item-rota"
                      onClick={(evento) => {
                        evento.stopPropagation()
                        abrirComoChegar(farmacia)
                      }}
                    >
                      Como chegar
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </Cartao>
        </div>
      </div>
    </>
  )
}
