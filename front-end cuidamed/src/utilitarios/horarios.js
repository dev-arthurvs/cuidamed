// Regra de negócio do alerta de horário: compara o horário agendado da dose
// com o horário atual para decidir se ela está pendente, atrasada ou perdida.
import { UNIDADE_ESTOQUE_POR_FORMA } from '../dados/dadosMock'

const TOLERANCIA_ATRASO_MIN = 15
const LIMITE_PERDIDA_MIN = 180

export function paraMinutos(horario) {
  const [horas, minutos] = horario.split(':').map(Number)
  return horas * 60 + minutos
}

export function minutosAgora(data = new Date()) {
  return data.getHours() * 60 + data.getMinutes()
}

export function calcularStatusAtual(dose, agoraEmMinutos = minutosAgora()) {
  if (dose.status === 'tomado') return 'tomado'
  const diferenca = agoraEmMinutos - paraMinutos(dose.horario)
  if (diferenca < TOLERANCIA_ATRASO_MIN) return 'pendente'
  if (diferenca < LIMITE_PERDIDA_MIN) return 'atrasado'
  return 'perdido'
}

export function dataAtualISO(data = new Date()) {
  const ano = data.getFullYear()
  const mes = String(data.getMonth() + 1).padStart(2, '0')
  const dia = String(data.getDate()).padStart(2, '0')
  return `${ano}-${mes}-${dia}`
}

export function formatarDataPorExtenso(data = new Date()) {
  const texto = data.toLocaleDateString('pt-BR', { weekday: 'long', day: 'numeric', month: 'long' })
  return texto.charAt(0).toUpperCase() + texto.slice(1)
}

export function formatarHoraAtual(data = new Date()) {
  return data.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}

export function obterIniciais(nomeCompleto) {
  const partes = nomeCompleto.trim().split(/\s+/)
  const primeira = partes[0]?.[0] || ''
  const ultima = partes.length > 1 ? partes[partes.length - 1][0] : ''
  return (primeira + ultima).toUpperCase()
}

// No próprio dia do "fim" do ciclo, só considera encerrado depois que todas
// as doses de hoje já foram registradas no histórico — senão o medicamento
// desapareceria da agenda antes do cuidador conseguir confirmar a última dose.
export function medicamentoEncerrado(medicamento, hojeIso = dataAtualISO(), historico = []) {
  if (!medicamento.fim) return false
  if (medicamento.fim < hojeIso) return true
  if (medicamento.fim > hojeIso) return false
  if (!temDoseNoDia(medicamento, hojeIso)) return true // último dia sem dose: ciclo já cumprido
  return medicamento.horarios.every((horario) =>
    historico.some((item) => item.medicamentoId === medicamento.id && item.data === hojeIso && item.horario === horario),
  )
}

// false enquanto a data de início do tratamento ainda não chegou.
export function medicamentoIniciado(medicamento, hojeIso = dataAtualISO()) {
  return !medicamento.inicio || medicamento.inicio <= hojeIso
}

function diasEntre(deIso, ateIso) {
  return Math.round((new Date(`${ateIso}T00:00:00Z`) - new Date(`${deIso}T00:00:00Z`)) / 86400000)
}

function somarDias(dataIso, dias) {
  const data = new Date(`${dataIso}T00:00:00Z`)
  data.setUTCDate(data.getUTCDate() + dias)
  return data.toISOString().slice(0, 10)
}

// Frequências que não são diárias: "Dias alternados" = dose a cada 2 dias e
// "Semanal" = a cada 7, contando a partir da data de início. As demais
// (1x/2x/3x ao dia, a cada 8 horas) têm dose todos os dias.
const INTERVALO_DIAS_POR_FREQUENCIA = { 'Dias alternados': 2, Semanal: 7, DIAS_ALTERNADOS: 2, SEMANAL: 7 }

export function intervaloEntreDiasDeDose(medicamento) {
  return INTERVALO_DIAS_POR_FREQUENCIA[medicamento.frequencia] || 1
}

