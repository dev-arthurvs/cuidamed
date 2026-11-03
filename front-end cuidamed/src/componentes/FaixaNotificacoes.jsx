import { useState } from 'react'
import { pedirPermissaoNotificacao, statusPermissaoNotificacao } from '../utilitarios/notificacoes'
import Botao from './Botao'

// Convite para ativar som e notificação; some depois que a pessoa responde.
export default function FaixaNotificacoes({ descricao }) {
  const [status, setStatus] = useState(() => statusPermissaoNotificacao())

  if (status !== 'default') return null

  return (
    <div className="painel-idoso__banner-notificacao">
      <div>
        <strong>Ative os lembretes sonoros e notificações</strong>
        <p>{descricao}</p>
      </div>
      <Botao tamanho="pequeno" onClick={async () => setStatus(await pedirPermissaoNotificacao())}>
        Ativar
      </Botao>
    </div>
  )
}
