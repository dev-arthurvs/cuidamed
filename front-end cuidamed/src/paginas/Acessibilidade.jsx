import { AnimatePresence, motion } from 'framer-motion'
import { useState } from 'react'
import { useOutletContext } from 'react-router-dom'
import Cabecalho from '../componentes/Cabecalho'
import Cartao from '../componentes/Cartao'
import SecaoAjuda from '../componentes/SecaoAjuda'
import { useApp } from '../contexto/useApp'
import { GUIA_SECOES } from '../utilitarios/ajudaConteudo'
import './Acessibilidade.css'

export default function Acessibilidade() {
  const { usuario } = useApp()
  const { abrirMenu } = useOutletContext()
  const [chaveAberta, setChaveAberta] = useState(null)

  const secoes = GUIA_SECOES.filter((secao) => secao.publico === 'ambos' || secao.publico === usuario.tipo)

  function alternar(chave) {
    setChaveAberta((atual) => (atual === chave ? null : chave))
  }

  return (
    <>
      <Cabecalho kicker="Ajuda e acessibilidade" titulo="Acessibilidade" aoAbrirMenu={abrirMenu} />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo acessibilidade">
          <Cartao titulo="Como usar cada tela" className="acessibilidade__guia-cartao">
            <p className="acessibilidade__guia-descricao">Clique em uma tela para ver para que ela serve e como usá-la.</p>
            <div className="acessibilidade__lista">
              {secoes.map((secao) => {
                const aberta = chaveAberta === secao.chave
                return (
                  <div key={secao.chave} className="acessibilidade__item">
                    <button
                      type="button"
                      className={`acessibilidade__item-cabecalho${aberta ? ' acessibilidade__item-cabecalho--ativo' : ''}`}
                      onClick={() => alternar(secao.chave)}
                      aria-expanded={aberta}
                    >
                      <span>{secao.titulo}</span>
                      <svg
                        className="acessibilidade__item-seta"
                        width="16"
                        height="16"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2.5"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        style={{ transform: aberta ? 'rotate(180deg)' : 'none' }}
                      >
                        <path d="M6 9l6 6 6-6" />
                      </svg>
                    </button>
                    <AnimatePresence initial={false}>
                      {aberta && (
                        <motion.div
                          className="acessibilidade__item-conteudo"
                          initial={{ height: 0, opacity: 0 }}
                          animate={{ height: 'auto', opacity: 1 }}
                          exit={{ height: 0, opacity: 0 }}
                          transition={{ duration: 0.2, ease: 'easeOut' }}
                        >
                          <div className="acessibilidade__item-miolo">
                            <SecaoAjuda secao={secao} mostrarTitulo={false} />
                          </div>
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                )
              })}
            </div>
          </Cartao>
        </div>
      </div>
    </>
  )
}
