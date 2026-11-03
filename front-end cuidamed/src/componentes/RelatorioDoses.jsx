import { createPortal } from 'react-dom'
import { formatarDataCurta } from '../utilitarios/horarios'
import './RelatorioDoses.css'

const ROTULO_STATUS = { tomado: 'Tomada', atrasado: 'Atrasada', perdido: 'Perdida' }

// Relatório para levar ao médico. Fica escondido na tela e é o único conteúdo
// impresso: "Gerar relatório" abre a impressão do navegador, que salva em PDF.
export default function RelatorioDoses({ paciente, entradas, dataInicio, dataFim }) {
  const contar = (status) => entradas.filter((item) => item.status === status).length
  const tomadas = contar('tomado')
  const adesao = entradas.length ? `${Math.round((tomadas / entradas.length) * 100)}%` : '—'
  const emOrdem = [...entradas].sort((a, b) => (a.data === b.data ? a.horario.localeCompare(b.horario) : a.data.localeCompare(b.data)))

  return createPortal(
    <div className="relatorio-doses">
      <h1>CuidaMed — Relatório de doses</h1>
      <dl className="relatorio-doses__dados">
        <div>
          <dt>Paciente</dt>
          <dd>{paciente.nome}</dd>
        </div>
        {paciente.dataNascimento && (
          <div>
            <dt>Nascimento</dt>
            <dd>{formatarDataCurta(paciente.dataNascimento)}</dd>
          </div>
        )}
        {paciente.enfermidade && (
          <div>
            <dt>Condição</dt>
            <dd>{paciente.enfermidade}</dd>
          </div>
        )}
        <div>
          <dt>Período</dt>
          <dd>
            {formatarDataCurta(dataInicio)} a {formatarDataCurta(dataFim)}
          </dd>
        </div>
      </dl>

      <h2>Resumo</h2>
      <p>
        Adesão no período: <strong>{adesao}</strong> · Tomadas: {tomadas} · Atrasadas: {contar('atrasado')} · Perdidas: {contar('perdido')}
      </p>

      <h2>Medicamentos em uso</h2>
      {paciente.medicamentosAtivos.length === 0 && <p>Nenhum.</p>}
      <ul>
        {paciente.medicamentosAtivos.map((medicamento) => (
          <li key={medicamento.id}>
            {[medicamento.nome, medicamento.dosagem, medicamento.forma].filter(Boolean).join(' · ')} — {medicamento.horarios.join(', ')}
          </li>
        ))}
      </ul>

      <h2>Doses</h2>
      {entradas.length === 0 ? (
        <p>Nenhuma dose no período.</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Data</th>
              <th>Hora</th>
              <th>Medicamento</th>
              <th>Situação</th>
            </tr>
          </thead>
          <tbody>
            {emOrdem.map((item) => (
              <tr key={`${item.data}-${item.horario}-${item.medicamentoId}`}>
                <td>{formatarDataCurta(item.data)}</td>
                <td>{item.horario}</td>
                <td>{item.medicamento}</td>
                <td>{ROTULO_STATUS[item.status] || item.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
      <p className="relatorio-doses__nota">Doses que passaram do horário sem registro contam como atrasadas ou perdidas.</p>
    </div>,
    document.body,
  )
}
