import { apagarPacientes, criarContas } from './comum.js'
import { usarComoPaciente } from './uso-do-paciente.js'

const USUARIOS = Number(__ENV.USUARIOS || 50)
const MANTER = __ENV.MANTER || '3m'

export const options = {
  setupTimeout: '10m',
  stages: [
    { duration: '1m', target: USUARIOS },
    { duration: MANTER, target: USUARIOS },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    'http_req_duration{nome:historico 31 dias}': ['p(95)<500'],
    'http_req_duration{nome:registrar dose}': ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
    checks: ['rate>0.99'],
  },
}

export function setup() {
  return { contas: criarContas(USUARIOS) }
}

export default function (contexto) {
  usarComoPaciente(contexto.contas[(__VU - 1) % contexto.contas.length])
}

export function teardown(contexto) {
  apagarPacientes(contexto.contas)
}
