import './LogoMarca.css'

export default function LogoMarca({ tamanho = 42, tamanhoTexto, comTexto = true, corTexto = 'escuro', fundo = 'gradiente' }) {
  return (
    <div className="logo-marca">
      <div
        className={`logo-marca__icone logo-marca__icone--${fundo}`}
        style={{ width: tamanho, height: tamanho }}
      >
        <div className="logo-marca__capsula" style={{ width: tamanho * 0.57, height: tamanho * 0.26 }}>
          <div className="logo-marca__capsula-metade" style={{ width: tamanho * 0.285, height: tamanho * 0.26 }} />
        </div>
      </div>
      {comTexto && (
        <span
          className={`logo-marca__texto logo-marca__texto--${corTexto}`}
          style={tamanhoTexto ? { fontSize: tamanhoTexto } : undefined}
        >
          Cuida<span className="logo-marca__destaque">Med</span>
        </span>
      )}
    </div>
  )
}
