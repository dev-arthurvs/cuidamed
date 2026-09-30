import { AnimatePresence, motion } from 'framer-motion'
import { useEffect, useRef, useState } from 'react'
import { useOutletContext } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Cabecalho from '../componentes/Cabecalho'
import Cartao from '../componentes/Cartao'
import { useApp } from '../contexto/useApp'
import { api } from '../utilitarios/api'
import './Chat.css'


const MENSAGEM_BOAS_VINDAS = {
  id: 'boas-vindas',
  autor: 'ia',
  texto: 'Olá! Eu sou o assistente do CuidaMed. Pode me perguntar sobre seus remédios e horários.',
}

const MENSAGEM_ERRO_CONEXAO = 'Não consegui me conectar ao servidor agora. Tente novamente em instantes.'

const PERGUNTAS_SUGERIDAS = [
  'Quais remédios eu preciso tomar?',
  'Que horas eu tomo cada remédio?',
  'Tem alguma observação sobre como tomar meus remédios?',
  'Eu tomei todos os remédios nos últimos dias?',
]

export default function Chat() {
  const { abrirMenu } = useOutletContext()
  const { usuario } = useApp()

  const [mensagens, setMensagens] = useState([MENSAGEM_BOAS_VINDAS])
  const [entrada, setEntrada] = useState('')
  const [enviando, setEnviando] = useState(false)

  const fimDaListaRef = useRef(null)
  const proximoIdRef = useRef(0)

  useEffect(() => {
    fimDaListaRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [mensagens])

  async function enviarMensagem(evento) {
    evento.preventDefault()
    await enviarTexto(entrada)
  }

  async function enviarSugestao(pergunta) {
    await enviarTexto(pergunta)
  }

  async function enviarTexto(valor) {
    const texto = valor.trim()
    if (!texto || enviando) return

    const sequencia = (proximoIdRef.current += 1)
    const idPergunta = `usuario-${sequencia}`
    const idResposta = `ia-${sequencia}`

    setMensagens((atual) => [
      ...atual,
      { id: idPergunta, autor: 'usuario', texto },
      { id: idResposta, autor: 'ia', texto: '', digitando: true },
    ])
    setEntrada('')
    setEnviando(true)

    try {
      const json = await api.post(`/api/chat/${usuario.id}`, { mensagem: texto })
      setMensagens((atual) =>
        atual.map((item) => (item.id === idResposta ? { ...item, texto: json.resposta, digitando: false } : item)),
      )
    } catch (erro) {
      // Sem rede, o fetch falha com TypeError; um erro do servidor (ex.: limite
      // de perguntas atingido) já vem com a mensagem certa para mostrar.
      const texto = erro instanceof TypeError ? MENSAGEM_ERRO_CONEXAO : erro.message || MENSAGEM_ERRO_CONEXAO
      setMensagens((atual) =>
        atual.map((item) => (item.id === idResposta ? { ...item, texto, digitando: false } : item)),
      )
    } finally {
      setEnviando(false)
    }
  }

  return (
    <>
      <Cabecalho kicker="Assistente" titulo="Chat" aoAbrirMenu={abrirMenu} />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo chat">
          <Cartao className="chat__cartao">
            <div className="chat__lista">
              <AnimatePresence initial={false}>
                {mensagens.map((mensagem) => (
                  <motion.div
                    key={mensagem.id}
                    className={`chat__bolha${mensagem.autor === 'usuario' ? ' chat__bolha--usuario' : ' chat__bolha--ia'}`}
                    initial={{ opacity: 0, y: 10, scale: 0.97 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    transition={{ duration: 0.22, ease: 'easeOut' }}
                  >
                    {mensagem.digitando ? (
                      <span className="chat__digitando">
                        <span />
                        <span />
                        <span />
                      </span>
                    ) : (
                      mensagem.texto
                    )}
                  </motion.div>
                ))}
              </AnimatePresence>
              <div ref={fimDaListaRef} />
            </div>

            <div className="chat__sugestoes">
              {PERGUNTAS_SUGERIDAS.map((pergunta) => (
                <button
                  key={pergunta}
                  type="button"
                  className="chat__sugestao"
                  disabled={enviando}
                  onClick={() => enviarSugestao(pergunta)}
                >
                  {pergunta}
                </button>
              ))}
            </div>

            <form className="chat__formulario" onSubmit={enviarMensagem}>
              <input
                type="text"
                className="chat__entrada"
                placeholder="Digite sua pergunta..."
                value={entrada}
                onChange={(e) => setEntrada(e.target.value)}
                disabled={enviando}
              />
              <Botao type="submit" disabled={enviando || !entrada.trim()}>
                Enviar
              </Botao>
            </form>
          </Cartao>
        </div>
      </div>
    </>
  )
}
