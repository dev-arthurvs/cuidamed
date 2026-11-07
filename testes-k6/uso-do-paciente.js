// O que um paciente faz no app, usado pelos testes de carga e de estresse:
// abre o Início (dados, remédios e últimos 31 dias do histórico), registra a
// dose e desfaz. Registrar e desfazer devolve o estoque, então o teste pode
// repetir sem acumular dados.
import { check, group, sleep } from 'k6'
import { apagar, buscar, dados, diaDeBrasilia, postar } from './comum.js'

export function usarComoPaciente(conta) {
  const hoje = diaDeBrasilia()

  group('Abrir o Início', () => {
    const paciente = buscar(`/api/pacientes/${conta.id}`, conta.token, { nome: 'dados do paciente' })
    const remedios = buscar(`/api/pacientes/${conta.id}/medicamentos`, conta.token, { nome: 'remedios' })
    const historico = buscar(`/api/pacientes/${conta.id}/historicos?de=${diaDeBrasilia(-31)}`, conta.token, { nome: 'historico 31 dias' })
    check(paciente, { 'dados do paciente: 200': (r) => r.status === 200 })
    check(remedios, { 'remedios: 200': (r) => r.status === 200 })
    check(historico, { 'historico: 200': (r) => r.status === 200 })
  })
  sleep(1 + Math.random() * 2)

  group('Registrar e desfazer a dose', () => {
    const registro = postar('/api/historicos', {
      pacienteId: conta.id,
      medicamentoId: conta.medicamentoId,
      data: hoje,
      hora: '08:00',
      status: 'TOMADO',
    }, conta.token, { nome: 'registrar dose' })
    const registrou = check(registro, { 'registrar dose: 201': (r) => r.status === 201 })
    if (registrou) {
      const desfazer = apagar(`/api/historicos/${dados(registro).id}`, conta.token, { nome: 'desfazer dose' })
      check(desfazer, { 'desfazer dose: 204': (r) => r.status === 204 })
    }
  })
  sleep(1 + Math.random() * 2)
}
