import { ESTILO_STATUS } from '../dados/dadosMock'
import './Rotulo.css'

export default function Rotulo({ status }) {
  const estilo = ESTILO_STATUS[status] || ESTILO_STATUS.pendente
  return (
    <span className="rotulo" style={{ background: estilo.fundo, color: estilo.texto }}>
      {estilo.rotulo}
    </span>
  )
}
