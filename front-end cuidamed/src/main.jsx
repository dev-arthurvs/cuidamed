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
        <App />
      </ProvedorApp>
    </BrowserRouter>
  </StrictMode>,
)
