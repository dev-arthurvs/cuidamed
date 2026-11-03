import { AnimatePresence, motion } from 'framer-motion'
import { Suspense } from 'react'
import { useLocation, useOutlet } from 'react-router-dom'
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
  const location = useLocation()
  const outlet = useOutlet()

  return (
    <div className="layout-app">
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
            {/* Telas carregadas sob demanda: a barra continua na tela enquanto baixam. */}
            <Suspense fallback={null}>{outlet}</Suspense>
          </motion.div>
        </AnimatePresence>
      </div>
      <BotaoChatFlutuante />
      <Toast />
    </div>
  )
}
