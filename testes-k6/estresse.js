// TESTE DE ESTRESSE: até onde o app aguenta e se ele se recupera depois.
// Sobe em degraus além do uso normal (até PICO usuários, 400 por padrão) e
// depois desce. Lentidão e erros no topo são esperados: o objetivo é achar o
// limite. A descida mostra se o app volta ao normal sozinho.
//   k6 run estresse.js                          (API de testes no PC)
//   k6 run -e API=https://<api> estresse.js     (Railway)
// No notebook, use um pico menor: k6 run -e PICO=100 estresse.js
import { apagarPacientes, criarContas } from './comum.js'
import { usarComoPaciente } from './uso-do-paciente.js'

const PICO = Number(__ENV.PICO || 400)
const DEGRAU = __ENV.DEGRAU || '1m'

export const options = {
  setupTimeout: '20m',
  stages: [
    { duration: DEGRAU, target: Math.round(PICO / 8) }, // uso normal
    { duration: DEGRAU, target: Math.round(PICO / 4) },
    { duration: DEGRAU, target: Math.round(PICO / 2) },
    { duration: DEGRAU, target: PICO }, // acima do esperado
    { duration: DEGRAU, target: PICO }, // segura no topo
    { duration: DEGRAU, target: Math.round(PICO / 8) }, // recuperação
    { duration: '30s', target: 0 },
  ],
  // Limites de referência: no estresse eles mostram em que ponto o app deixa de
  // atender bem, e não precisam passar.
  thresholds: {
    http_req_duration: ['p(95)<1500'],
    http_req_failed: ['rate<0.05'],
  },
}

export function setup() {
  return { contas: criarContas(PICO) }
}

export default function (contexto) {
  usarComoPaciente(contexto.contas[(__VU - 1) % contexto.contas.length])
}

export function teardown(contexto) {
  apagarPacientes(contexto.contas)
}
