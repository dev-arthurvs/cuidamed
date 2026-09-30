import { motion } from 'framer-motion'
import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Campo from '../componentes/Campo'
import LogoMarca from '../componentes/LogoMarca'
import Toast from '../componentes/Toast'
import { useApp } from '../contexto/useApp'
import { api } from '../utilitarios/api'
import '../estilos/autenticacao.css'

export default function DefinirSenha() {
  const { mostrarToast } = useApp()
  const navegar = useNavigate()
  const [email, setEmail] = useState('')
  const [codigo, setCodigo] = useState('')
  const [novaSenha, setNovaSenha] = useState('')
  const [confirmarSenha, setConfirmarSenha] = useState('')
  const [enviando, setEnviando] = useState(false)

  async function ativarAcesso(evento) {
    evento.preventDefault()
    if (!email.trim()) {
      mostrarToast('Informe o e-mail cadastrado pelo seu cuidador.')
      return
    }
    if (!codigo.trim()) {
      mostrarToast('Informe o código de ativação que seu cuidador passou.')
      return
    }
    if (novaSenha.length < 8) {
      mostrarToast('A senha deve ter no mínimo 8 caracteres.')
      return
    }
    if (novaSenha !== confirmarSenha) {
      mostrarToast('As senhas não coincidem.')
      return
    }
    setEnviando(true)
    try {
      await api.post('/api/pacientes/definir-senha', { email: email.trim(), codigo: codigo.trim(), novaSenha })
      mostrarToast('Acesso ativado! Faça login com sua nova senha.')
      navegar('/login')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível ativar o acesso.')
    } finally {
      setEnviando(false)
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
          <p className="autenticacao__hero-titulo">Seu cuidador já cadastrou você.</p>
          <p className="autenticacao__hero-subtitulo">
            Agora é só criar uma senha para acessar sua própria agenda de medicamentos.
          </p>
        </div>

        <div className="autenticacao__hero-rodape">© 2026 CuidaMed</div>
      </div>

      <div className="autenticacao__painel">
        <form className="autenticacao__caixa" onSubmit={ativarAcesso}>
          <Botao variante="texto" type="button" onClick={() => navegar('/login')} style={{ alignSelf: 'flex-start' }}>
            ‹ Voltar para entrar
          </Botao>
          <div>
            <h1 className="autenticacao__titulo">Ativar meu acesso</h1>
          </div>

          <Campo
            rotulo="E-mail cadastrado"
            tipo="email"
            placeholder="seu@email.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <Campo
            rotulo="Código de ativação"
            placeholder="Código que seu cuidador passou"
            value={codigo}
            onChange={(e) => setCodigo(e.target.value.toUpperCase())}
            autoComplete="off"
            maxLength={12}
          />
          <Campo
            rotulo="Criar senha"
            tipo="password"
            placeholder="Mínimo 8 caracteres"
            value={novaSenha}
            onChange={(e) => setNovaSenha(e.target.value)}
          />
          <Campo
            rotulo="Confirmar senha"
            tipo="password"
            placeholder="Repita a senha"
            value={confirmarSenha}
            onChange={(e) => setConfirmarSenha(e.target.value)}
          />

          <Botao type="submit" larguraTotal disabled={enviando}>
            {enviando ? 'Ativando...' : 'Ativar acesso'}
          </Botao>

          <div className="autenticacao__rodape-acoes">
            <div className="autenticacao__conta">
              Ainda não tem cadastro?
              <Link to="/cadastro">
                <strong>Cadastre-se</strong>
              </Link>
            </div>
          </div>
        </form>
      </div>
      <Toast />
    </motion.div>
  )
}
