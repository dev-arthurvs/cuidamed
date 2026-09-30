import { useEffect, useState } from 'react'
import { useApp } from '../contexto/useApp'
import { formatarDataPorExtenso, formatarHoraAtual, obterIniciais } from '../utilitarios/horarios'
import './Cabecalho.css'

export default function Cabecalho({ kicker, titulo, aoAbrirMenu }) {
  const { usuario } = useApp()
  const [agora, setAgora] = useState(() => new Date())

  useEffect(() => {
    const intervalo = setInterval(() => setAgora(new Date()), 30000)
    return () => clearInterval(intervalo)
  }, [])

  return (
    <header className="cabecalho">
      <div className="cabecalho__esquerda">
        <button type="button" className="cabecalho__menu" onClick={aoAbrirMenu} aria-label="Abrir menu de navegação">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.3" strokeLinecap="round">
            <path d="M4 7h16M4 12h16M4 17h16" />
          </svg>
        </button>
        <div className="cabecalho__titulos">
          <div className="cabecalho__kicker">{kicker}</div>
          <h1 className="cabecalho__titulo">{titulo}</h1>
        </div>
      </div>
      <div className="cabecalho__info">
        <div className="cabecalho__data">
          <div className="cabecalho__dia">{formatarDataPorExtenso(agora)}</div>
          <div className="cabecalho__hora">{formatarHoraAtual(agora)} · Agora</div>
        </div>
        <div className="cabecalho__avatar">{usuario ? obterIniciais(usuario.nome) : ''}</div>
      </div>
    </header>
  )
}
