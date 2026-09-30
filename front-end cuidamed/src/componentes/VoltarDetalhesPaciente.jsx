import { useNavigate } from 'react-router-dom'
import { useApp } from '../contexto/useApp'
import Botao from './Botao'
import './VoltarDetalhesPaciente.css'

// "‹ Voltar para os detalhes do paciente" — no topo das telas abertas a partir
// dos detalhes do paciente (agenda, histórico, ciclos encerrados e painel do
// paciente). Só para o cuidador: o paciente não tem a tela de detalhes.
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
