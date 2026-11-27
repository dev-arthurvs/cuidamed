import { apagarPacientes, criarContas } from './comum.js'
import { usarComoPaciente } from './uso-do-paciente.js'

const PICO = Number(__ENV.PICO || 400)
const DEGRAU = __ENV.DEGRAU || '1m'

export const options = {
  setupTimeout: '20m',
  stages: [
    { duration: DEGRAU, target: Math.round(PICO / 8) },
    { duration: DEGRAU, target: Math.round(PICO / 4) },
    { duration: DEGRAU, target: Math.round(PICO / 2) },
    { duration: DEGRAU, target: PICO },
    { duration: DEGRAU, target: PICO },
    { duration: DEGRAU, target: Math.round(PICO / 8) },
    { duration: '30s', target: 0 },
  ],
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
