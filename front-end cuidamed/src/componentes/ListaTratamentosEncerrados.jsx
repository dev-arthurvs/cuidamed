import { AnimatePresence, m } from 'framer-motion'
import { TRANSICAO_ITEM_LISTA, VARIANTES_ITEM_LISTA } from '../utilitarios/animacoes'
import { formatarDataCurta } from '../utilitarios/horarios'
import LogoMarca from './LogoMarca'
import '../paginas/AgendaMedicamentos.css'
import './ListaTratamentosEncerrados.css'

// Aba "Encerrados" da Agenda: remédios cujo tratamento já terminou, só para
// consulta (sem editar/excluir), com o período em que foram usados.
export default function ListaTratamentosEncerrados({ medicamentos }) {
  return (
    <div className="agenda__grade tratamentos-encerrados__grade">
      <AnimatePresence>
        {medicamentos.map((medicamento) => (
          <m.div
            className="agenda__cartao tratamentos-encerrados__cartao"
            key={medicamento.id}
            layout
            initial={VARIANTES_ITEM_LISTA.initial}
            animate={VARIANTES_ITEM_LISTA.animate}
            exit={VARIANTES_ITEM_LISTA.exit}
            transition={TRANSICAO_ITEM_LISTA}
          >
            <div className="agenda__cartao-cabecalho">
              <div className="agenda__cartao-icone tratamentos-encerrados__icone">
                <LogoMarca comTexto={false} tamanho={24} />
              </div>
              <div className="agenda__cartao-info">
                <div className="agenda__cartao-nome">{medicamento.nome}</div>
                <div className="agenda__cartao-dose">
                  {[medicamento.dosagem, medicamento.forma].filter(Boolean).join(' · ')}
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
            <div className="tratamentos-encerrados__periodo">
              Tratamento de {formatarDataCurta(medicamento.inicio)} até {formatarDataCurta(medicamento.fim)}
            </div>
            {medicamento.observacoes && <div className="tratamentos-encerrados__observacoes">{medicamento.observacoes}</div>}
          </m.div>
        ))}
      </AnimatePresence>
      {medicamentos.length === 0 && <p style={{ color: 'var(--texto-suave)' }}>Nenhum tratamento encerrado até o momento.</p>}
    </div>
  )
}
