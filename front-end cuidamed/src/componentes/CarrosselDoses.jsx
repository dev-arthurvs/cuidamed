import { AnimatePresence, motion } from 'framer-motion'
import { useEffect, useState } from 'react'
import Botao from './Botao'
import { formatarQuantidadePorDose } from '../utilitarios/whatsapp'
import './CarrosselDoses.css'

const TEMPO_DESFAZER_MS = 12000

const FIM = { id: 'fim', fim: true }

function IconeStatus({ status }) {
  if (status === 'tomado') {
    return (
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M5 12.5l4.5 4.5L19 7.5" />
      </svg>
    )
  }
  if (status === 'perdido') {
    return (
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" aria-hidden="true">
        <path d="M6 6l12 12M18 6L6 18" />
      </svg>
    )
  }
  return <span className="carrossel-doses__ponto" aria-hidden="true" />
}

const ROTULO_STATUS = { tomado: 'Tomada', perdido: 'Perdida', atrasado: 'Atrasada', pendente: 'Pendente' }

// Linha pequena (dose anterior em cima, próxima embaixo): tomada em verde com
// ✓; perdida em vermelho, riscada e com ✕; pendente/atrasada em branco.
function LinhaDose({ dose, posicao }) {
  if (!dose) return <div className="carrossel-doses__vaga" />
  if (dose.fim) {
    return (
      <div className="carrossel-doses__linha">
        <span className="carrossel-doses__linha-texto">Fim das doses de hoje</span>
      </div>
    )
  }
  return (
    <div
      role="group"
      className={`carrossel-doses__linha carrossel-doses__linha--${dose.status}`}
      aria-label={`${posicao === 'anterior' ? 'Dose anterior' : 'Próxima dose'}: ${dose.horario}, ${dose.nome}, ${ROTULO_STATUS[dose.status]}`}
    >
      <span className="carrossel-doses__linha-texto">
        <strong>{dose.horario}</strong> {[dose.nome, formatarQuantidadePorDose(dose)].filter(Boolean).join(' · ')}
      </span>
      <IconeStatus status={dose.status} />
    </div>
  )
}

/**
 * Card "Doses de hoje" da tela inicial: carrossel vertical com a dose anterior
 * (pequena, em cima), a dose em foco (grande, com "Registrar dose" ao lado
 * quando é a dose da vez) e a próxima (pequena, embaixo). Só as duas setas
 * trocam de dose: rolar ou arrastar sobre o card move a página.
 */
