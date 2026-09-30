import { Navigate, Outlet, useOutletContext } from 'react-router-dom'
import { useApp } from '../contexto/useApp'

export default function RotaProtegida({ tiposPermitidos }) {
  const { autenticado, usuario } = useApp()
  const contextoExterno = useOutletContext()

  if (!autenticado) return <Navigate to="/login" replace />
  if (tiposPermitidos && !tiposPermitidos.includes(usuario.tipo)) return <Navigate to="/painel" replace />

  return <Outlet context={contextoExterno} />
}
