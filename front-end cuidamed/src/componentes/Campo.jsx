import './Campo.css'

export default function Campo({ rotulo, tipo = 'texto', className = '', children, ...resto }) {
  const classes = ['campo', className].filter(Boolean).join(' ')

  return (
    <div className={classes}>
      {rotulo && <label className="campo__rotulo">{rotulo}</label>}
      {tipo === 'select' ? (
        <select className="campo__entrada" {...resto}>
          {children}
        </select>
      ) : tipo === 'textarea' ? (
        <textarea className="campo__entrada campo__entrada--area" {...resto} />
      ) : (
        <input type={tipo === 'texto' ? 'text' : tipo} className="campo__entrada" {...resto} />
      )}
    </div>
  )
}
