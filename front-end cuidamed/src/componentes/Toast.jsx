import { useApp } from '../contexto/useApp'
import './Toast.css'

export default function Toast() {
  const { toast } = useApp()
  if (!toast) return null
  return (
    <div className="toast" key={toast}>
      {toast}
    </div>
  )
}
