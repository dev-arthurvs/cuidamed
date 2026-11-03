// Sessão do login: o token (JWT) que o back-end entrega no login e quem é o
// usuário. Fica guardada no navegador para continuar logado ao recarregar a
// página ou voltar outro dia — o token expira sozinho em alguns dias.
const CHAVE_SESSAO = 'cuidamed.sessao'

// Sai sozinho depois de 30 minutos sem uso (clique, toque, tecla ou rolagem),
// para qualquer tipo de usuário. O horário da última atividade fica guardado
// no navegador: vale entre abas e também se a página for fechada e reaberta.
export const LIMITE_INATIVIDADE_MS = 30 * 60 * 1000
const CHAVE_ULTIMA_ATIVIDADE = 'cuidamed.ultimaAtividade'
// "Lembrar de mim": e-mail ou telefone para já vir preenchido no próximo login.
const CHAVE_LOGIN_LEMBRADO = 'cuidamed.loginLembrado'

// Cópia em memória: se o navegador bloquear o armazenamento (aba anônima,
// dados bloqueados), a sessão ainda vale enquanto a página estiver aberta.
let ultimaAtividadeEmMemoria = Date.now()
let sessaoAtual = lerDoArmazenamento()
let aoExpirar = null

// Sessão salva de uma visita anterior que ficou parada demais: não volta
// (a não ser que tenha entrado com "Lembrar de mim").
if (sessaoAtual && sessaoInativa()) limparSessao()

export function lerLoginLembrado() {
  try {
    return localStorage.getItem(CHAVE_LOGIN_LEMBRADO) || ''
  } catch {
    return ''
  }
}

export function lembrarLogin(login) {
  try {
    if (login) localStorage.setItem(CHAVE_LOGIN_LEMBRADO, login)
    else localStorage.removeItem(CHAVE_LOGIN_LEMBRADO)
  } catch {
    // sem armazenamento: só não lembra
  }
}

function lerUltimaAtividade() {
  try {
    const valor = Number(localStorage.getItem(CHAVE_ULTIMA_ATIVIDADE))
    return valor > 0 ? valor : ultimaAtividadeEmMemoria
  } catch {
    return ultimaAtividadeEmMemoria
  }
}

export function registrarAtividade(agora = Date.now()) {
  ultimaAtividadeEmMemoria = agora
  try {
    localStorage.setItem(CHAVE_ULTIMA_ATIVIDADE, String(agora))
  } catch {
    // sem armazenamento: vale a cópia em memória
  }
}

// Com "Lembrar de mim" a sessão não sai por inatividade: vale até o login
// (token) vencer.
export function sessaoInativa(agora = Date.now()) {
  if (sessaoAtual?.lembrar) return false
  return agora - lerUltimaAtividade() > LIMITE_INATIVIDADE_MS
}

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
  registrarAtividade()
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
    localStorage.removeItem(CHAVE_ULTIMA_ATIVIDADE)
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
