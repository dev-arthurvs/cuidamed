const CHAVE_SESSAO = 'cuidamed.sessao'

export const LIMITE_INATIVIDADE_MS = 30 * 60 * 1000
const CHAVE_ULTIMA_ATIVIDADE = 'cuidamed.ultimaAtividade'
const CHAVE_LOGIN_LEMBRADO = 'cuidamed.loginLembrado'

let ultimaAtividadeEmMemoria = Date.now()
let sessaoAtual = lerDoArmazenamento()
let aoExpirar = null

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
    // armazenamento bloqueado: segue sem salvar
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
    // armazenamento bloqueado: segue sem salvar
  }
}

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
    // armazenamento bloqueado: segue sem salvar
  }
}

export function limparSessao() {
  sessaoAtual = null
  try {
    localStorage.removeItem(CHAVE_SESSAO)
    localStorage.removeItem(CHAVE_ULTIMA_ATIVIDADE)
  } catch {
    // armazenamento bloqueado: segue sem salvar
  }
}

export function definirAoExpirarSessao(callback) {
  aoExpirar = callback
}

export function notificarSessaoExpirada() {
  limparSessao()
  aoExpirar?.()
}
