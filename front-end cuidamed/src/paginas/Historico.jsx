import { useEffect, useMemo, useState } from 'react'
import { useParams } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Cabecalho from '../componentes/Cabecalho'
import RelatorioDoses from '../componentes/RelatorioDoses'
import VoltarDetalhesPaciente from '../componentes/VoltarDetalhesPaciente'
import Rotulo from '../componentes/Rotulo'
import { useApp } from '../contexto/useApp'
import { ESTILO_STATUS } from '../dados/dadosMock'
import { dosesSemRegistro, inicioJanelaHistorico, somarDias } from '../utilitarios/horarios'
import { DATA_MINIMA } from '../utilitarios/mascaras'
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
  const { pacientes, pacienteFoco, usuario, carregarHistoricoAntigo } = useApp()
  const { pacienteId } = useParams()
  const [filtroMedicamento, setFiltroMedicamento] = useState('todos')

  const paciente = pacienteId ? pacientes.find((item) => String(item.id) === pacienteId) : pacienteFoco

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

  // O app guarda só os últimos dias do histórico; período mais antigo vem do
  // servidor. Até chegar, nada é calculado: sem os registros, doses tomadas
  // apareceriam como perdidas.
  const inicioJanela = inicioJanelaHistorico(hojeIso)
  const pacienteAtualId = paciente?.id
  const chaveAntigos = pacienteAtualId && dataInicio < inicioJanela ? `${pacienteAtualId}|${dataInicio}` : null
  const [antigos, setAntigos] = useState(null)
  useEffect(() => {
    if (!chaveAntigos) return undefined
    let cancelado = false
    carregarHistoricoAntigo(pacienteAtualId, dataInicio, somarDias(inicioJanela, -1))
      .then((itens) => {
        if (!cancelado) setAntigos({ chave: chaveAntigos, itens })
      })
      .catch(() => {
        if (!cancelado) setAntigos({ chave: chaveAntigos, itens: [], erro: true })
      })
    return () => {
      cancelado = true
    }
  }, [chaveAntigos, pacienteAtualId, dataInicio, inicioJanela, carregarHistoricoAntigo])
  const antigosAtuais = chaveAntigos && antigos?.chave === chaveAntigos ? antigos : null
  const carregandoAntigos = Boolean(chaveAntigos) && !antigosAtuais
  const erroAntigos = Boolean(antigosAtuais?.erro)
  const periodoDisponivel = !carregandoAntigos && !erroAntigos

  const historicoDoPeriodo = useMemo(() => {
    if (!paciente) return []
    return antigosAtuais ? [...antigosAtuais.itens, ...paciente.historico] : paciente.historico
  }, [paciente, antigosAtuais])

  const nomesMedicamentos = useMemo(() => {
    if (!paciente) return []
    return [
      ...new Set([...historicoDoPeriodo.map((item) => item.medicamento), ...paciente.medicamentos.map((item) => item.nome)]),
    ].sort()
  }, [paciente, historicoDoPeriodo])

  const entradasFiltradas = useMemo(() => {
    if (!paciente || !periodoDisponivel) return []
    // Registros do banco + doses que passaram do horário sem registro (as
    // mesmas que o Início mostra como atrasadas/perdidas).
    const semRegistro = dosesSemRegistro(paciente.medicamentos, historicoDoPeriodo, dataInicio, dataFim)
    return [...historicoDoPeriodo, ...semRegistro]
      .map((item) => ({ ...item, diferenca: diasDeDiferenca(item.data, hoje) }))
      .filter((item) => item.data >= dataInicio && item.data <= dataFim)
      .filter((item) => filtroMedicamento === 'todos' || item.medicamento === filtroMedicamento)
      .sort((a, b) => (a.data === b.data ? b.horario.localeCompare(a.horario) : b.data.localeCompare(a.data)))
  }, [paciente, periodoDisponivel, historicoDoPeriodo, hoje, dataInicio, dataFim, filtroMedicamento])

  if (!paciente) {
    return (
      <>
        <Cabecalho kicker="Registro de doses" titulo="Histórico de doses" />
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
        titulo={usuario.tipo === 'cuidador' ? `Histórico de doses de ${paciente.nome}` : 'Histórico de doses'}
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
                    min={DATA_MINIMA}
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
                    min={DATA_MINIMA}
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

            <Botao variante="secundario" larguraTotal disabled={!periodoDisponivel} onClick={() => window.print()}>
              Gerar relatório (PDF)
            </Botao>
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
                    {item.dosagem && <div className="historico__item-dose">{item.dosagem}</div>}
                    <Rotulo status={item.status} />
                  </div>
                </div>
              )
            })}
            {entradasFiltradas.length === 0 && (
              <div className="historico__vazio">
                {carregandoAntigos
                  ? 'Carregando...'
                  : erroAntigos
                    ? 'Não foi possível carregar esse período.'
                    : 'Nenhum registro para este filtro.'}
              </div>
            )}
          </div>
        </div>
      </div>
      <RelatorioDoses paciente={paciente} entradas={entradasFiltradas} dataInicio={dataInicio} dataFim={dataFim} />
    </>
  )
}
