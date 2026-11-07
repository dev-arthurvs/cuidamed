import { LazyMotion, domAnimation } from 'framer-motion'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App.jsx'
import { ProvedorApp } from './contexto/ContextoApp.jsx'
import './estilos/global.css'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <ProvedorApp>
        {/* Só os recursos de animação que o app usa, com os componentes "m". */}
        <LazyMotion features={domAnimation}>
          <App />
        </LazyMotion>
      </ProvedorApp>
    </BrowserRouter>
  </StrictMode>,
)
