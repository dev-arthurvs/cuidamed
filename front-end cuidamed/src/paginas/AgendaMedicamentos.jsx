import { AnimatePresence, motion } from 'framer-motion'
import { useState } from 'react'
import { Link, useOutletContext } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Cabecalho from '../componentes/Cabecalho'
import VoltarDetalhesPaciente from '../componentes/VoltarDetalhesPaciente'
import LogoMarca from '../componentes/LogoMarca'
import ModalConfirmacao from '../componentes/ModalConfirmacao'
import { useApp } from '../contexto/useApp'
import { TRANSICAO_ITEM_LISTA, VARIANTES_ITEM_LISTA } from '../utilitarios/animacoes'
import {
  calcularEstoque,
  formatarDataCurta,
  medicamentoEncerrado,
  medicamentoIniciado,
  proximoDiaDeDose,
  temDoseNoDia,
} from '../utilitarios/horarios'
import FormularioMedicamento from './FormularioMedicamento'
import './AgendaMedicamentos.css'

// "dura 3 dias" / "dura 1 dia" / "não dá para o dia todo" (antes: "dura ~0 dias").
function descreverDuracao(dias) {
  if (dias <= 0) return 'não dá para o dia todo'
  return `dura ${dias} dia${dias === 1 ? '' : 's'}`
}

