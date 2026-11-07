// TESTE DE INTEGRAÇÃO: as partes do app funcionam juntas, de ponta a ponta?
// Um cuidador e um paciente de teste passam pelo caminho completo: cadastro,
// login, vínculo, remédio cadastrado pelo cuidador, dose registrada pelo
// paciente (o estoque desconta), desfazer (o estoque volta) e o cuidador vendo
// tudo. Todas as verificações precisam passar.
//   k6 run integracao.js
import { check, fail, group } from 'k6'
import { apagar, buscar, dados, diaDeBrasilia, entrar, EXECUCAO, postar, SENHA, telefoneDeTeste } from './comum.js'

export const options = {
  vus: 1,
  iterations: 1,
  thresholds: {
    checks: ['rate==1.0'],
  },
}

function exigir(condicao, mensagem) {
  if (!condicao) fail(mensagem)
}

export default function () {
  const hoje = diaDeBrasilia()
  const emailCuidador = `k6.cuidador.${EXECUCAO}@teste.cuidamed`
  const emailPaciente = `k6.paciente.integracao.${EXECUCAO}@teste.cuidamed`
  let cuidador
  let paciente
  let medicamentoId

  group('1. Cadastro e login', () => {
    const c = postar('/api/cuidadores', {
      nome: 'K6 Cuidador', email: emailCuidador, senha: SENHA, profissao: 'Teste', telefone: telefoneDeTeste(90),
    })
    check(c, { 'cuidador cadastrado: 201': (r) => r.status === 201 })
    const p = postar('/api/pacientes', {
      nome: 'K6 Paciente Integracao', email: emailPaciente, senha: SENHA, dataNascimento: '1948-05-10', sexo: 'MASCULINO',
      telefone: telefoneDeTeste(91),
    })
    check(p, { 'paciente cadastrado: 201': (r) => r.status === 201 })
    cuidador = entrar(emailCuidador)
    paciente = entrar(emailPaciente)
    exigir(cuidador && paciente, 'login do cuidador ou do paciente falhou')
    check(cuidador, { 'login identifica o cuidador': (s) => s.tipo === 'CUIDADOR' })
    check(paciente, { 'login identifica o paciente': (s) => s.tipo === 'PACIENTE' })
    // Login também pelo telefone (só os dígitos contam).
    check(entrar(telefoneDeTeste(91).replace(/\D/g, '')), { 'login pelo telefone funciona': (s) => s && s.id === paciente.id })
  })

  group('2. Vínculo entre paciente e cuidador', () => {
    const pedido = postar(`/api/pacientes/${paciente.id}/solicitar-vinculo`, { cuidadorEmail: emailCuidador }, paciente.token)
    check(pedido, { 'paciente pede o vínculo: 204': (r) => r.status === 204 })
    const solicitacoes = dados(buscar(`/api/cuidadores/${cuidador.id}/solicitacoes`, cuidador.token)) || []
    check(solicitacoes, { 'cuidador vê o pedido': (lista) => lista.some((item) => item.id === paciente.id) })
    const aceite = postar(`/api/pacientes/${paciente.id}/aceitar-vinculo`, {}, cuidador.token)
    check(aceite, { 'cuidador aceita: 204': (r) => r.status === 204 })
    const pacientes = dados(buscar(`/api/cuidadores/${cuidador.id}/pacientes`, cuidador.token)) || []
    check(pacientes, { 'paciente aparece na lista do cuidador': (lista) => lista.some((item) => item.id === paciente.id) })
    const ficha = dados(buscar(`/api/pacientes/${paciente.id}`, paciente.token))
    check(ficha, { 'ficha do paciente mostra o cuidador': (f) => f && f.cuidadorId === cuidador.id })
  })

  group('3. Cuidador cadastra o remédio e o paciente vê', () => {
    const remedio = postar('/api/medicamentos', {
      pacienteId: paciente.id, nome: 'Metformina K6', dosagem: '850mg', forma: 'COMPRIMIDO', frequencia: 'UMA_VEZ_AO_DIA',
      dataInicio: hoje, horarios: ['08:00'], quantidadeEstoque: 10, quantidadePorDose: 2,
    }, cuidador.token)
    check(remedio, { 'cuidador cadastra o remédio: 201': (r) => r.status === 201 })
    medicamentoId = dados(remedio) && dados(remedio).id
    exigir(medicamentoId, 'remédio não foi cadastrado')
    const lista = dados(buscar(`/api/pacientes/${paciente.id}/medicamentos`, paciente.token)) || []
    check(lista, { 'paciente vê o remédio com o horário': (l) => l.some((m) => m.id === medicamentoId && m.horarios.includes('08:00')) })
  })

  group('4. Dose: registrar desconta o estoque e desfazer devolve', () => {
    const registro = postar('/api/historicos', {
      pacienteId: paciente.id, medicamentoId, data: hoje, hora: '08:00', status: 'TOMADO',
    }, paciente.token)
    check(registro, { 'paciente registra a dose: 201': (r) => r.status === 201 })
    const depois = dados(buscar(`/api/medicamentos/${medicamentoId}`, paciente.token))
    check(depois, { 'estoque desconta a quantidade por dose (10 → 8)': (m) => m && m.quantidadeEstoque === 8 })
    const visto = dados(buscar(`/api/pacientes/${paciente.id}/historicos?de=${hoje}`, cuidador.token)) || []
    check(visto, { 'cuidador vê a dose no histórico': (l) => l.some((h) => h.medicamentoId === medicamentoId && h.status === 'TOMADO') })
    const desfazer = apagar(`/api/historicos/${dados(registro).id}`, paciente.token)
    check(desfazer, { 'paciente desfaz a dose: 204': (r) => r.status === 204 })
    const devolvido = dados(buscar(`/api/medicamentos/${medicamentoId}`, paciente.token))
    check(devolvido, { 'estoque volta (8 → 10)': (m) => m && m.quantidadeEstoque === 10 })
    const vazio = dados(buscar(`/api/pacientes/${paciente.id}/historicos?de=${hoje}`, paciente.token)) || [1]
    check(vazio, { 'histórico de hoje fica vazio': (l) => l.length === 0 })
  })

  group('5. Limpeza', () => {
    check(apagar(`/api/pacientes/${paciente.id}`, cuidador.token), { 'cuidador exclui o paciente de teste: 204': (r) => r.status === 204 })
  })
}
