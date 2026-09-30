import './Cartao.css'

export default function Cartao({ titulo, acao, className = '', children, ...resto }) {
  const classes = ['cartao', className].filter(Boolean).join(' ')
  return (
    <div className={classes} {...resto}>
      {(titulo || acao) && (
        <div className="cartao__cabecalho">
          {titulo && <h2 className="cartao__titulo">{titulo}</h2>}
          {acao}
        </div>
      )}
      {children}
    </div>
  )
}
