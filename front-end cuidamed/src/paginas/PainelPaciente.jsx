import { useState } from 'react'
import { useNavigate, useOutletContext, useParams } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Cabecalho from '../componentes/Cabecalho'
import VoltarDetalhesPaciente from '../componentes/VoltarDetalhesPaciente'
import Cartao from '../componentes/Cartao'
import ModalConfirmacao from '../componentes/ModalConfirmacao'
import { useApp } from '../contexto/useApp'
import './PainelPaciente.css'

export default function PainelPaciente() {
  const { pacientes, atualizarPermissaoAlteracoes, desvincularPaciente, mostrarToast } = useApp()
  const { pacienteId } = useParams()
  const navegar = useNavigate()
  const { abrirMenu } = useOutletContext()
  const [alterandoPermissao, setAlterandoPermissao] = useState(false)
  const [desvinculando, setDesvinculando] = useState(false)
  const [confirmandoDesvinculo, setConfirmandoDesvinculo] = useState(false)

  const paciente = pacientes.find((item) => String(item.id) === pacienteId)
  if (!paciente) return null

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

  const pacienteSemLoginProprio = !paciente.email

  return (
    <>
      <Cabecalho kicker="Painel Paciente" titulo={paciente.nome} aoAbrirMenu={abrirMenu} />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo painel-paciente">
          <VoltarDetalhesPaciente paciente={paciente} />

          <Cartao titulo="Permite alterações">
            <div className="painel-paciente__linha-permissao">
              <div>
                <p className="painel-paciente__descricao">
                  Quando ativado, {paciente.nome.split(' ')[0]} pode adicionar, editar e excluir medicamentos na própria
                  agenda. Quando desativado, apenas você pode fazer essas alterações.
                </p>
              </div>
              <label className="painel-paciente__toggle">
                <input
                  type="checkbox"
                  checked={paciente.permiteAlteracoes}
                  disabled={alterandoPermissao}
                  onChange={alternarPermissao}
                />
                <span className="painel-paciente__toggle-trilho">
                  <span className="painel-paciente__toggle-bola" />
                </span>
              </label>
            </div>
          </Cartao>

          <Cartao titulo="Desvincular paciente" className="painel-paciente__zona-risco">
            <p className="painel-paciente__descricao">
              Ao desvincular, você deixa de acompanhar {paciente.nome} e ele(a) some da sua lista de pacientes. Essa ação só
              pode ser feita por você, o cuidador.
              {pacienteSemLoginProprio && (
                <>
                  {' '}
                  <strong>Atenção:</strong> esse paciente não tem e-mail/senha próprios cadastrados — ao desvincular, ele(a)
                  ficará sem nenhum cuidador responsável e sem forma de acessar o sistema, até que outro cuidador o cadastre
                  novamente.
                </>
              )}
            </p>
            <Botao variante="perigo" onClick={() => setConfirmandoDesvinculo(true)} disabled={desvinculando}>
              Desvincular paciente
            </Botao>
          </Cartao>
        </div>
      </div>

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
