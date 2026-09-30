import './Spinner.css'

export default function Spinner({ tamanho = 16, className = '' }) {
  return (
    <span
      className={`spinner ${className}`}
      style={{ width: tamanho, height: tamanho, borderWidth: Math.max(2, tamanho / 7) }}
      role="status"
      aria-label="Carregando"
    />
  )
}
