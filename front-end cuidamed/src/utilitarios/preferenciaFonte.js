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
    // armazenamento bloqueado: segue sem salvar
  }
}
