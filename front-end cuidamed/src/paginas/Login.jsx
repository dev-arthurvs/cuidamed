import { motion } from 'framer-motion'
import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Campo from '../componentes/Campo'
import LogoMarca from '../componentes/LogoMarca'
import Toast from '../componentes/Toast'
import { useApp } from '../contexto/useApp'
import '../estilos/autenticacao.css'

export default function Login() {
  const { entrar, mostrarToast } = useApp()
  const navegar = useNavigate()
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [entrando, setEntrando] = useState(false)

  async function entrarNaConta(evento) {
    evento.preventDefault()
    if (!email.trim() || !senha.trim()) {
      mostrarToast('Preencha e-mail e senha para entrar.')
      return
    }
    setEntrando(true)
    try {
      await entrar(email.trim(), senha)
      navegar('/painel')
    } catch (erro) {
      mostrarToast(erro.message || 'E-mail ou senha inválidos.')
    } finally {
      setEntrando(false)
    }
  }

  return (
    <motion.div
      className="autenticacao"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, ease: 'easeOut' }}
    >
      <div className="autenticacao__hero">
        <LogoMarca tamanho={68} tamanhoTexto={38} corTexto="claro" fundo="transparente" />

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

          <Campo rotulo="E-mail" tipo="email" placeholder="seu@email.com" value={email} onChange={(e) => setEmail(e.target.value)} />
          <Campo rotulo="Senha" tipo="password" placeholder="••••••••" value={senha} onChange={(e) => setSenha(e.target.value)} />

          <Botao type="submit" larguraTotal disabled={entrando}>
            {entrando ? 'Entrando...' : 'Entrar'}
          </Botao>

          <div className="autenticacao__rodape-acoes">
            <Botao
              variante="texto"
              type="button"
              onClick={() => mostrarToast('Enviamos as instruções de recuperação para o seu e-mail (simulação).')}
            >
              Esqueci minha senha
            </Botao>
            <div className="autenticacao__conta">
              Não tem conta?
              <Link to="/cadastro">
                <strong>Cadastre-se</strong>
              </Link>
            </div>
            <div className="autenticacao__conta">
              Cadastrado pelo seu cuidador?
              <Link to="/definir-senha">
                <strong>Ativar meu acesso</strong>
              </Link>
            </div>
          </div>
        </form>
      </div>
      <Toast />
    </motion.div>
  )
}
