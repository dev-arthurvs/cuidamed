// TESTE DE CARGA: o app aguenta o uso normal esperado?
// Sobe até USUARIOS pacientes usando o app ao mesmo tempo (50 por padrão),
// mantém por alguns minutos e desce. Cada usuário virtual tem a própria conta.
//   k6 run carga.js                         (API de testes no PC)
//   k6 run -e API=https://<api> carga.js    (Railway)
import { apagarPacientes, criarContas } from './comum.js'
import { usarComoPaciente } from './uso-do-paciente.js'

const USUARIOS = Number(__ENV.USUARIOS || 50)
const MANTER = __ENV.MANTER || '3m'

export const options = {
  setupTimeout: '10m',
  stages: [
    { duration: '1m', target: USUARIOS }, // sobe aos poucos
    { duration: MANTER, target: USUARIOS }, // uso normal
    { duration: '30s', target: 0 }, // todos saem
  ],
  // Metas do uso normal: 95% das respostas abaixo de 500 ms e menos de 1% de erros.
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
