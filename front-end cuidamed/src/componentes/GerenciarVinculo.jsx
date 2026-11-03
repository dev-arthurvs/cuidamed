import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useApp } from '../contexto/useApp'
import Botao from './Botao'
import Cartao from './Cartao'
import ModalConfirmacao from './ModalConfirmacao'
import './GerenciarVinculo.css'

// Parte final dos detalhes do paciente (só o cuidador vê): permissão para o
// paciente alterar a própria agenda e o desvínculo. Antes era uma tela à parte.
export default function GerenciarVinculo({ paciente }) {
  const { atualizarPermissaoAlteracoes, desvincularPaciente, mostrarToast } = useApp()
  const navegar = useNavigate()
  const [alterandoPermissao, setAlterandoPermissao] = useState(false)
  const [desvinculando, setDesvinculando] = useState(false)
  const [confirmandoDesvinculo, setConfirmandoDesvinculo] = useState(false)

  async function alternarPermissao(evento) {
    const novoValor = evento.target.checked
    setAlterandoPermissao(true)
    try {
      await atualizarPermissaoAlteracoes(paciente.id, novoValor)
      mostrarToast(novoValor ? 'Paciente agora pode alterar a própria agenda.' : 'Alterações da agenda bloqueadas para o paciente.')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível atualizar a permissão.')
    } finally {
      setAlterandoPermissao(false)
    }
  }

  async function confirmarDesvinculo() {
    setDesvinculando(true)
    try {
      await desvincularPaciente(paciente.id)
      mostrarToast(`${paciente.nome} foi desvinculado(a) da sua conta.`)
      navegar('/painel')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível desvincular o paciente.')
    } finally {
      setDesvinculando(false)
      setConfirmandoDesvinculo(false)
    }
  }

  const pacienteSemLoginProprio = !paciente.email && !paciente.telefone

  return (
    <>
      <Cartao titulo="Permite alterações">
        <div className="painel-paciente__linha-permissao">
          <p className="painel-paciente__descricao">
            Quando ativado, {paciente.nome.split(' ')[0]} pode adicionar, editar e excluir medicamentos na própria agenda.
            Quando desativado, apenas você pode fazer essas alterações.
          </p>
          <label className="painel-paciente__toggle">
            <input type="checkbox" checked={paciente.permiteAlteracoes} disabled={alterandoPermissao} onChange={alternarPermissao} />
            <span className="painel-paciente__toggle-trilho">
              <span className="painel-paciente__toggle-bola" />
            </span>
          </label>
        </div>
      </Cartao>

      <Cartao titulo="Desvincular paciente" className="painel-paciente__zona-risco">
        <p className="painel-paciente__descricao">
          Ao desvincular, você deixa de acompanhar {paciente.nome} e ele(a) some da sua lista de pacientes. Essa ação só pode
          ser feita por você, o cuidador.
          {pacienteSemLoginProprio && (
            <>
              {' '}
              <strong>Atenção:</strong> esse paciente não tem e-mail, telefone ou senha próprios cadastrados — ao desvincular,
              ele(a) ficará sem nenhum cuidador responsável e sem forma de acessar o sistema, até que outro cuidador o cadastre
              novamente.
            </>
          )}
        </p>
        <Botao variante="perigo" onClick={() => setConfirmandoDesvinculo(true)} disabled={desvinculando}>
          Desvincular paciente
        </Botao>
      </Cartao>

      {confirmandoDesvinculo && (
        <ModalConfirmacao
          titulo="Desvincular paciente?"
          mensagem={`Tem certeza que deseja desvincular ${paciente.nome} da sua conta?${
            pacienteSemLoginProprio ? ' Esse paciente ficará sem nenhum cuidador responsável.' : ''
          }`}
          textoConfirmar="Sim, desvincular"
          onCancelar={() => setConfirmandoDesvinculo(false)}
          onConfirmar={confirmarDesvinculo}
        />
      )}
    </>
  )
}
