import { AnimatePresence, motion } from 'framer-motion'
import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Campo from '../componentes/Campo'
import { ICONES_CAMPO } from '../componentes/iconesCampo'
import LogoMarca from '../componentes/LogoMarca'
import OpcaoSemEmail from '../componentes/OpcaoSemEmail'
import Toast from '../componentes/Toast'
import { useApp } from '../contexto/useApp'
import { OPCOES_SEXO } from '../dados/dadosMock'
import { dataDeHojeISO, telefoneCompleto } from '../utilitarios/mascaras'
import '../estilos/autenticacao.css'

const variantesCampos = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -8 },
}

const FRASES_IMPACTO = {
  paciente: {
    titulo: 'O remédio certo, na hora certa, sempre com você.',
    subtitulo: 'Receba lembretes automáticos e nunca mais perca uma dose importante.',
  },
  cuidador: {
    titulo: 'Cuidado à distância, com tranquilidade total.',
    subtitulo: 'Acompanhe em tempo real a adesão aos medicamentos de quem você cuida.',
  },
}

export default function Cadastro() {
  const { cadastrar, mostrarToast } = useApp()
  const navegar = useNavigate()

  const [tipo, setTipo] = useState('paciente')
  const [nome, setNome] = useState('')
  const [email, setEmail] = useState('')
  const [semEmail, setSemEmail] = useState(false)
  const [senha, setSenha] = useState('')
  const [dataNascimento, setDataNascimento] = useState('')
  const [sexo, setSexo] = useState(OPCOES_SEXO[0])
  const [telefone, setTelefone] = useState('')
  const [enviando, setEnviando] = useState(false)

  async function criarConta(evento) {
    evento.preventDefault()
    if (!nome.trim()) {
      mostrarToast('Preencha o nome.')
      return
    }
    if (semEmail ? !telefoneCompleto(telefone) : !email.trim()) {
      mostrarToast(semEmail ? 'Sem e-mail, informe o telefone com DDD.' : 'Preencha o e-mail ou marque "Não tenho e-mail".')
      return
    }
    if (senha.length < 8) {
      mostrarToast('A senha deve ter no mínimo 8 caracteres.')
      return
    }
    setEnviando(true)
    try {
      await cadastrar({
        nome: nome.trim(),
        email: semEmail ? '' : email.trim(),
        senha,
        tipo,
        dataNascimento,
        sexo,
        telefone: telefone.trim(),
      })
      navegar('/painel')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível criar a conta.')
    } finally {
      setEnviando(false)
    }
  }

  const campoEmail = (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      {!semEmail && (
        <Campo rotulo="E-mail" tipo="email" icone={ICONES_CAMPO.email} placeholder="seu@email.com" value={email} onChange={(e) => setEmail(e.target.value)} />
      )}
      <OpcaoSemEmail marcado={semEmail} aoMudar={setSemEmail} />
    </div>
  )

  return (
    <motion.div
      className="autenticacao"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, ease: 'easeOut' }}
    >
      <div className="autenticacao__hero">
        <LogoMarca tamanho={84} tamanhoTexto={48} corTexto="claro" fundo="transparente" />

        <AnimatePresence mode="wait" initial={false}>
          <motion.div
            key={tipo}
            className="autenticacao__hero-texto"
            variants={variantesCampos}
            initial="initial"
            animate="animate"
            exit="exit"
            transition={{ duration: 0.2, ease: 'easeInOut' }}
          >
            <p className="autenticacao__hero-titulo">{FRASES_IMPACTO[tipo].titulo}</p>
            <p className="autenticacao__hero-subtitulo">{FRASES_IMPACTO[tipo].subtitulo}</p>
          </motion.div>
        </AnimatePresence>

        <div className="autenticacao__hero-rodape">© 2026 CuidaMed</div>
      </div>

      <div className="autenticacao__painel">
        <form className="autenticacao__caixa" onSubmit={criarConta}>
          <h1 className="autenticacao__titulo">Criar cadastro</h1>

          <div className="autenticacao__papel">
            <div className="autenticacao__papel-titulo">Eu sou</div>
            <div className="autenticacao__papel-opcoes">
              <button
                type="button"
                className={`autenticacao__opcao${tipo === 'paciente' ? ' autenticacao__opcao--ativa' : ''}`}
                onClick={() => setTipo('paciente')}
              >
                Paciente
              </button>
              <button
                type="button"
                className={`autenticacao__opcao${tipo === 'cuidador' ? ' autenticacao__opcao--ativa' : ''}`}
                onClick={() => setTipo('cuidador')}
              >
                Cuidador
              </button>
            </div>
          </div>

          <AnimatePresence mode="wait" initial={false}>
            {tipo === 'paciente' ? (
              <motion.div
                key="paciente"
                variants={variantesCampos}
                initial="initial"
                animate="animate"
                exit="exit"
                transition={{ duration: 0.2, ease: 'easeInOut' }}
                style={{ display: 'flex', flexDirection: 'column', gap: 20 }}
              >
                <Campo rotulo="Nome completo" icone={ICONES_CAMPO.pessoa} placeholder="Maria Aparecida Souza" value={nome} onChange={(e) => setNome(e.target.value)} />
                <div className="autenticacao__grade-dupla">
                  <Campo
                    rotulo="Data de nascimento"
                    tipo="date"
                    value={dataNascimento}
                    max={dataDeHojeISO()}
                    onChange={(e) => setDataNascimento(e.target.value)}
                  />
                  <Campo rotulo="Sexo" tipo="select" value={sexo} onChange={(e) => setSexo(e.target.value)}>
                    {OPCOES_SEXO.map((opcao) => (
                      <option key={opcao}>{opcao}</option>
                    ))}
                  </Campo>
                </div>
                <Campo
                  rotulo="Telefone"
                  tipo="tel"
                  icone={ICONES_CAMPO.telefone}
                  placeholder="(11) 98765-4321"
                  value={telefone}
                  onChange={(e) => setTelefone(e.target.value)}
                />
                {campoEmail}
                <Campo
                  rotulo="Senha"
                  tipo="password"
                  icone={ICONES_CAMPO.senha}
                  alternarSenha
                  placeholder="Mínimo 8 caracteres"
                  value={senha}
                  onChange={(e) => setSenha(e.target.value)}
                />
              </motion.div>
            ) : (
              <motion.div
                key="cuidador"
                variants={variantesCampos}
                initial="initial"
                animate="animate"
                exit="exit"
                transition={{ duration: 0.2, ease: 'easeInOut' }}
                style={{ display: 'flex', flexDirection: 'column', gap: 20 }}
              >
                <Campo rotulo="Nome completo" icone={ICONES_CAMPO.pessoa} placeholder="Ana Lúcia Souza" value={nome} onChange={(e) => setNome(e.target.value)} />
                <Campo
                  rotulo="Telefone"
                  tipo="tel"
                  icone={ICONES_CAMPO.telefone}
                  placeholder="(11) 98765-4321"
                  value={telefone}
                  onChange={(e) => setTelefone(e.target.value)}
                />
                {campoEmail}
                <Campo
                  rotulo="Senha"
                  tipo="password"
                  icone={ICONES_CAMPO.senha}
                  alternarSenha
                  placeholder="Mínimo 8 caracteres"
                  value={senha}
                  onChange={(e) => setSenha(e.target.value)}
                />
              </motion.div>
            )}
          </AnimatePresence>

          <Botao type="submit" larguraTotal style={{ marginTop: 6 }} disabled={enviando}>
            {enviando ? 'Criando conta...' : 'Criar conta e entrar'}
          </Botao>

          <div className="autenticacao__alternativas">
            <Link className="autenticacao__alternativa" to="/login">
              Entrar
            </Link>
            <Link className="autenticacao__alternativa" to="/definir-senha">
              Ativar acesso
            </Link>
          </div>
        </form>
      </div>
      <Toast />
    </motion.div>
  )
}