// O remédio tem dose nesse dia? Considera início, fim e a frequência.
export function temDoseNoDia(medicamento, diaIso = dataAtualISO()) {
  if (medicamento.inicio && diaIso < medicamento.inicio) return false
  if (medicamento.fim && diaIso > medicamento.fim) return false
  const intervalo = intervaloEntreDiasDeDose(medicamento)
  if (intervalo === 1 || !medicamento.inicio) return true
  return diasEntre(medicamento.inicio, diaIso) % intervalo === 0
}

// Próximo dia (a partir de [aPartirIso], inclusive) com dose; null se o ciclo acaba antes.
export function proximoDiaDeDose(medicamento, aPartirIso = dataAtualISO()) {
  let dia = medicamento.inicio && medicamento.inicio > aPartirIso ? medicamento.inicio : aPartirIso
  for (let i = 0; i < 8; i += 1) {
    if (medicamento.fim && dia > medicamento.fim) return null
    if (temDoseNoDia(medicamento, dia)) return dia
    dia = somarDias(dia, 1)
  }
  return null
}

// Quantos dias com dose existem entre [deIso] e [ateIso] (inclusive).
function contarDiasDeDose(medicamento, deIso, ateIso) {
  if (ateIso < deIso) return 0
  const intervalo = intervaloEntreDiasDeDose(medicamento)
  const total = diasEntre(deIso, ateIso) + 1
  if (intervalo === 1 || !medicamento.inicio) return total
  const primeiro = proximoDiaDeDose(medicamento, deIso)
  if (!primeiro || primeiro > ateIso) return 0
  return Math.floor(diasEntre(primeiro, ateIso) / intervalo) + 1
}

// null quando o medicamento não tem data final (uso contínuo/indefinido) —
// nesse caso não dá pra calcular quantos dias faltam pro ciclo acabar.
export function calcularDiasRestantesCiclo(dataFimIso, hojeIso = dataAtualISO()) {
  if (!dataFimIso) return null
  const fim = new Date(`${dataFimIso}T00:00:00Z`)
  const hoje = new Date(`${hojeIso}T00:00:00Z`)
  return Math.round((fim - hoje) / 86400000)
}

export function formatarDataCurta(dataIso) {
  return new Date(`${dataIso}T00:00:00`).toLocaleDateString('pt-BR')
}

export function calcularIdade(dataNascimentoIso, hoje = new Date()) {
  if (!dataNascimentoIso) return null
  const nascimento = new Date(`${dataNascimentoIso}T00:00:00`)
  if (Number.isNaN(nascimento.getTime())) return null

  let idade = hoje.getFullYear() - nascimento.getFullYear()
  const aindaNaoFezAniversario =
    hoje.getMonth() < nascimento.getMonth() ||
    (hoje.getMonth() === nascimento.getMonth() && hoje.getDate() < nascimento.getDate())
  if (aindaNaoFezAniversario) idade -= 1

  return idade
}

// Substitui o array `dosesHoje` que antes vinha pronto do mock: monta a
// agenda do dia combinando os horários de cada medicamento ativo com o
// histórico de hoje (se já tiver um registro pra aquele horário, usa o
// status gravado; senão calcula ao vivo, igual sempre foi feito).
export function construirDosesHoje(medicamentosAtivos, historicoHoje, hojeIso = dataAtualISO()) {
  const doses = []
  for (const medicamento of medicamentosAtivos) {
    // Só entra se hoje é dia de dose: tratamento que ainda não começou não tem
    // dose (antes aparecia como "perdido"), e "Dias alternados"/"Semanal" só
    // têm dose a cada 2/7 dias (antes geravam dose todo dia).
    if (!temDoseNoDia(medicamento, hojeIso)) continue
    for (const horario of medicamento.horarios) {
      const registrado = historicoHoje.find(
        (item) => item.medicamentoId === medicamento.id && item.horario === horario,
      )
      const status = registrado ? registrado.status : calcularStatusAtual({ status: 'pendente', horario })
      doses.push({
        id: `${medicamento.id}-${horario}`,
        medicamentoId: medicamento.id,
        horario,
        nome: medicamento.nome,
        dosagem: medicamento.dosagem,
        forma: medicamento.forma,
        quantidadePorDose: medicamento.quantidadePorDose,
        dataFim: medicamento.fim,
        status,
      })
    }
  }
  return doses.sort((a, b) => a.horario.localeCompare(b.horario))
}

