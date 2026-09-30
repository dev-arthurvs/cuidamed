import { Link } from 'react-router-dom'
import Botao from './Botao'
import SecaoAjuda from './SecaoAjuda'
import './ModalAjuda.css'

export default function ModalAjuda({ secao, onFechar }) {
  return (
    <div className="modal-ajuda__fundo" role="dialog" aria-modal="true">
      <div className="modal-ajuda__caixa">
        {secao ? (
          <SecaoAjuda secao={secao} />
        ) : (
          <p className="secao-ajuda__para-que-serve">Ainda não temos uma ajuda específica para esta tela.</p>
        )}
        <div className="modal-ajuda__acoes">
          <Link to="/acessibilidade" className="modal-ajuda__link" onClick={onFechar}>
            Ver guia completo
          </Link>
          <Botao onClick={onFechar}>Entendi</Botao>
        </div>
      </div>
    </div>
  )
}
