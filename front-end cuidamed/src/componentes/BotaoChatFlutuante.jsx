import { Link, useLocation } from 'react-router-dom'
import { useApp } from '../contexto/useApp'
import './BotaoChatFlutuante.css'

// Chat é uma conversa sobre a própria rotina de remédios (primeira pessoa) —
// só faz sentido pro paciente, não pro cuidador.
export default function BotaoChatFlutuante() {
  const { usuario } = useApp()
  const location = useLocation()

  if (usuario?.tipo !== 'paciente' || location.pathname.startsWith('/chat')) return null

  return (
    <Link to="/chat" className="botao-chat-flutuante" aria-label="Abrir chat com o assistente">
      <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M4 5.5h16v10H9l-4.5 4v-4H4z" />
      </svg>
    </Link>
  )
}
