import { Link } from 'react-router-dom'
import { formatarDataCurta } from '../utilitarios/horarios'
import { formatarNumeroCartao } from '../utilitarios/mascaras'
import LogoMarca from './LogoMarca'
import './CartaoPaciente.css'

// "Cartão do paciente" da tela inicial, no formato de cartão de plano de
// saúde: identifica o paciente (nome, nascimento, sexo) e resume o dia (doses
// tomadas, a tomar e atrasadas), com o atalho para a agenda. O nº do cartão é o
// código do vínculo com o cuidador: só aparece quando há cuidador vinculado.
export default function CartaoPaciente({ paciente, contagem }) {
  return (
    <section className="cartao-paciente" aria-label="Cartão do paciente">
      <div className="cartao-paciente__topo">
        <LogoMarca tamanho={36} tamanhoTexto={21} corTexto="claro" fundo="transparente" />
        <span className="cartao-paciente__tipo">Cartão do paciente</span>
      </div>

      <div className="cartao-paciente__identificacao">
        <span className="cartao-paciente__chip" aria-hidden="true" />
        <div className="cartao-paciente__nome">{paciente.nome}</div>
      </div>

      <dl className="cartao-paciente__dados">
        <div>
          <dt>Nascimento</dt>
          <dd>{paciente.dataNascimento ? formatarDataCurta(paciente.dataNascimento) : '—'}</dd>
        </div>
        <div>
          <dt>Sexo</dt>
          <dd>{paciente.sexo || '—'}</dd>
        </div>
        {paciente.codigoVinculo && (
          <div>
            <dt>Nº do cartão</dt>
            <dd className="cartao-paciente__numero">{formatarNumeroCartao(paciente.codigoVinculo)}</dd>
          </div>
        )}
      </dl>

      <div className="cartao-paciente__rodape">
        <div className="cartao-paciente__doses" aria-label="Doses de hoje">
          <div className="cartao-paciente__dose cartao-paciente__dose--tomado">
            <strong>{contagem.tomados}</strong>
            <span>Tomados</span>
          </div>
          <div className="cartao-paciente__dose cartao-paciente__dose--a-tomar">
            <strong>{contagem.aTomar}</strong>
            <span>A tomar</span>
          </div>
          <div className="cartao-paciente__dose cartao-paciente__dose--atrasado">
            <strong>{contagem.atrasados}</strong>
            <span>Atrasados</span>
          </div>
        </div>
        <Link to="/agenda" className="cartao-paciente__agenda">
          Ver agenda completa ›
        </Link>
      </div>
    </section>
  )
}
