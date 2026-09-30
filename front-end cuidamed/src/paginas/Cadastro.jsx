import { AnimatePresence, motion } from 'framer-motion'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Campo from '../componentes/Campo'
import LogoMarca from '../componentes/LogoMarca'
import Toast from '../componentes/Toast'
import { useApp } from '../contexto/useApp'
import { OPCOES_SEXO } from '../dados/dadosMock'
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
  const [senha, setSenha] = useState('')
  const [dataNascimento, setDataNascimento] = useState('')
  const [sexo, setSexo] = useState(OPCOES_SEXO[0])
  const [telefone, setTelefone] = useState('')
  const [endereco, setEndereco] = useState('')
  const [profissao, setProfissao] = useState('')
  const [enviando, setEnviando] = useState(false)

  async function criarConta(evento) {
    evento.preventDefault()
    if (!nome.trim() || !email.trim()) {
      mostrarToast('Preencha nome e e-mail.')
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
        email: email.trim(),
        senha,
        tipo,
        dataNascimento,
        sexo,
        telefone: telefone.trim(),
        endereco: endereco.trim(),
        profissao: profissao.trim(),
      })
      navegar('/painel')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível criar a conta.')
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
        <div style={{ display: 'flex', flexDirection: 'column', gap: 60 }}>
          <LogoMarca tamanho={68} tamanhoTexto={38} corTexto="claro" fundo="transparente" />

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
        </div>

        <div className="autenticacao__hero-rodape">© 2026 CuidaMed · Protótipo de demonstração</div>
      </div>

      <div className="autenticacao__painel">
        <form className="autenticacao__caixa" onSubmit={criarConta}>
          <Botao variante="texto" type="button" onClick={() => navegar('/login')} style={{ alignSelf: 'flex-start' }}>
            ‹ Voltar para entrar
          </Botao>
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
                <Campo rotulo="Nome completo" placeholder="Maria Aparecida Souza" value={nome} onChange={(e) => setNome(e.target.value)} />
                <div className="autenticacao__grade-dupla">
                  <Campo
                    rotulo="Data de nascimento"
                    tipo="date"
                    value={dataNascimento}
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
                  placeholder="(11) 98765-4321"
                  value={telefone}
                  onChange={(e) => setTelefone(e.target.value)}
                />
                <Campo
                  rotulo="Endereço"
                  placeholder="Rua, número, bairro - cidade/UF"
                  value={endereco}
                  onChange={(e) => setEndereco(e.target.value)}
                />
                <Campo rotulo="E-mail" tipo="email" placeholder="seu@email.com" value={email} onChange={(e) => setEmail(e.target.value)} />
                <Campo
                  rotulo="Senha"
                  tipo="password"
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
                <Campo rotulo="Nome completo" placeholder="Ana Lúcia Souza" value={nome} onChange={(e) => setNome(e.target.value)} />
                <Campo
                  rotulo="Profissão"
                  placeholder="Ex.: Médica, Enfermeira, Cuidadora"
                  value={profissao}
                  onChange={(e) => setProfissao(e.target.value)}
                />
                <Campo
                  rotulo="Telefone"
                  tipo="tel"
                  placeholder="(11) 98765-4321"
                  value={telefone}
                  onChange={(e) => setTelefone(e.target.value)}
                />
                <Campo rotulo="E-mail" tipo="email" placeholder="seu@email.com" value={email} onChange={(e) => setEmail(e.target.value)} />
                <Campo
                  rotulo="Senha"
                  tipo="password"
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
        </form>
      </div>
      <Toast />
    </motion.div>
  )
}
