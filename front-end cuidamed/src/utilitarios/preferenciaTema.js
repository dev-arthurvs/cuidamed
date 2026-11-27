const CHAVE_TEMA = 'cuidamed_tema'

export function obterTemaSalvo() {
  try {
    return localStorage.getItem(CHAVE_TEMA) === 'escuro' ? 'escuro' : 'claro'
  } catch {
    return 'claro'
  }
}

export function salvarTema(tema) {
  try {
    localStorage.setItem(CHAVE_TEMA, tema)
  } catch {
    // armazenamento bloqueado: segue sem salvar
  }
}
