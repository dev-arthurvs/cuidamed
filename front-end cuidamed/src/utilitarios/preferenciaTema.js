// Preferência de tema (claro/escuro), escolhida no menu e guardada no
// navegador. Vale só dentro do sistema: login, cadastro e ativação ficam
// sempre com o visual padrão.
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
    // localStorage indisponível (aba privada, etc.) — preferência vale só pra sessão atual.
  }
}