export const DIAS_JANELA_ADESAO = 30

// Adesão dos últimos 30 dias (hoje incluso) — é o período que as telas anunciam
// ("Adesão média (30 dias)"). Antes considerava o histórico inteiro.
export function calcularAdesao(historico, hojeIso = dataAtualISO()) {
  const inicioJanela = new Date(`${hojeIso}T00:00:00Z`)
  inicioJanela.setUTCDate(inicioJanela.getUTCDate() - (DIAS_JANELA_ADESAO - 1))
  const inicioIso = inicioJanela.toISOString().slice(0, 10)
  const recentes = historico.filter((item) => item.data >= inicioIso && item.data <= hojeIso)
  if (!recentes.length) return 100
  const tomados = recentes.filter((item) => item.status === 'tomado').length
  return Math.round((tomados / recentes.length) * 100)
}

const LIMIAR_DIAS_ESTOQUE_BAIXO = 5

// Unidades que ainda serão consumidas até o fim do tratamento: doses de hoje
// ainda não registradas + as dos dias seguintes (o back-end já desconta do
// estoque cada dose registrada como tomada). null em uso contínuo (sem fim).
function unidadesAteOFim(medicamento, historico, hojeIso, dosesPorDia, consumoPorDose) {
  if (!medicamento.fim || medicamento.fim < hojeIso) return null
  if (!medicamentoIniciado(medicamento, hojeIso)) {
    return contarDiasDeDose(medicamento, medicamento.inicio, medicamento.fim) * dosesPorDia * consumoPorDose
  }
  const tomadasHoje = historico.filter(
    (item) => item.medicamentoId === medicamento.id && item.data === hojeIso && item.status === 'tomado',
  ).length
  const dosesRestantesHoje = temDoseNoDia(medicamento, hojeIso) ? Math.max(0, dosesPorDia - tomadasHoje) : 0
  const diasSeguintes = contarDiasDeDose(medicamento, somarDias(hojeIso, 1), medicamento.fim)
  return (dosesRestantesHoje + diasSeguintes * dosesPorDia) * consumoPorDose
}

export function calcularEstoque(medicamento, historico = [], hojeIso = dataAtualISO()) {
  if (medicamento.forma === 'Pomada') return null
  if (medicamento.quantidadeEstoque === '' || medicamento.quantidadeEstoque == null) return null
  const temQuantidadePorDose = medicamento.quantidadePorDose !== '' && medicamento.quantidadePorDose != null
  const dosesPorDia = medicamento.horarios.length || 1
  const consumoPorDose = temQuantidadePorDose ? Number(medicamento.quantidadePorDose) : 1
  const quantidade = Number(medicamento.quantidadeEstoque)
  // Dias de calendário: em "Dias alternados"/"Semanal" cada dia de dose rende 2/7 dias.
  const diasRestantes = Math.floor(quantidade / (dosesPorDia * consumoPorDose)) * intervaloEntreDiasDeDose(medicamento)
  const necessarias = unidadesAteOFim(medicamento, historico, hojeIso, dosesPorDia, consumoPorDose)
  // Se o que tem cobre tudo o que falta tomar até a data final, não precisa comprar.
  const duraAteOFim = necessarias != null && quantidade > 0 && quantidade >= necessarias
  return {
    quantidade,
    unidade: UNIDADE_ESTOQUE_POR_FORMA[medicamento.forma] || 'unidades',
    diasRestantes,
    esgotado: quantidade <= 0 && necessarias !== 0,
    duraAteOFim,
    baixo: !duraAteOFim && diasRestantes <= LIMIAR_DIAS_ESTOQUE_BAIXO,
  }
}
