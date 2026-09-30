import { Navigate, Route, Routes } from 'react-router-dom'
import LayoutApp from './componentes/LayoutApp'
import RotaProtegida from './componentes/RotaProtegida'
import { useApp } from './contexto/useApp'
import Acessibilidade from './paginas/Acessibilidade'
import AgendaMedicamentos from './paginas/AgendaMedicamentos'
import Cadastro from './paginas/Cadastro'
import Chat from './paginas/Chat'
import CiclosEncerrados from './paginas/CiclosEncerrados'
import DefinirSenha from './paginas/DefinirSenha'
import EdicaoPerfil from './paginas/EdicaoPerfil'
import Farmacias from './paginas/Farmacias'
import Historico from './paginas/Historico'
import Login from './paginas/Login'
import PainelCuidador from './paginas/PainelCuidador'
import PainelIdoso from './paginas/PainelIdoso'
import PainelPaciente from './paginas/PainelPaciente'

function PainelPrincipal() {
  const { usuario } = useApp()
  return usuario.tipo === 'cuidador' ? <PainelCuidador /> : <PainelIdoso />
}

export default function App() {
  const { autenticado, carregandoSessao } = useApp()

  // Recarregando a sessão salva: não decide ainda entre login e painel.
  if (carregandoSessao) return null

  return (
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
  )
}