export default function CarrosselDoses({ doses, aoRegistrar, aoDesfazer }) {
  const indiceDaVez = doses.findIndex((dose) => dose.status === 'pendente' || dose.status === 'atrasado')
  // Sem dose da vez, entra um item final "Nada pendente" depois da última dose.
  const itens = indiceDaVez === -1 ? [...doses, FIM] : doses
  const indiceInicial = indiceDaVez === -1 ? itens.length - 1 : indiceDaVez
  const chaveDaVez = indiceDaVez === -1 ? `fim-${doses.length}` : doses[indiceDaVez].id

  const [foco, setFoco] = useState(indiceInicial)
  const [direcao, setDirecao] = useState(1)
  // Logo depois de registrar, oferece "Desfazer" por alguns segundos.
  const [registrada, setRegistrada] = useState(null)
  useEffect(() => {
    if (!registrada) return undefined
    const temporizador = setTimeout(() => setRegistrada(null), TEMPO_DESFAZER_MS)
    return () => clearTimeout(temporizador)
  }, [registrada])

  async function registrar(dose) {
    if (await aoRegistrar(dose.id)) setRegistrada(dose)
  }

  function desfazer(dose) {
    setRegistrada(null)
    aoDesfazer(dose)
  }

  // Quando a dose da vez muda (ex.: acabou de registrar), o foco volta pra ela.
  const [chaveAnterior, setChaveAnterior] = useState(chaveDaVez)
  if (chaveAnterior !== chaveDaVez) {
    setChaveAnterior(chaveDaVez)
    setDirecao(1)
    setFoco(indiceInicial)
  }

  const focoValido = Math.min(Math.max(foco, 0), itens.length - 1)
  const atual = itens[focoValido]
  const anterior = itens[focoValido - 1]
  const proxima = itens[focoValido + 1]

  function irPara(indice) {
    if (indice < 0 || indice >= itens.length || indice === focoValido) return
    setDirecao(indice > focoValido ? 1 : -1)
    setFoco(indice)
  }

  const ehDaVez = !atual.fim && focoValido === indiceDaVez
  const temPerdida = doses.some((dose) => dose.status === 'perdido')

  return (
    <div className="carrossel-doses">
      <div className="carrossel-doses__topo">
        <span className="carrossel-doses__kicker">Doses de hoje</span>
        {doses.length > 0 && (
          <button
            type="button"
            className="carrossel-doses__seta"
            onClick={() => irPara(focoValido - 1)}
            disabled={focoValido === 0}
            aria-label="Dose anterior"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M6 15l6-6 6 6" />
            </svg>
          </button>
        )}
      </div>

      {registrada && (
        <div className="carrossel-doses__registrada" role="status">
          <span>Dose das {registrada.horario} registrada.</span>
          <button type="button" className="carrossel-doses__desfazer" onClick={() => desfazer(registrada)}>
            Desfazer
          </button>
        </div>
      )}

      <div className="carrossel-doses__janela">
        <AnimatePresence mode="wait" initial={false} custom={direcao}>
          <motion.div
            key={atual.id}
            className="carrossel-doses__trilho"
            custom={direcao}
            variants={{
              entrar: (d) => ({ opacity: 0, y: d * 28 }),
              centro: { opacity: 1, y: 0 },
              sair: (d) => ({ opacity: 0, y: d * -28 }),
            }}
            initial="entrar"
            animate="centro"
            exit="sair"
            transition={{ duration: 0.2, ease: 'easeOut' }}
          >
            <LinhaDose dose={anterior} posicao="anterior" />

            {atual.fim ? (
              <div className="carrossel-doses__atual">
                <div className="carrossel-doses__atual-info">
                  <div className="carrossel-doses__nome">Nada pendente</div>
                  <div className="carrossel-doses__quantidade">
                    {doses.length === 0
                      ? 'Nenhuma dose para hoje.'
                      : temPerdida
                        ? 'Algumas doses de hoje foram perdidas.'
                        : 'Todas as doses de hoje foram tomadas.'}
                  </div>
                </div>
              </div>
            ) : (
              <div className={`carrossel-doses__atual carrossel-doses__atual--${atual.status}`}>
                <div className="carrossel-doses__atual-info">
                  <div className="carrossel-doses__hora-linha">
                    <span className="carrossel-doses__hora">{atual.horario}</span>
                    {atual.status !== 'pendente' && (
                      <span className={`carrossel-doses__selo carrossel-doses__selo--${atual.status}`}>
                        <IconeStatus status={atual.status} />
                        {ROTULO_STATUS[atual.status]}
                      </span>
                    )}
                  </div>
                  <div className="carrossel-doses__nome">{atual.nome}</div>
                  {/* Quantidade por dose (ex.: "1 comp"); pomada não tem. */}
                  {formatarQuantidadePorDose(atual) && (
                    <div className="carrossel-doses__quantidade">{formatarQuantidadePorDose(atual)}</div>
                  )}
                </div>
                {ehDaVez && (
                  <Botao className="carrossel-doses__botao" onClick={() => registrar(atual)}>
                    Registrar dose
                  </Botao>
                )}
                {atual.status === 'tomado' && (
                  <button type="button" className="carrossel-doses__desfazer" onClick={() => desfazer(atual)}>
                    Desfazer
                  </button>
                )}
              </div>
            )}

            {/* Abre espaço para a seta do canto inferior, que fica fora da animação. */}
            <div className="carrossel-doses__linha-proxima">
              <LinhaDose dose={proxima} posicao="proxima" />
            </div>
          </motion.div>
        </AnimatePresence>
      </div>

      {doses.length > 0 && (
        <button
          type="button"
          className="carrossel-doses__seta carrossel-doses__seta--baixo"
          onClick={() => irPara(focoValido + 1)}
          disabled={focoValido === itens.length - 1}
          aria-label="Próxima dose"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M6 9l6 6 6-6" />
          </svg>
        </button>
      )}
    </div>
  )
}
