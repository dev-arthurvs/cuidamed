// Máscaras de digitação dos campos de formulário.

const apenasDigitos = (texto) => (texto || '').replace(/\D/g, '')

// Telefone brasileiro: "(79) 99999-9999" (celular, 11 dígitos) ou
// "(79) 3333-4444" (fixo, 10 dígitos). Parêntese, espaço e hífen entram
// sozinhos e o campo para no 11º dígito.
// `anterior` resolve o "apagar o hífen": sem ele, apagar um caractere de
// formatação devolveria o mesmo número e o hífen voltaria na hora.
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

// Tem DDD + número? (10 dígitos no fixo, 11 no celular.)
export function telefoneCompleto(valor) {
  const tamanho = apenasDigitos(valor).length
  return tamanho === 10 || tamanho === 11
}

// Nº do cartão do paciente = id do vínculo ativo com o cuidador: 12 → "0000 0012".
export function formatarNumeroCartao(codigo) {
  const digitos = String(codigo).padStart(8, '0')
  return `${digitos.slice(0, 4)} ${digitos.slice(4)}`
}

// Limites das datas: o ano fica com 4 dígitos (sem eles, o navegador aceita
// anos como 202611) e as datas ficam num intervalo que faz sentido.
export const DATA_MINIMA = '1900-01-01'
export const DATA_MAXIMA = '2100-12-31'

export function dataDeHojeISO() {
  const hoje = new Date()
  const mes = String(hoje.getMonth() + 1).padStart(2, '0')
  const dia = String(hoje.getDate()).padStart(2, '0')
  return `${hoje.getFullYear()}-${mes}-${dia}`
}
