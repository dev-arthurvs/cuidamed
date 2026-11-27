import { lerSessao, notificarSessaoExpirada } from './sessao'

export const URL_BASE_API = (import.meta.env.VITE_API_URL || 'http://localhost:8080').replace(/\/$/, '')

const ehRotaDeLogin = (caminho) => caminho.startsWith('/api/auth/')

async function requisitar(caminho, opcoes = {}) {
  const { headers, ...resto } = opcoes
  const sessao = lerSessao()
  const cabecalhos = { 'Content-Type': 'application/json', ...headers }
  if (sessao && !ehRotaDeLogin(caminho)) cabecalhos.Authorization = `Bearer ${sessao.token}`

  const resposta = await fetch(`${URL_BASE_API}${caminho}`, { ...resto, headers: cabecalhos })

  if (!resposta.ok) {
    const corpo = await resposta.json().catch(() => null)
    if (resposta.status === 401 && sessao && !ehRotaDeLogin(caminho)) notificarSessaoExpirada()
    throw new Error(corpo?.message || 'Não foi possível completar a operação. Tente novamente.')
  }

  if (resposta.status === 204) return null
  return resposta.json()
}

export const api = {
  get: (caminho, opcoes) => requisitar(caminho, opcoes),
  post: (caminho, dados, opcoes) => requisitar(caminho, { ...opcoes, method: 'POST', body: JSON.stringify(dados) }),
  put: (caminho, dados, opcoes) => requisitar(caminho, { ...opcoes, method: 'PUT', body: JSON.stringify(dados) }),
  delete: (caminho, opcoes) => requisitar(caminho, { ...opcoes, method: 'DELETE' }),
}
