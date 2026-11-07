import { m } from 'framer-motion'
import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Campo from '../componentes/Campo'
import { ICONES_CAMPO } from '../componentes/iconesCampo'
import LogoMarca from '../componentes/LogoMarca'
import Toast from '../componentes/Toast'
import { useApp } from '../contexto/useApp'
import { api } from '../utilitarios/api'
import '../estilos/autenticacao.css'

export default function DefinirSenha() {
  const { mostrarToast } = useApp()
  const navegar = useNavigate()
  // Veio de "Esqueci minha senha": mesmo formulário, com o código de nova senha.
  const [parametros] = useSearchParams()
  const ehRecuperacao = parametros.get('novaSenha') === '1'
  const [login, setLogin] = useState('')
  const [codigo, setCodigo] = useState('')
  const [novaSenha, setNovaSenha] = useState('')
  const [confirmarSenha, setConfirmarSenha] = useState('')
  const [enviando, setEnviando] = useState(false)

  async function ativarAcesso(evento) {
    evento.preventDefault()
    if (!login.trim()) {
      mostrarToast('Informe o e-mail ou telefone cadastrado pelo seu cuidador.')
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
      await api.post('/api/pacientes/definir-senha', { login: login.trim(), codigo: codigo.trim(), novaSenha })
      mostrarToast(ehRecuperacao ? 'Senha criada! Entre com a nova senha.' : 'Acesso ativado! Faça login com sua nova senha.')
      navegar('/login')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível ativar o acesso.')
    } finally {
      setEnviando(false)
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
          <p className="autenticacao__hero-titulo">Seu cuidador já cadastrou você.</p>
          <p className="autenticacao__hero-subtitulo">
            Agora é só criar uma senha para acessar sua própria agenda de medicamentos.
          </p>
        </div>

        <div className="autenticacao__hero-rodape">© 2026 CuidaMed</div>
      </div>

      <div className="autenticacao__painel">
        <form className="autenticacao__caixa" onSubmit={ativarAcesso}>
          <div>
            <h1 className="autenticacao__titulo">{ehRecuperacao ? 'Criar nova senha' : 'Ativar meu acesso'}</h1>
            {ehRecuperacao && (
              <p className="autenticacao__subtitulo">Peça ao seu cuidador um código de nova senha. Ele gera nos detalhes do paciente.</p>
            )}
          </div>

          <Campo
            rotulo="E-mail ou telefone cadastrado"
            tipo="email-ou-telefone"
            icone={ICONES_CAMPO.pessoa}
            placeholder="seu@email.com ou (79) 99999-9999"
            value={login}
            onChange={(e) => setLogin(e.target.value)}
          />
          <Campo
            rotulo="Código de ativação"
            icone={ICONES_CAMPO.codigo}
            placeholder="Código que seu cuidador passou"
            value={codigo}
            onChange={(e) => setCodigo(e.target.value.toUpperCase())}
            autoComplete="off"
            maxLength={12}
          />
          <Campo
            rotulo="Criar senha"
            tipo="password"
            icone={ICONES_CAMPO.senha}
            alternarSenha
            placeholder="Mínimo 8 caracteres"
            value={novaSenha}
            onChange={(e) => setNovaSenha(e.target.value)}
          />
          <Campo
            rotulo="Confirmar senha"
            tipo="password"
            icone={ICONES_CAMPO.senha}
            alternarSenha
            placeholder="Repita a senha"
            value={confirmarSenha}
            onChange={(e) => setConfirmarSenha(e.target.value)}
          />

          <Botao type="submit" larguraTotal disabled={enviando}>
            {enviando ? 'Ativando...' : 'Ativar acesso'}
          </Botao>

          <div className="autenticacao__alternativas">
            <Link className="autenticacao__alternativa" to="/login">
              Entrar
            </Link>
            <Link className="autenticacao__alternativa" to="/cadastro">
              Criar conta
            </Link>
          </div>
        </form>
      </div>
      <Toast />
    </m.div>
  )
}
