// Conversão dos valores em português usados nas telas para os enums em
// inglês maiúsculo esperados pela API, e vice-versa.

function inverterMapa(mapa) {
  return Object.fromEntries(Object.entries(mapa).map(([chave, valor]) => [valor, chave]))
}

export const SEXO_PARA_API = {
  Feminino: 'FEMININO',
  Masculino: 'MASCULINO',
  Outro: 'OUTRO',
}
export const SEXO_DA_API = inverterMapa(SEXO_PARA_API)

export const FORMA_PARA_API = {
  Comprimido: 'COMPRIMIDO',
  Cápsula: 'CAPSULA',
  Gota: 'GOTA',
  Xarope: 'XAROPE',
  Injeção: 'INJECAO',
  Pomada: 'POMADA',
}
export const FORMA_DA_API = inverterMapa(FORMA_PARA_API)

export const FREQUENCIA_PARA_API = {
  '1x ao dia': 'UMA_VEZ_AO_DIA',
  '2x ao dia': 'DUAS_VEZES_AO_DIA',
  '3x ao dia': 'TRES_VEZES_AO_DIA',
  'A cada 8 horas': 'A_CADA_8_HORAS',
  'Dias alternados': 'DIAS_ALTERNADOS',
  Semanal: 'SEMANAL',
}
export const FREQUENCIA_DA_API = inverterMapa(FREQUENCIA_PARA_API)

export const STATUS_HISTORICO_DA_API = {
  TOMADO: 'tomado',
  ATRASADO: 'atrasado',
  PERDIDO: 'perdido',
}
export const STATUS_HISTORICO_PARA_API = inverterMapa(STATUS_HISTORICO_DA_API)
