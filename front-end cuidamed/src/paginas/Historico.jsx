import { useMemo, useState } from 'react'
import { useOutletContext, useParams } from 'react-router-dom'
import Cabecalho from '../componentes/Cabecalho'
import VoltarDetalhesPaciente from '../componentes/VoltarDetalhesPaciente'
import Rotulo from '../componentes/Rotulo'
import { useApp } from '../contexto/useApp'
import { ESTILO_STATUS } from '../dados/dadosMock'
import './Historico.css'

const UM_DIA_MS = 24 * 60 * 60 * 1000

function diasDeDiferenca(dataIso, hoje) {
  const data = new Date(`${dataIso}T00:00:00`)
  return Math.round((hoje - data) / UM_DIA_MS)
}

function rotuloDoDia(dataIso, diferenca) {
  if (diferenca === 0) return `Hoje, ${formatarDiaMes(dataIso)}`
  if (diferenca === 1) return `Ontem, ${formatarDiaMes(dataIso)}`
  return formatarDiaMes(dataIso)
}

// Data local (não UTC) no formato do <input type="date">: AAAA-MM-DD.
function dataIsoLocal(data) {
  const mes = String(data.getMonth() + 1).padStart(2, '0')
  const dia = String(data.getDate()).padStart(2, '0')
  return `${data.getFullYear()}-${mes}-${dia}`
}

function formatarDiaMes(dataIso) {
  const data = new Date(`${dataIso}T00:00:00`)
  return data.toLocaleDateString('pt-BR', { day: 'numeric', month: 'long' })
}

