import { useState } from 'react'
import { DATA_MAXIMA, DATA_MINIMA, formatarEmailOuTelefone, formatarTelefone } from '../utilitarios/mascaras'
import { ICONE_OLHO, ICONE_OLHO_FECHADO } from './iconesCampo'
import './Campo.css'

// `icone`: ícone dentro do campo, à esquerda (ver iconesCampo.jsx).
// `alternarSenha`: em campos de senha, botão de "olho" para mostrar/esconder
// o que foi digitado (ajuda quem erra a digitação, comum entre idosos).
// Sem esses dois, o campo é exatamente como antes.
// Máscaras automáticas: telefone (tipo="tel") vira "(79) 99999-9999" e data
// (tipo="date") fica com ano de 4 dígitos, entre 1900 e 2100 (min/max podem
// ser passados para restringir mais, ex.: nascimento até hoje). Em
// tipo="email-ou-telefone", só números ganham a máscara de telefone.
export default function Campo({ rotulo, tipo = 'texto', className = '', icone, alternarSenha = false, children, ...resto }) {
  const [senhaVisivel, setSenhaVisivel] = useState(false)
  const classes = ['campo', className].filter(Boolean).join(' ')
  const comOlho = tipo === 'password' && alternarSenha

  let propsEntrada = resto
  if (tipo === 'tel') {
    const { onChange, value } = resto
    propsEntrada = {
      inputMode: 'numeric',
      maxLength: 15,
      ...resto,
      onChange: (evento) => {
        evento.target.value = formatarTelefone(evento.target.value, value ?? '')
        onChange?.(evento)
      },
    }
  } else if (tipo === 'email-ou-telefone') {
    const { onChange, value } = resto
    propsEntrada = {
      ...resto,
      onChange: (evento) => {
        evento.target.value = formatarEmailOuTelefone(evento.target.value, value ?? '')
        onChange?.(evento)
      },
    }
  } else if (tipo === 'date') {
    propsEntrada = { min: DATA_MINIMA, max: DATA_MAXIMA, ...resto }
  }

  function renderizarEntrada() {
    if (tipo === 'select') {
      return (
        <select className="campo__entrada" {...resto}>
          {children}
        </select>
      )
    }
    if (tipo === 'textarea') return <textarea className="campo__entrada campo__entrada--area" {...resto} />

    const tipoInput = tipo === 'texto' || tipo === 'email-ou-telefone' ? 'text' : comOlho && senhaVisivel ? 'text' : tipo
    if (!icone && !comOlho) return <input type={tipoInput} className="campo__entrada" {...propsEntrada} />

    const classesEntrada = ['campo__entrada', icone ? 'campo__entrada--com-icone' : '', comOlho ? 'campo__entrada--com-olho' : '']
      .filter(Boolean)
      .join(' ')
    return (
      <div className="campo__controle">
        {icone && <span className="campo__icone">{icone}</span>}
        <input type={tipoInput} className={classesEntrada} {...propsEntrada} />
        {comOlho && (
          <button
            type="button"
            className="campo__olho"
            onClick={() => setSenhaVisivel((visivel) => !visivel)}
            aria-label={senhaVisivel ? 'Esconder senha' : 'Mostrar senha'}
            title={senhaVisivel ? 'Esconder senha' : 'Mostrar senha'}
          >
            {senhaVisivel ? ICONE_OLHO_FECHADO : ICONE_OLHO}
          </button>
        )}
      </div>
    )
  }

  return (
    <div className={classes}>
      {rotulo && <label className="campo__rotulo">{rotulo}</label>}
      {renderizarEntrada()}
    </div>
  )
}
