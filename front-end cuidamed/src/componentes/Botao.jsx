import './Botao.css'

const VARIANTES = ['primario', 'secundario', 'perigo', 'texto', 'contorno']

export default function Botao({
  variante = 'primario',
  tamanho = 'padrao',
  larguraTotal = false,
  type = 'button',
  className = '',
  children,
  ...resto
}) {
  const varianteValida = VARIANTES.includes(variante) ? variante : 'primario'
  const classes = [
    'botao',
    `botao--${varianteValida}`,
    tamanho === 'pequeno' ? 'botao--pequeno' : '',
    larguraTotal ? 'botao--largura-total' : '',
    className,
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <button type={type} className={classes} {...resto}>
      {children}
    </button>
  )
}
