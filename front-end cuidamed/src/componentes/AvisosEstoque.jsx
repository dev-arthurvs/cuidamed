import { avisosEstoque } from '../utilitarios/horarios'
import Cartao from './Cartao'
import './AvisosEstoque.css'

// Remédios com estoque baixo ou esgotado. Sem nenhum, o card não aparece.
export default function AvisosEstoque({ paciente, className = '' }) {
  const avisos = avisosEstoque(paciente.medicamentosAtivos, paciente.historico)
  if (avisos.length === 0) return null

  return (
    <Cartao titulo="Estoque acabando" className={className}>
      <div className="avisos-estoque">
        {avisos.map((aviso) => (
          <div className={`avisos-estoque__item${aviso.esgotado ? ' avisos-estoque__item--esgotado' : ''}`} key={aviso.id}>
            <strong>{aviso.nome}</strong>
            <span>{aviso.texto}</span>
          </div>
        ))}
      </div>
    </Cartao>
  )
}
