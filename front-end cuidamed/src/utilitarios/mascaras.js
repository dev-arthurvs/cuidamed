const apenasDigitos = (texto) => (texto || '').replace(/\D/g, '')

export function formatarTelefone(valor, anterior = '') {
  let digitos = apenasDigitos(valor).slice(0, 11)
  if (valor.length < anterior.length && digitos === apenasDigitos(anterior)) digitos = digitos.slice(0, -1)
  if (!digitos) return ''
  if (digitos.length <= 2) return `(${digitos}`
  const ddd = digitos.slice(0, 2)
  const numero = digitos.slice(2)
  if (numero.length <= 4) return `(${ddd}) ${numero}`
  const tamanhoInicio = digitos.length === 11 ? 5 : 4
  return `(${ddd}) ${numero.slice(0, tamanhoInicio)}-${numero.slice(tamanhoInicio)}`
}

export function formatarEmailOuTelefone(valor, anterior = '') {
  if (/[^\d\s()-]/.test(valor)) return /^\(\d/.test(anterior) ? valor.replace(/[()\s-]/g, '') : valor
  return formatarTelefone(valor, anterior)
}

export function telefoneCompleto(valor) {
  const tamanho = apenasDigitos(valor).length
  return tamanho === 10 || tamanho === 11
}

export function formatarNumeroCartao(codigo) {
  const digitos = String(codigo).padStart(8, '0')
  return `${digitos.slice(0, 4)} ${digitos.slice(4)}`
}

export const DATA_MINIMA = '1900-01-01'
export const DATA_MAXIMA = '2100-12-31'

export function dataDeHojeISO() {
  const hoje = new Date()
  const mes = String(hoje.getMonth() + 1).padStart(2, '0')
  const dia = String(hoje.getDate()).padStart(2, '0')
  return `${hoje.getFullYear()}-${mes}-${dia}`
}
