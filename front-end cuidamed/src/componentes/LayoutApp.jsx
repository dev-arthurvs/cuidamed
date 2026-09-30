import { AnimatePresence, motion } from 'framer-motion'
import { Suspense, useState } from 'react'
import { useLocation, useOutlet } from 'react-router-dom'
import BarraNavegacao from './BarraNavegacao'
import BarraSuperior from './BarraSuperior'
import BotaoChatFlutuante from './BotaoChatFlutuante'
import Toast from './Toast'
import './LayoutApp.css'

const variantesPagina = {
  initial: { opacity: 0, y: 10 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -10 },
}

export default function LayoutApp() {
  const [menuAberto, setMenuAberto] = useState(false)
  const location = useLocation()
  const outlet = useOutlet({ abrirMenu: () => setMenuAberto(true) })

  return (
    <div className="layout-app">
      <BarraNavegacao aberta={menuAberto} aoFechar={() => setMenuAberto(false)} />
      <div className="layout-app__conteudo">
        <BarraSuperior />
        <AnimatePresence mode="popLayout" initial={false}>
          <motion.div
            key={location.pathname}
            className="layout-app__transicao"
            variants={variantesPagina}
            initial="initial"
            animate="animate"
            exit="exit"
            transition={{ duration: 0.22, ease: 'easeInOut' }}
          >
            {/* Telas carregadas sob demanda: o menu e a barra continuam na tela enquanto baixam. */}
            <Suspense fallback={null}>{outlet}</Suspense>
          </motion.div>
        </AnimatePresence>
      </div>
      <BotaoChatFlutuante />
      <Toast />
    </div>
  )
}
