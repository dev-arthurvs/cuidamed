import { useEffect, useState } from 'react'
import { useApp } from '../contexto/useApp'
import { formatarDataPorExtenso, formatarHoraAtual, obterIniciais } from '../utilitarios/horarios'
import './Cabecalho.css'

export default function Cabecalho({ kicker, titulo }) {
  const { usuario } = useApp()
  const [agora, setAgora] = useState(() => new Date())

  useEffect(() => {
    const intervalo = setInterval(() => setAgora(new Date()), 30000)
    return () => clearInterval(intervalo)
  }, [])

  return (
    <header className="cabecalho">
      <div className="cabecalho__esquerda">
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
