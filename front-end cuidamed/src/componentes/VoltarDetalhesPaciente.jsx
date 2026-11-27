import { useNavigate } from 'react-router-dom'
import { useApp } from '../contexto/useApp'
import Botao from './Botao'
import './VoltarDetalhesPaciente.css'

export default function VoltarDetalhesPaciente({ paciente }) {
  const { usuario } = useApp()
  const navegar = useNavigate()
  if (usuario?.tipo !== 'cuidador' || !paciente) return null

  return (
    <div className="voltar-detalhes-paciente">
      <Botao variante="texto" onClick={() => navegar(`/cuidador/paciente/${paciente.id}`)}>
        ‹ Voltar para os detalhes do paciente
      </Botao>
    </div>
  )
}
