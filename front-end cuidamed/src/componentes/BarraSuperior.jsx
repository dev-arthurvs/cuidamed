import { useEffect, useRef, useState } from 'react'
import { Link, NavLink, useLocation, useNavigate } from 'react-router-dom'
import { useApp } from '../contexto/useApp'
import { obterSecaoAjuda } from '../utilitarios/ajudaConteudo'
import { ICONES_NAVEGACAO, ITENS_NAVEGACAO } from './itensNavegacao'
import LogoMarca from './LogoMarca'
import ModalAjuda from './ModalAjuda'
import './BarraSuperior.css'

const ROTAS_POR_PACIENTE = new Set(['/agenda', '/ciclos-encerrados', '/historico'])

export default function BarraSuperior() {
  const { usuario, pacientes, pacienteFoco, selecionarPaciente } = useApp()
  const navegar = useNavigate()
  const location = useLocation()
  // Dois estados separados: "passando o mouse" mostra a lista (prévia) e o
  // clique "trava" a lista aberta até escolher um paciente, clicar fora ou
  // apertar Esc. Antes era um estado só, e o clique fechava a lista que o
  // mouse tinha acabado de abrir.
  const [itemSobMouse, setItemSobMouse] = useState(null)
  const [itemTravado, setItemTravado] = useState(null)
  const [ajudaAberta, setAjudaAberta] = useState(false)
  const referencia = useRef(null)
  const temporizadorSaida = useRef(null)
  const ehCuidador = usuario?.tipo === 'cuidador'
  const secaoAjuda = obterSecaoAjuda(location.pathname, usuario?.tipo)

  function fecharTudo() {
    clearTimeout(temporizadorSaida.current)
    setItemSobMouse(null)
    setItemTravado(null)
  }

  useEffect(() => {
    function aoClicarFora(evento) {
      if (referencia.current && !referencia.current.contains(evento.target)) fecharTudo()
    }
    function aoApertarTecla(evento) {
      if (evento.key === 'Escape') fecharTudo()
    }
    document.addEventListener('mousedown', aoClicarFora)
    document.addEventListener('keydown', aoApertarTecla)
    return () => {
      document.removeEventListener('mousedown', aoClicarFora)
      document.removeEventListener('keydown', aoApertarTecla)
      clearTimeout(temporizadorSaida.current)
    }
  }, [])

  function aoEntrarNoMenu(rota) {
    clearTimeout(temporizadorSaida.current)
    setItemSobMouse(rota)
  }

  // Pequena folga antes de fechar a prévia: se o mouse escapa por um instante
  // no caminho até a lista, ela não some.
  function aoSairDoMenu(rota) {
    clearTimeout(temporizadorSaida.current)
    temporizadorSaida.current = setTimeout(() => {
      setItemSobMouse((atual) => (atual === rota ? null : atual))
    }, 150)
  }

  // Clique no menu: trava a lista aberta; clicar de novo no mesmo menu destrava e fecha.
  function alternarTrava(rota) {
    if (itemTravado === rota) {
      setItemTravado(null)
      setItemSobMouse(null)
    } else {
      setItemTravado(rota)
    }
  }

  function escolherPaciente(rota, paciente) {
    selecionarPaciente(paciente.id)
    navegar(rota)
    fecharTudo()
  }

  return (
    <nav className="barra-superior" ref={referencia}>
      <Link to="/painel" className="barra-superior__logo" aria-label="Ir para o início">
        <LogoMarca tamanho={30} tamanhoTexto={18} />
      </Link>
      <div className="barra-superior__itens">
        {ITENS_NAVEGACAO.map((item) => {
          if (!(ehCuidador && ROTAS_POR_PACIENTE.has(item.rota))) {
            return (
              <NavLink
                key={item.rota}
                to={item.rota}
                className={({ isActive }) => `barra-superior__item${isActive ? ' barra-superior__item--ativo' : ''}`}
              >
                <span className="barra-superior__icone">{ICONES_NAVEGACAO[item.icone]}</span>
                <span className="barra-superior__rotulo">{item.rotulo}</span>
              </NavLink>
            )
          }

          // Com uma lista travada, só ela fica aberta; sem trava, abre a que está sob o mouse.
          const aberto = itemTravado ? itemTravado === item.rota : itemSobMouse === item.rota
          const travado = itemTravado === item.rota

          return (
            <div
              key={item.rota}
              className="barra-superior__grupo"
              onMouseEnter={() => aoEntrarNoMenu(item.rota)}
              onMouseLeave={() => aoSairDoMenu(item.rota)}
            >
              <button
                type="button"
                className={`barra-superior__item${aberto ? ' barra-superior__item--ativo' : ''}`}
                aria-expanded={aberto}
                aria-pressed={travado}
                title={travado ? 'Clique para fechar a lista' : 'Clique para fixar a lista aberta'}
                onClick={() => alternarTrava(item.rota)}
              >
                <span className="barra-superior__icone">{ICONES_NAVEGACAO[item.icone]}</span>
                <span className="barra-superior__rotulo">{item.rotulo}</span>
                <svg
                  className="barra-superior__seta"
                  width="12"
                  height="12"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M6 9l6 6 6-6" />
                </svg>
              </button>

              {aberto && (
                <div className="barra-superior__dropdown">
                  <div className="barra-superior__dropdown-titulo">Ver {item.rotulo.toLowerCase()} de qual paciente?</div>
                  {pacientes.map((paciente) => (
                    <button
                      type="button"
                      key={paciente.id}
                      className={`barra-superior__paciente${
                        pacienteFoco?.id === paciente.id ? ' barra-superior__paciente--selecionado' : ''
                      }`}
                      onClick={() => escolherPaciente(item.rota, paciente)}
                    >
                      <span className="barra-superior__paciente-avatar">{paciente.iniciais}</span>
                      <span className="barra-superior__paciente-nome">{paciente.nome}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>
          )
        })}
      </div>

      <button
        type="button"
        className="barra-superior__ajuda"
        onClick={() => setAjudaAberta(true)}
        aria-label="Ajuda sobre esta tela"
      >
        ?
      </button>

      {ajudaAberta && <ModalAjuda secao={secaoAjuda} onFechar={() => setAjudaAberta(false)} />}
    </nav>
  )
}
