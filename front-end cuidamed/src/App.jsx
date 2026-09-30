import { lazy, Suspense } from 'react'
import { Navigate, Route, Routes } from 'react-router-dom'
import LayoutApp from './componentes/LayoutApp'
import RotaProtegida from './componentes/RotaProtegida'
import { useApp } from './contexto/useApp'
import AgendaMedicamentos from './paginas/AgendaMedicamentos'
import Login from './paginas/Login'
import PainelCuidador from './paginas/PainelCuidador'
import PainelIdoso from './paginas/PainelIdoso'

// Telas carregadas só quando abertas (o primeiro acesso baixa menos): as
// menos usadas no dia a dia e as pesadas, como Farmácias (com o mapa).
const Acessibilidade = lazy(() => import('./paginas/Acessibilidade'))
const Cadastro = lazy(() => import('./paginas/Cadastro'))
const Chat = lazy(() => import('./paginas/Chat'))
const CiclosEncerrados = lazy(() => import('./paginas/CiclosEncerrados'))
const DefinirSenha = lazy(() => import('./paginas/DefinirSenha'))
const EdicaoPerfil = lazy(() => import('./paginas/EdicaoPerfil'))
const Farmacias = lazy(() => import('./paginas/Farmacias'))
const Historico = lazy(() => import('./paginas/Historico'))
const PainelPaciente = lazy(() => import('./paginas/PainelPaciente'))

function PainelPrincipal() {
  const { usuario } = useApp()
  return usuario.tipo === 'cuidador' ? <PainelCuidador /> : <PainelIdoso />
}

export default function App() {
  const { autenticado, carregandoSessao } = useApp()

  // Recarregando a sessão salva: não decide ainda entre login e painel.
  if (carregandoSessao) return null

  return (
    <Suspense fallback={null}>
    <Routes>
      <Route path="/login" element={autenticado ? <Navigate to="/painel" replace /> : <Login />} />
      <Route path="/cadastro" element={autenticado ? <Navigate to="/painel" replace /> : <Cadastro />} />
      <Route path="/definir-senha" element={autenticado ? <Navigate to="/painel" replace /> : <DefinirSenha />} />

      <Route element={<RotaProtegida />}>
        <Route element={<LayoutApp />}>
          <Route path="/painel" element={<PainelPrincipal />} />
          <Route path="/cuidador/paciente/:pacienteId" element={<PainelCuidador />} />
          <Route element={<RotaProtegida tiposPermitidos={['cuidador']} />}>
            <Route path="/cuidador/paciente/:pacienteId/painel" element={<PainelPaciente />} />
          </Route>
          <Route path="/agenda" element={<AgendaMedicamentos />} />
          <Route path="/ciclos-encerrados" element={<CiclosEncerrados />} />
          <Route path="/historico" element={<Historico />} />
          <Route path="/historico/:pacienteId" element={<Historico />} />
          <Route path="/perfil" element={<EdicaoPerfil />} />
          <Route path="/farmacias" element={<Farmacias />} />
          <Route path="/chat" element={<Chat />} />
          <Route path="/acessibilidade" element={<Acessibilidade />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to={autenticado ? '/painel' : '/login'} replace />} />
    </Routes>
    </Suspense>
  )
}
