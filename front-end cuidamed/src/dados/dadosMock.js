export const ESTILO_STATUS = {
  tomado: { rotulo: 'Tomado', fundo: 'var(--verde-fundo)', texto: 'var(--verde-texto)', ponto: 'var(--verde)' },
  pendente: { rotulo: 'A tomar', fundo: 'var(--azul-fundo)', texto: 'var(--azul-texto)', ponto: 'var(--azul)' },
  atrasado: { rotulo: 'Atrasado', fundo: 'var(--amarelo-fundo)', texto: 'var(--amarelo-texto)', ponto: 'var(--amarelo)' },
  perdido: { rotulo: 'Perdido', fundo: 'var(--vermelho-fundo)', texto: 'var(--vermelho-texto)', ponto: 'var(--vermelho)' },
}

export const FORMAS_MEDICAMENTO = ['Comprimido', 'Cápsula', 'Gota', 'Xarope', 'Injeção', 'Pomada']

export const UNIDADE_ESTOQUE_POR_FORMA = {
  Comprimido: 'comp',
  Cápsula: 'cáp',
  Gota: 'gotas',
  Xarope: 'ml',
  Injeção: 'amp',
}

export const FREQUENCIAS_MEDICAMENTO = ['1x ao dia', '2x ao dia', '3x ao dia', 'A cada 8 horas', 'Dias alternados', 'Semanal']

export const OPCOES_SEXO = ['Feminino', 'Masculino', 'Outro']
