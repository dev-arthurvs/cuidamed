import Botao from './Botao'
import './ModalConfirmacao.css'

export default function ModalConfirmacao({ titulo, mensagem, textoConfirmar = 'Confirmar', onCancelar, onConfirmar }) {
  return (
    <div className="modal-confirmacao__fundo" role="dialog" aria-modal="true">
      <div className="modal-confirmacao__caixa">
        <h2 className="modal-confirmacao__titulo">{titulo}</h2>
        <p className="modal-confirmacao__mensagem">{mensagem}</p>
        <div className="modal-confirmacao__acoes">
          <Botao variante="contorno" onClick={onCancelar}>
            Cancelar
          </Botao>
          <Botao variante="perigo" onClick={onConfirmar} style={{ background: 'var(--vermelho)', color: '#fff', border: 'none' }}>
            {textoConfirmar}
          </Botao>
        </div>
      </div>
    </div>
  )
}
