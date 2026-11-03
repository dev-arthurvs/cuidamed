import { useState } from 'react'
import { useApp } from '../contexto/useApp'
import Botao from './Botao'
import Cartao from './Cartao'

// Detalhes do paciente: código para ativar o acesso ou, se ele esqueceu a
// senha, botão para o cuidador gerar um código de nova senha (vale 24 horas).
export default function AcessoPaciente({ paciente }) {
  const { gerarCodigoNovaSenha, mostrarToast } = useApp()
  const [gerando, setGerando] = useState(false)

  async function gerar() {
    setGerando(true)
    try {
      await gerarCodigoNovaSenha(paciente.id)
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível gerar o código.')
    } finally {
      setGerando(false)
    }
  }

  return (
    <Cartao titulo="Acesso do paciente">
      {paciente.codigoAtivacao ? (
        <>
          <p className="painel-cuidador-detalhe__ativacao-texto">
            {paciente.codigoNovaSenha
              ? 'Passe este código ao paciente. Ele clica em “Esqueci minha senha”, informa o e-mail ou telefone e cria a senha nova. Vale por 24 horas.'
              : 'Ainda não ativou o acesso ao app. Passe este código para usar em “Ativar meu acesso”, junto com o e-mail ou telefone cadastrado.'}
          </p>
          <div className="painel-cuidador-detalhe__codigo">{paciente.codigoAtivacao}</div>
        </>
      ) : (
        <>
          <p className="painel-cuidador-detalhe__ativacao-texto">O paciente esqueceu a senha? Gere um código para ele criar uma nova.</p>
          <Botao variante="secundario" larguraTotal onClick={gerar} disabled={gerando}>
            {gerando ? 'Gerando...' : 'Gerar código de nova senha'}
          </Botao>
        </>
      )}
    </Cartao>
  )
}
