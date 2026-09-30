import { AnimatePresence, motion } from 'framer-motion'
import { useOutletContext } from 'react-router-dom'
import Cabecalho from '../componentes/Cabecalho'
import VoltarDetalhesPaciente from '../componentes/VoltarDetalhesPaciente'
import LogoMarca from '../componentes/LogoMarca'
import { useApp } from '../contexto/useApp'
import { TRANSICAO_ITEM_LISTA, VARIANTES_ITEM_LISTA } from '../utilitarios/animacoes'
import { formatarDataCurta, medicamentoEncerrado } from '../utilitarios/horarios'
import './AgendaMedicamentos.css'
import './CiclosEncerrados.css'

export default function CiclosEncerrados() {
  const { pacienteFoco, usuario } = useApp()
  const { abrirMenu } = useOutletContext()

  if (!pacienteFoco) {
    return (
      <>
        <Cabecalho kicker="Agenda de medicamentos" titulo="Nenhum paciente selecionado" aoAbrirMenu={abrirMenu} />
        <div className="pagina-corpo">
          <p>Selecione um paciente no painel do cuidador para ver os ciclos encerrados.</p>
        </div>
      </>
    )
  }

  const medicamentosEncerrados = pacienteFoco.medicamentos.filter((medicamento) =>
    medicamentoEncerrado(medicamento, undefined, pacienteFoco.historico),
  )
  const titulo = usuario.tipo === 'cuidador' ? `Ciclos encerrados de ${pacienteFoco.nome}` : 'Ciclos encerrados'

  return (
    <>
      <Cabecalho kicker="Agenda de medicamentos" titulo={titulo} aoAbrirMenu={abrirMenu} />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo agenda">
          <VoltarDetalhesPaciente paciente={pacienteFoco} />

          <div className="agenda__grade ciclos-encerrados__grade">
            <AnimatePresence>
            {medicamentosEncerrados.map((medicamento) => (
              <motion.div
                className="agenda__cartao ciclos-encerrados__cartao"
                key={medicamento.id}
                layout
                initial={VARIANTES_ITEM_LISTA.initial}
                animate={VARIANTES_ITEM_LISTA.animate}
                exit={VARIANTES_ITEM_LISTA.exit}
                transition={TRANSICAO_ITEM_LISTA}
              >
                <div className="agenda__cartao-cabecalho">
                  <div className="agenda__cartao-icone ciclos-encerrados__icone">
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
                </div>
                <div className="ciclos-encerrados__periodo">
                  Ciclo de {formatarDataCurta(medicamento.inicio)} até {formatarDataCurta(medicamento.fim)}
                </div>
                {medicamento.observacoes && <div className="ciclos-encerrados__observacoes">{medicamento.observacoes}</div>}
              </motion.div>
            ))}
            </AnimatePresence>
            {medicamentosEncerrados.length === 0 && (
              <p style={{ color: 'var(--texto-suave)' }}>Nenhum ciclo encerrado até o momento.</p>
            )}
          </div>
        </div>
      </div>

    </>
  )
}
