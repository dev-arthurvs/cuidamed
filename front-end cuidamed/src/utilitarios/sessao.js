// Sessão do login: o token (JWT) que o back-end entrega no login e quem é o
// usuário. Fica guardada no navegador para continuar logado ao recarregar a
// página ou voltar outro dia — o token expira sozinho em alguns dias.
const CHAVE_SESSAO = 'cuidamed.sessao'

// Cópia em memória: se o navegador bloquear o armazenamento (aba anônima,
// dados bloqueados), a sessão ainda vale enquanto a página estiver aberta.
let sessaoAtual = lerDoArmazenamento()
let aoExpirar = null

function lerDoArmazenamento() {
  try {
    const sessao = JSON.parse(localStorage.getItem(CHAVE_SESSAO))
    return sessao?.token && sessao?.tipo && sessao?.id ? sessao : null
  } catch {
    return null
  }
}

export function lerSessao() {
  return sessaoAtual
}

export function salvarSessao(sessao) {
  sessaoAtual = sessao
  try {
    localStorage.setItem(CHAVE_SESSAO, JSON.stringify(sessao))
  } catch {
    // sem armazenamento: a sessão vale só enquanto a página estiver aberta
  }
}

export function limparSessao() {
  sessaoAtual = null
  try {
    localStorage.removeItem(CHAVE_SESSAO)
  } catch {
    // nada a limpar
  }
}

// O ContextoApp registra aqui o que fazer quando o servidor recusar o token
// (expirado ou inválido): sair da conta e avisar o usuário.
export function definirAoExpirarSessao(callback) {
  aoExpirar = callback
}

export function notificarSessaoExpirada() {
  limparSessao()
  aoExpirar?.()
}
