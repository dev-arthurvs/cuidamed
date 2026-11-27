import http from 'k6/http'
import { check, fail } from 'k6'

export const API = (__ENV.API || 'http://localhost:8081').replace(/\/$/, '')

export const EXECUCAO = `${Date.now()}`
export const SENHA = 'senhaK6teste'

const JSON_HEADERS = { 'Content-Type': 'application/json' }

export function cabecalhos(token, extras = {}) {
  return { headers: { ...JSON_HEADERS, ...(token ? { Authorization: `Bearer ${token}` } : {}), ...extras } }
}

function opcoes(token, tags, esperado) {
  const extra = esperado === undefined ? {} : { responseCallback: http.expectedStatuses(...[].concat(esperado)) }
  return { ...cabecalhos(token), tags, ...extra }
}

export function postar(caminho, corpo, token, tags = {}, esperado) {
  return http.post(`${API}${caminho}`, JSON.stringify(corpo), opcoes(token, tags, esperado))
}

export function buscar(caminho, token, tags = {}, esperado) {
  return http.get(`${API}${caminho}`, opcoes(token, tags, esperado))
}

export function apagar(caminho, token, tags = {}, esperado) {
  return http.del(`${API}${caminho}`, null, opcoes(token, tags, esperado))
}

export function dados(resposta) {
  try {
    return resposta.json()
  } catch {
    return null
  }
}

export function diaDeBrasilia(somarDias = 0) {
  return new Date(Date.now() - 3 * 3600 * 1000 + somarDias * 86400 * 1000).toISOString().slice(0, 10)
}

export function telefoneDeTeste(numero) {
  const oito = String((Number(EXECUCAO) % 1000000) * 100 + numero).padStart(8, '0').slice(-8)
  return `(79) 9${oito.slice(0, 4)}-${oito.slice(4)}`
}

export function entrar(login, senha = SENHA) {
  const resposta = postar('/api/auth/login', { login, senha }, null, { nome: 'login' })
  const ok = check(resposta, { 'login aceito': (r) => r.status === 200 })
  return ok ? dados(resposta) : null
}

export function criarPacienteComRemedio(numero, { estoque = 1000, inicio = diaDeBrasilia() } = {}) {
  const email = `k6.paciente.${EXECUCAO}.${numero}@teste.cuidamed`
  // Guardado na conta: o setup do k6 roda em outro contexto, com outro EXECUCAO.
  const telefone = telefoneDeTeste(numero)
  const cadastro = postar('/api/pacientes', {
    nome: `K6 Paciente ${numero}`,
    email,
    senha: SENHA,
    dataNascimento: '1950-01-01',
    sexo: 'FEMININO',
    telefone,
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
  return { email, telefone, id: sessao.id, token: sessao.token, medicamentoId: dados(remedio).id }
}

export function apagarPacientes(contas) {
  for (const conta of contas) {
    if (conta && conta.id) apagar(`/api/pacientes/${conta.id}`, conta.token, { nome: 'limpeza' })
  }
}

export function criarContas(quantidade) {
  const contas = []
  for (let i = 1; i <= quantidade; i++) contas.push(criarPacienteComRemedio(i))
  return contas
}
