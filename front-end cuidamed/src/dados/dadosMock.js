// Constantes de UI compartilhadas pelas telas do app (não são dados fictícios
// de paciente — os dados reais vêm da API, ver src/utilitarios/api.js).

export const ESTILO_STATUS = {
  // Variáveis de cor (global.css): acompanham o modo claro/escuro.
  tomado: { rotulo: 'Tomado', fundo: 'var(--verde-fundo)', texto: 'var(--verde-texto)', ponto: 'var(--verde)' },
  pendente: { rotulo: 'A tomar', fundo: 'var(--azul-fundo)', texto: 'var(--azul-texto)', ponto: 'var(--azul)' },
  atrasado: { rotulo: 'Atrasado', fundo: 'var(--amarelo-fundo)', texto: 'var(--amarelo-texto)', ponto: 'var(--amarelo)' },
  perdido: { rotulo: 'Perdido', fundo: 'var(--vermelho-fundo)', texto: 'var(--vermelho-texto)', ponto: 'var(--vermelho)' },
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
