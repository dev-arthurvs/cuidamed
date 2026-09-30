import { useContext } from 'react'
import { ContextoAppContexto } from './contexto'

export function useApp() {
  const contexto = useContext(ContextoAppContexto)
  if (!contexto) throw new Error('useApp precisa ser usado dentro de um ProvedorApp')
  return contexto
}