export default function AgendaMedicamentos() {
  const { pacienteFoco, usuario, excluirMedicamento, mostrarToast } = useApp()
  const { abrirMenu } = useOutletContext()
  const [medicamentoParaExcluir, setMedicamentoParaExcluir] = useState(null)
  const [medicamentoNoModal, setMedicamentoNoModal] = useState(undefined)

  if (!pacienteFoco) {
    return (
      <>
        <Cabecalho kicker="Agenda de medicamentos" titulo="Nenhum paciente selecionado" aoAbrirMenu={abrirMenu} />
        <div className="pagina-corpo">
          <p>Selecione um paciente no painel do cuidador para ver a agenda.</p>
        </div>
      </>
    )
  }

  const medicamentosAtivos = pacienteFoco.medicamentos.filter(
    (medicamento) => !medicamentoEncerrado(medicamento, undefined, pacienteFoco.historico),
  )
  const totalEncerrados = pacienteFoco.medicamentos.length - medicamentosAtivos.length
  const kicker = usuario.tipo === 'cuidador' ? `Agenda de ${pacienteFoco.nome.split(' ')[0]}` : 'Agenda de medicamentos'
  const podeEditar = usuario.tipo === 'cuidador' || pacienteFoco.permiteAlteracoes

  async function confirmarExclusao() {
    try {
      await excluirMedicamento(pacienteFoco.id, medicamentoParaExcluir.id)
      mostrarToast('Medicamento excluído.')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível excluir o medicamento.')
    } finally {
      setMedicamentoParaExcluir(null)
    }
  }

  return (
    <>
      <Cabecalho kicker={kicker} titulo={`${medicamentosAtivos.length} medicamentos cadastrados`} aoAbrirMenu={abrirMenu} />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo agenda">
          <VoltarDetalhesPaciente paciente={pacienteFoco} />
          <div className="agenda__topo">
            {!podeEditar && (
              <p className="agenda__descricao">
                Seu cuidador ainda não liberou alterações nessa agenda. Fale com ele(a) se precisar ajustar algo.
              </p>
            )}
            <div className="agenda__topo-acoes">
              <Link to="/ciclos-encerrados" className="agenda__link-encerrados">
                Ciclos encerrados{totalEncerrados > 0 ? ` (${totalEncerrados})` : ''}
              </Link>
              {podeEditar && (
                <Botao onClick={() => setMedicamentoNoModal(null)}>
                  <span style={{ fontSize: 24, lineHeight: 1 }}>+</span>
                  <span>Inserir medicamento</span>
                </Botao>
              )}
            </div>
          </div>

          <div className="agenda__grade">
            <AnimatePresence>
            {medicamentosAtivos.map((medicamento) => {
              const estoque = calcularEstoque(medicamento, pacienteFoco.historico)
              const iniciado = medicamentoIniciado(medicamento)
              const proximaDose = iniciado && !temDoseNoDia(medicamento) ? proximoDiaDeDose(medicamento) : null
              return (
              <motion.div
                className="agenda__cartao"
                key={medicamento.id}
                layout
                initial={VARIANTES_ITEM_LISTA.initial}
                animate={VARIANTES_ITEM_LISTA.animate}
                exit={VARIANTES_ITEM_LISTA.exit}
                transition={TRANSICAO_ITEM_LISTA}
              >
                <div className="agenda__cartao-cabecalho">
                  <div className="agenda__cartao-icone">
                    <LogoMarca comTexto={false} tamanho={24} />
                  </div>
                  <div className="agenda__cartao-info">
                    <div className="agenda__cartao-nome">{medicamento.nome}</div>
                    <div className="agenda__cartao-dose">
                      {medicamento.dosagem} · {medicamento.forma}
                    </div>
                  </div>
                </div>
                <div className="agenda__cartao-pilulas">
                  {medicamento.horarios.map((horario) => (
                    <span className="agenda__pilula agenda__pilula--horario" key={horario}>
                      {horario}
                    </span>
                  ))}
                  <span className="agenda__pilula agenda__pilula--frequencia">{medicamento.frequencia}</span>
                  {!iniciado && (
                    <span className="agenda__pilula agenda__pilula--inicio">Começa em {formatarDataCurta(medicamento.inicio)}</span>
                  )}
                  {proximaDose && (
                    <span className="agenda__pilula agenda__pilula--inicio">Próxima dose: {formatarDataCurta(proximaDose)}</span>
                  )}
                </div>
                {estoque && (
                  <div
                    className={`agenda__estoque${
                      estoque.esgotado
                        ? ' agenda__estoque--esgotado'
                        : estoque.duraAteOFim
                          ? ' agenda__estoque--suficiente'
                          : estoque.baixo
                            ? ' agenda__estoque--baixo'
                            : ''
                    }`}
                  >
                    {estoque.esgotado
                      ? '⚠️ Estoque esgotado — Reponha o quanto antes.'
                      : estoque.duraAteOFim
                        ? `✅ Estoque suficiente — (até ${formatarDataCurta(medicamento.fim)}).`
                      : estoque.baixo
                        ? `⚠️ Estoque baixo: ${estoque.quantidade} ${estoque.unidade} restantes — (${descreverDuracao(estoque.diasRestantes)}).`
                        : `Estoque: ${estoque.quantidade} ${estoque.unidade} — (${descreverDuracao(estoque.diasRestantes)}).`}
                  </div>
                )}
                {podeEditar && (
                  <div className="agenda__cartao-acoes">
                    <Botao variante="secundario" tamanho="pequeno" larguraTotal onClick={() => setMedicamentoNoModal(medicamento)}>
                      Editar
                    </Botao>
                    <Botao variante="perigo" tamanho="pequeno" larguraTotal onClick={() => setMedicamentoParaExcluir(medicamento)}>
                      Excluir
                    </Botao>
                  </div>
                )}
              </motion.div>
              )
            })}
            </AnimatePresence>
            {medicamentosAtivos.length === 0 && (
              <p style={{ color: 'var(--texto-suave)' }}>Nenhum medicamento ativo cadastrado no momento.</p>
            )}
          </div>
        </div>
      </div>

      {medicamentoNoModal !== undefined && (
        <FormularioMedicamento medicamentoExistente={medicamentoNoModal} aoFechar={() => setMedicamentoNoModal(undefined)} />
      )}

      {medicamentoParaExcluir && (
        <ModalConfirmacao
          titulo="Excluir medicamento?"
          mensagem={`Tem certeza que deseja excluir "${medicamentoParaExcluir.nome}" da agenda? Essa ação não pode ser desfeita.`}
          textoConfirmar="Sim, excluir"
          onCancelar={() => setMedicamentoParaExcluir(null)}
          onConfirmar={confirmarExclusao}
        />
      )}
    </>
  )
}