export default function Historico() {
  const { pacientes, pacienteFoco, usuario } = useApp()
  const { pacienteId } = useParams()
  const { abrirMenu } = useOutletContext()
  const [filtroMedicamento, setFiltroMedicamento] = useState('todos')

  const paciente = pacienteId ? pacientes.find((item) => String(item.id) === pacienteId) : pacienteFoco

  const nomesMedicamentos = useMemo(() => {
    if (!paciente) return []
    return [...new Set(paciente.historico.map((item) => item.medicamento))].sort()
  }, [paciente])

  const hoje = useMemo(() => {
    const data = new Date()
    data.setHours(0, 0, 0, 0)
    return data
  }, [])

  // Período por datas "De" e "Até" (as duas começam em hoje). Datas futuras não
  // são aceitas e, se uma passar da outra, a outra acompanha — o intervalo
  // nunca fica invertido.
  const hojeIso = dataIsoLocal(hoje)
  const [dataInicio, setDataInicio] = useState(hojeIso)
  const [dataFim, setDataFim] = useState(hojeIso)

  function alterarInicio(valor) {
    if (!valor) return
    const data = valor > hojeIso ? hojeIso : valor
    setDataInicio(data)
    if (data > dataFim) setDataFim(data)
  }

  function alterarFim(valor) {
    if (!valor) return
    const data = valor > hojeIso ? hojeIso : valor
    setDataFim(data)
    if (data < dataInicio) setDataInicio(data)
  }

  const entradasFiltradas = useMemo(() => {
    if (!paciente) return []
    return paciente.historico
      .map((item) => ({ ...item, diferenca: diasDeDiferenca(item.data, hoje) }))
      .filter((item) => item.data >= dataInicio && item.data <= dataFim)
      .filter((item) => filtroMedicamento === 'todos' || item.medicamento === filtroMedicamento)
      .sort((a, b) => (a.data === b.data ? b.horario.localeCompare(a.horario) : b.data.localeCompare(a.data)))
  }, [paciente, hoje, dataInicio, dataFim, filtroMedicamento])

  if (!paciente) {
    return (
      <>
        <Cabecalho kicker="Registro de doses" titulo="Histórico" aoAbrirMenu={abrirMenu} />
        <div className="pagina-corpo">
          <p>Nenhum paciente selecionado.</p>
        </div>
      </>
    )
  }

  const contagem = {
    tomadas: entradasFiltradas.filter((item) => item.status === 'tomado').length,
    atrasadas: entradasFiltradas.filter((item) => item.status === 'atrasado').length,
    perdidas: entradasFiltradas.filter((item) => item.status === 'perdido').length,
  }

  return (
    <>
      <Cabecalho
        kicker="Registro de doses"
        titulo={usuario.tipo === 'cuidador' ? `Histórico de ${paciente.nome}` : 'Histórico'}
        aoAbrirMenu={abrirMenu}
      />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo historico">
          <VoltarDetalhesPaciente paciente={paciente} />
          <div className="historico__filtros">
            <div className="historico__filtro-periodo">
              <div className="historico__filtro-titulo">Período</div>
              <div className="historico__datas">
                <label className="historico__data">
                  <span className="historico__data-rotulo">De</span>
                  <input
                    type="date"
                    className="historico__select"
                    value={dataInicio}
                    max={hojeIso}
                    onChange={(e) => alterarInicio(e.target.value)}
                  />
                </label>
                <label className="historico__data">
                  <span className="historico__data-rotulo">Até</span>
                  <input
                    type="date"
                    className="historico__select"
                    value={dataFim}
                    max={hojeIso}
                    onChange={(e) => alterarFim(e.target.value)}
                  />
                </label>
              </div>
            </div>

            <div className="historico__filtro-medicamento">
              <div className="historico__filtro-titulo">Medicamento</div>
              <select
                className="historico__select"
                value={filtroMedicamento}
                onChange={(e) => setFiltroMedicamento(e.target.value)}
              >
                <option value="todos">Todos os medicamentos</option>
                {nomesMedicamentos.map((nome) => (
                  <option key={nome} value={nome}>
                    {nome}
                  </option>
                ))}
              </select>
            </div>

            <div className="historico__resumo">
              <div className="historico__resumo-item" style={{ background: ESTILO_STATUS.tomado.fundo }}>
                <div className="historico__resumo-numero" style={{ color: ESTILO_STATUS.tomado.texto }}>
                  {contagem.tomadas}
                </div>
                <div className="historico__resumo-rotulo">Tomadas</div>
              </div>
              <div className="historico__resumo-item" style={{ background: ESTILO_STATUS.atrasado.fundo }}>
                <div className="historico__resumo-numero" style={{ color: ESTILO_STATUS.atrasado.texto }}>
                  {contagem.atrasadas}
                </div>
                <div className="historico__resumo-rotulo">Atrasadas</div>
              </div>
              <div className="historico__resumo-item" style={{ background: ESTILO_STATUS.perdido.fundo }}>
                <div className="historico__resumo-numero" style={{ color: ESTILO_STATUS.perdido.texto }}>
                  {contagem.perdidas}
                </div>
                <div className="historico__resumo-rotulo">Perdidas</div>
              </div>
            </div>
          </div>

          <div className="historico__lista">
            {entradasFiltradas.map((item, indice) => {
              const mostrarDia = indice === 0 || entradasFiltradas[indice - 1].data !== item.data
              return (
                <div key={`${item.data}-${item.horario}-${item.medicamento}-${indice}`}>
                  {mostrarDia && <div className="historico__dia">{rotuloDoDia(item.data, item.diferenca)}</div>}
                  <div className="historico__item">
                    <span className="historico__ponto" style={{ background: ESTILO_STATUS[item.status].ponto }} />
                    <div className="historico__item-hora">{item.horario}</div>
                    <div className="historico__item-nome">{item.medicamento}</div>
                    <div className="historico__item-dose">{item.dosagem}</div>
                    <Rotulo status={item.status} />
                  </div>
                </div>
              )
            })}
            {entradasFiltradas.length === 0 && (
              <div className="historico__vazio">Nenhum registro para este filtro.</div>
            )}
          </div>
        </div>
      </div>
    </>
  )
}
