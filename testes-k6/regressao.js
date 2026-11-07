// TESTE DE REGRESSÃO: as regras que já funcionavam continuam funcionando?
// Confere, uma a uma, regras de segurança e de negócio do app. Rodar depois
// de cada mudança mostra se algo que funcionava quebrou.
//   k6 run regressao.js
import { check, group } from 'k6'
import http from 'k6/http'
import {
  API, apagar, apagarPacientes, buscar, criarPacienteComRemedio, dados, diaDeBrasilia, entrar, EXECUCAO, postar, SENHA, telefoneDeTeste,
} from './comum.js'

export const options = {
  vus: 1,
  iterations: 1,
  thresholds: {
    checks: ['rate==1.0'],
  },
}

export function setup() {
  // A, B e C: pacientes independentes. C tem o remédio desde 20 dias atrás.
  return {
    a: criarPacienteComRemedio(1, { estoque: 10 }),
    b: criarPacienteComRemedio(2),
    c: criarPacienteComRemedio(3, { inicio: diaDeBrasilia(-20) }),
  }
}

export default function ({ a, b, c }) {
  const hoje = diaDeBrasilia()

  group('Segurança: acesso', () => {
    check(buscar(`/api/pacientes/${a.id}`, null), { 'sem login, a API recusa: 401': (r) => r.status === 401 })
    check(buscar(`/api/pacientes/${a.id}`, 'token-invalido'), { 'com token falso, a API recusa: 401': (r) => r.status === 401 })
    check(buscar(`/api/pacientes/${b.id}`, a.token), { 'paciente não vê outro paciente: 403': (r) => r.status === 403 })
    check(buscar(`/api/pacientes/${b.id}/historicos`, a.token), { 'paciente não vê histórico de outro: 403': (r) => r.status === 403 })
    check(postar(`/api/chat/${b.id}`, { mensagem: 'oi' }, a.token), { 'paciente não usa o chat de outro: 403': (r) => r.status === 403 })
    check(postar(`/api/chat/${a.id}`, { mensagem: 'oi' }, null), { 'chat sem login não chama a IA: 401': (r) => r.status === 401 })
    check(http.get(`${API}/actuator/health`), { 'saúde do servidor é pública: 200': (r) => r.status === 200 })
  })

  group('Login e cadastro', () => {
    const errado = postar('/api/auth/login', { login: a.email, senha: 'senha-errada' })
    check(errado, { 'senha errada não entra': (r) => r.status === 401 || r.status === 400 })
    check(entrar(a.email), { 'senha certa entra': (s) => s && s.id === a.id })
    const curta = postar('/api/pacientes', { nome: 'K6 Curta', email: `k6.curta.${EXECUCAO}@teste.cuidamed`, senha: '123' })
    check(curta, { 'senha com menos de 8 caracteres é recusada: 400': (r) => r.status === 400 })
    const repetido = postar('/api/pacientes', {
      nome: 'K6 Repetido', email: `k6.repetido.${EXECUCAO}@teste.cuidamed`, senha: SENHA, telefone: telefoneDeTeste(1),
    })
    check(repetido, { 'telefone já usado em outra conta é recusado': (r) => r.status >= 400 && r.status < 500 })
    check(postar('/api/pacientes', { nome: 'K6 Sem contato', senha: SENHA }), {
      'conta sem e-mail e sem telefone é recusada': (r) => r.status >= 400 && r.status < 500,
    })
  })

  group('Doses e estoque', () => {
    const dose = { pacienteId: a.id, medicamentoId: a.medicamentoId, data: hoje, hora: '08:00', status: 'TOMADO' }
    const registro = postar('/api/historicos', dose, a.token)
    check(registro, { 'registrar dose: 201': (r) => r.status === 201 })
    check(dados(buscar(`/api/medicamentos/${a.medicamentoId}`, a.token)), { 'estoque desconta (10 → 9)': (m) => m && m.quantidadeEstoque === 9 })
    check(postar('/api/historicos', dose, a.token), { 'mesma dose duas vezes é recusada: 409': (r) => r.status === 409 })
    check(apagar(`/api/historicos/${dados(registro).id}`, a.token), { 'desfazer a dose de hoje: 204': (r) => r.status === 204 })
    check(dados(buscar(`/api/medicamentos/${a.medicamentoId}`, a.token)), { 'estoque volta (9 → 10)': (m) => m && m.quantidadeEstoque === 10 })

    const antes = postar('/api/historicos', { ...dose, data: diaDeBrasilia(-1) }, a.token)
    check(antes, { 'dose antes do início do tratamento é recusada: 400': (r) => r.status === 400 })

    const ontem = postar('/api/historicos', { ...dose, pacienteId: c.id, medicamentoId: c.medicamentoId, data: diaDeBrasilia(-1) }, c.token)
    check(ontem, { 'registrar dose de ontem: 201': (r) => r.status === 201 })
    check(apagar(`/api/historicos/${dados(ontem).id}`, c.token), { 'dose de ontem não pode ser desfeita: 400': (r) => r.status === 400 })

    const semanal = postar('/api/medicamentos', {
      pacienteId: a.id, nome: 'Semanal K6', forma: 'COMPRIMIDO', frequencia: 'SEMANAL', dataInicio: hoje, horarios: ['09:00'], quantidadeEstoque: 4, quantidadePorDose: 1,
    }, a.token)
    check(semanal, { 'cadastrar remédio semanal: 201': (r) => r.status === 201 })
    check(postar('/api/medicamentos', { pacienteId: a.id, nome: 'Sem estoque K6', forma: 'COMPRIMIDO', frequencia: 'UMA_VEZ_AO_DIA', dataInicio: hoje, horarios: ['11:00'] }, a.token), {
      'remédio sem quantidade em estoque é recusado: 400': (r) => r.status === 400,
    })
    const amanha = postar('/api/historicos', {
      pacienteId: a.id, medicamentoId: dados(semanal).id, data: diaDeBrasilia(1), hora: '09:00', status: 'TOMADO',
    }, a.token)
    check(amanha, { 'dose semanal em dia sem dose é recusada: 400': (r) => r.status === 400 })
  })

  group('Histórico por período e compactação', () => {
    for (let dia = 2; dia <= 20; dia++) {
      postar('/api/historicos', {
        pacienteId: c.id, medicamentoId: c.medicamentoId, data: diaDeBrasilia(-dia), hora: '08:00', status: 'TOMADO',
      }, c.token)
    }
    const todos = dados(buscar(`/api/pacientes/${c.id}/historicos`, c.token)) || []
    const recentes = dados(buscar(`/api/pacientes/${c.id}/historicos?de=${diaDeBrasilia(-5)}`, c.token)) || []
    const periodo = dados(buscar(`/api/pacientes/${c.id}/historicos?de=${diaDeBrasilia(-20)}&ate=${diaDeBrasilia(-11)}`, c.token)) || []
    check(todos, { 'histórico completo: 20 registros': (l) => l.length === 20 })
    check(recentes, { 'histórico desde 5 dias atrás: 5 registros': (l) => l.length === 5 })
    check(periodo, { 'histórico entre 20 e 11 dias atrás: 10 registros': (l) => l.length === 10 })
    check(periodo, { 'período vem do mais recente ao mais antigo': (l) => l.length > 1 && l[0].data > l[l.length - 1].data })
    const compactada = http.get(`${API}/api/pacientes/${c.id}/historicos`, {
      headers: { Authorization: `Bearer ${c.token}`, 'Accept-Encoding': 'gzip' },
    })
    check(compactada, { 'histórico grande vem compactado (gzip)': (r) => r.headers['Content-Encoding'] === 'gzip' })
  })

  group('Remédios e permissões', () => {
    const lista = dados(buscar(`/api/pacientes/${a.id}/medicamentos`, a.token)) || []
    check(lista, { 'paciente sem cuidador pode cadastrar os próprios remédios': (l) => l.length === 2 })
    const outro = postar('/api/medicamentos', {
      pacienteId: b.id, nome: 'Invasor K6', forma: 'COMPRIMIDO', frequencia: 'UMA_VEZ_AO_DIA', dataInicio: hoje, horarios: ['10:00'], quantidadeEstoque: 4, quantidadePorDose: 1,
    }, a.token)
    check(outro, { 'paciente não cadastra remédio para outro: 403': (r) => r.status === 403 })
  })
}

export function teardown(contexto) {
  apagarPacientes([contexto.a, contexto.b, contexto.c])
}
