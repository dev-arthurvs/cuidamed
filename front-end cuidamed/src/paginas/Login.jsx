import { m } from 'framer-motion'
import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Campo from '../componentes/Campo'
import { ICONES_CAMPO } from '../componentes/iconesCampo'
import LogoMarca from '../componentes/LogoMarca'
import Toast from '../componentes/Toast'
import { useApp } from '../contexto/useApp'
import { lerLoginLembrado } from '../utilitarios/sessao'
import '../estilos/autenticacao.css'

export default function Login() {
  const { entrar, mostrarToast } = useApp()
  const navegar = useNavigate()
  const [login, setLogin] = useState(lerLoginLembrado)
  const [senha, setSenha] = useState('')
  // Marcado por padrão quando a pessoa já tinha pedido para ser lembrada.
  const [lembrar, setLembrar] = useState(() => lerLoginLembrado() !== '')
  const [entrando, setEntrando] = useState(false)

  async function entrarNaConta(evento) {
    evento.preventDefault()
    if (!login.trim() || !senha.trim()) {
      mostrarToast('Preencha o e-mail ou telefone e a senha para entrar.')
      return
    }
    setEntrando(true)
    try {
      await entrar(login.trim(), senha, lembrar)
      navegar('/painel')
    } catch (erro) {
      mostrarToast(erro.message || 'E-mail, telefone ou senha inválidos.')
    } finally {
      setEntrando(false)
    }
  }

  return (
    <m.div
      className="autenticacao"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, ease: 'easeOut' }}
    >
      <div className="autenticacao__hero">
        <LogoMarca tamanho={84} tamanhoTexto={48} corTexto="claro" fundo="transparente" />

        <div className="autenticacao__hero-texto">
          <p className="autenticacao__hero-titulo">O remédio certo, na hora certa, todos os dias.</p>
          <p className="autenticacao__hero-subtitulo">
            Agenda de medicamentos, com acompanhamento em tempo real por médicos e cuidadores.
          </p>
        </div>

        <div className="autenticacao__hero-rodape">© 2026 CuidaMed</div>
      </div>

      <div className="autenticacao__painel">
        <form className="autenticacao__caixa" onSubmit={entrarNaConta}>
          <div>
            <h1 className="autenticacao__titulo">Entrar na minha conta</h1>
          </div>

          <Campo
            rotulo="E-mail ou telefone"
            tipo="email-ou-telefone"
            icone={ICONES_CAMPO.pessoa}
            autoComplete="username"
            placeholder="seu@email.com ou (79) 99999-9999"
            value={login}
            onChange={(e) => setLogin(e.target.value)}
          />
          <Campo
            rotulo="Senha"
            tipo="password"
            icone={ICONES_CAMPO.senha}
            alternarSenha
            placeholder="••••••••"
            value={senha}
            onChange={(e) => setSenha(e.target.value)}
          />
          <div className="autenticacao__opcoes">
            <label className="autenticacao__lembrar">
              <input type="checkbox" checked={lembrar} onChange={(e) => setLembrar(e.target.checked)} />
              <span>Lembrar de mim</span>
            </label>
            <button
              type="button"
              className="autenticacao__esqueci"
              onClick={() => navegar('/definir-senha?novaSenha=1')}
            >
              Esqueci minha senha
            </button>
          </div>

          <Botao type="submit" larguraTotal disabled={entrando}>
            {entrando ? 'Entrando...' : 'Entrar'}
          </Botao>

          <div className="autenticacao__alternativas">
            <Link className="autenticacao__alternativa" to="/cadastro">
              Criar conta
            </Link>
            <Link className="autenticacao__alternativa" to="/definir-senha">
              Ativar acesso
            </Link>
          </div>
        </form>
      </div>
      <Toast />
    </m.div>
  )
}
