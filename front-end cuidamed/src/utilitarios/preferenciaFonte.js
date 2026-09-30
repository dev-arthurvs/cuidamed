// Preferência de tamanho de fonte (acessibilidade). Como praticamente todo o
// app usa font-size fixo em px (não rem), a forma confiável de escalar tudo de
// uma vez — textos, ícones, espaçamentos — é o zoom do elemento raiz, não um
// font-size no <html> (que só afetaria unidades relativas).
export const CHAVE_TAMANHO_FONTE = 'cuidamed_tamanho_fonte'

export const ZOOM_POR_TAMANHO = {
  pequena: 0.9,
  media: 1,
  grande: 1.15,
}

export const OPCOES_TAMANHO_FONTE = [
  { valor: 'pequena', rotulo: 'Pequena' },
  { valor: 'media', rotulo: 'Média' },
  { valor: 'grande', rotulo: 'Grande' },
]

export function obterTamanhoFonteSalvo() {
  try {
    const salvo = localStorage.getItem(CHAVE_TAMANHO_FONTE)
    return salvo && ZOOM_POR_TAMANHO[salvo] ? salvo : 'media'
  } catch {
    return 'media'
  }
}

export function salvarTamanhoFonte(tamanho) {
  try {
    localStorage.setItem(CHAVE_TAMANHO_FONTE, tamanho)
  } catch {
    // localStorage indisponível (aba privada, etc.) — preferência vale só pra sessão atual.
  }
}
