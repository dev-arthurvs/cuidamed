// Constantes de UI compartilhadas pelas telas do app (não são dados fictícios
// de paciente — os dados reais vêm da API, ver src/utilitarios/api.js).

export const ESTILO_STATUS = {
  tomado: { rotulo: 'Tomado', fundo: '#eaf7f0', texto: '#1b6f4e', ponto: '#1f8a5f' },
  pendente: { rotulo: 'A tomar', fundo: '#eaf3fe', texto: '#0f4c9e', ponto: '#1560c4' },
  atrasado: { rotulo: 'Atrasado', fundo: '#fff7ec', texto: '#8a6a33', ponto: '#d89b2a' },
  perdido: { rotulo: 'Perdido', fundo: '#fdf3f1', texto: '#a9372a', ponto: '#c0392b' },
}

export const FORMAS_MEDICAMENTO = ['Comprimido', 'Cápsula', 'Gota', 'Xarope', 'Injeção', 'Pomada']

// Unidade usada no controle de estoque de cada forma. Pomada fica de fora —
// não tem uma unidade discreta natural (a "dosagem" dela é só a concentração
// da substância, texto livre pra saber qual produto comprar), então não entra
// no controle de estoque/quantidade por dose.
export const UNIDADE_ESTOQUE_POR_FORMA = {
  Comprimido: 'comp',
  Cápsula: 'cáp',
  Gota: 'gotas',
  Xarope: 'ml',
  Injeção: 'amp',
}

export const FREQUENCIAS_MEDICAMENTO = ['1x ao dia', '2x ao dia', '3x ao dia', 'A cada 8 horas', 'Dias alternados', 'Semanal']

export const OPCOES_SEXO = ['Feminino', 'Masculino', 'Outro']
