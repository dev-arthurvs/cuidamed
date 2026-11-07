// Funções usadas pelos quatro testes: endereço da API, contas de teste e
// chamadas que o app faz. Os testes só falam com a API, como o app; não leem
// nem alteram dados de pacientes reais.
import http from 'k6/http'
import { check, fail } from 'k6'

// API de testes no PC (banco cuidamed_k6) por padrão. Para o Railway:
//   k6 run -e API=https://<endereço-da-api> carga.js
export const API = (__ENV.API || 'http://localhost:8081').replace(/\/$/, '')

// Marca de cada execução: deixa as contas de teste fáceis de achar e de apagar.
export const EXECUCAO = `${Date.now()}`
export const SENHA = 'senhaK6teste'

const JSON_HEADERS = { 'Content-Type': 'application/json' }

export function cabecalhos(token, extras = {}) {
  return { headers: { ...JSON_HEADERS, ...(token ? { Authorization: `Bearer ${token}` } : {}), ...extras } }
}

export function postar(caminho, corpo, token, tags = {}) {
  return http.post(`${API}${caminho}`, JSON.stringify(corpo), { ...cabecalhos(token), tags })
}

export function buscar(caminho, token, tags = {}) {
  return http.get(`${API}${caminho}`, { ...cabecalhos(token), tags })
}

export function apagar(caminho, token, tags = {}) {
  return http.del(`${API}${caminho}`, null, { ...cabecalhos(token), tags })
}

export function dados(resposta) {
  try {
    return resposta.json()
  } catch {
    return null
  }
}

// O app usa a data de Brasília (UTC-3, sem horário de verão).
export function diaDeBrasilia(somarDias = 0) {
  return new Date(Date.now() - 3 * 3600 * 1000 + somarDias * 86400 * 1000).toISOString().slice(0, 10)
}

// Telefone único por conta, pois a API não aceita o mesmo número em duas contas.
export function telefoneDeTeste(numero) {
  const oito = String((Number(EXECUCAO) % 1000000) * 100 + numero).padStart(8, '0').slice(-8)
  return `(79) 9${oito.slice(0, 4)}-${oito.slice(4)}`
}

export function entrar(login, senha = SENHA) {
  const resposta = postar('/api/auth/login', { login, senha }, null, { nome: 'login' })
  const ok = check(resposta, { 'login aceito': (r) => r.status === 200 })
  return ok ? dados(resposta) : null
}

/** Paciente de teste que cria a própria conta, com um remédio diário às 08:00. */
export function criarPacienteComRemedio(numero, { estoque = 1000, inicio = diaDeBrasilia() } = {}) {
  const email = `k6.paciente.${EXECUCAO}.${numero}@teste.cuidamed`
  const cadastro = postar('/api/pacientes', {
    nome: `K6 Paciente ${numero}`,
    email,
    senha: SENHA,
    dataNascimento: '1950-01-01',
    sexo: 'FEMININO',
    telefone: telefoneDeTeste(numero),
  }, null, { nome: 'cadastro' })
  if (cadastro.status !== 201) fail(`cadastro do paciente ${numero} falhou: ${cadastro.status} ${cadastro.body}`)
  const sessao = entrar(email)
  if (!sessao) fail(`login do paciente ${numero} falhou`)
  const remedio = postar('/api/medicamentos', {
    pacienteId: sessao.id,
    nome: 'Losartana K6',
    dosagem: '50mg',
    forma: 'COMPRIMIDO',
    frequencia: 'UMA_VEZ_AO_DIA',
    dataInicio: inicio,
    horarios: ['08:00'],
    quantidadeEstoque: estoque,
    quantidadePorDose: 1,
  }, sessao.token, { nome: 'cadastro' })
  if (remedio.status !== 201) fail(`remédio do paciente ${numero} falhou: ${remedio.status} ${remedio.body}`)
  return { email, id: sessao.id, token: sessao.token, medicamentoId: dados(remedio).id }
}

export function apagarPacientes(contas) {
  for (const conta of contas) {
    if (conta && conta.id) apagar(`/api/pacientes/${conta.id}`, conta.token, { nome: 'limpeza' })
  }
}

/** Cria as contas aos poucos, em lotes, para não medir o cadastro no lugar do uso. */
export function criarContas(quantidade) {
  const contas = []
  for (let i = 1; i <= quantidade; i++) contas.push(criarPacienteComRemedio(i))
  return contas
}
