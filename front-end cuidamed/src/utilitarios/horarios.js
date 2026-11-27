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

export function medicamentoEncerrado(medicamento, hojeIso = dataAtualISO(), historico = []) {
  if (!medicamento.fim) return false
  if (medicamento.fim < hojeIso) return true
  if (medicamento.fim > hojeIso) return false
  if (!temDoseNoDia(medicamento, hojeIso)) return true
  return medicamento.horarios.every((horario) =>
    historico.some((item) => item.medicamentoId === medicamento.id && item.data === hojeIso && item.horario === horario),
  )
}

export function medicamentoIniciado(medicamento, hojeIso = dataAtualISO()) {
  return !medicamento.inicio || medicamento.inicio <= hojeIso
}

function diasEntre(deIso, ateIso) {
  return Math.round((new Date(`${ateIso}T00:00:00Z`) - new Date(`${deIso}T00:00:00Z`)) / 86400000)
}

export function somarDias(dataIso, dias) {
  const data = new Date(`${dataIso}T00:00:00Z`)
  data.setUTCDate(data.getUTCDate() + dias)
  return data.toISOString().slice(0, 10)
}

const INTERVALO_DIAS_POR_FREQUENCIA = { 'Dias alternados': 2, Semanal: 7, DIAS_ALTERNADOS: 2, SEMANAL: 7 }

export function intervaloEntreDiasDeDose(medicamento) {
  return INTERVALO_DIAS_POR_FREQUENCIA[medicamento.frequencia] || 1
}

export function temDoseNoDia(medicamento, diaIso = dataAtualISO()) {
  if (medicamento.inicio && diaIso < medicamento.inicio) return false
  if (medicamento.fim && diaIso > medicamento.fim) return false
  const intervalo = intervaloEntreDiasDeDose(medicamento)
  if (intervalo === 1 || !medicamento.inicio) return true
  return diasEntre(medicamento.inicio, diaIso) % intervalo === 0
}

export function proximoDiaDeDose(medicamento, aPartirIso = dataAtualISO()) {
  let dia = medicamento.inicio && medicamento.inicio > aPartirIso ? medicamento.inicio : aPartirIso
  for (let i = 0; i < 8; i += 1) {
    if (medicamento.fim && dia > medicamento.fim) return null
    if (temDoseNoDia(medicamento, dia)) return dia
    dia = somarDias(dia, 1)
  }
  return null
}

function contarDiasDeDose(medicamento, deIso, ateIso) {
  if (ateIso < deIso) return 0
  const intervalo = intervaloEntreDiasDeDose(medicamento)
  const total = diasEntre(deIso, ateIso) + 1
  if (intervalo === 1 || !medicamento.inicio) return total
  const primeiro = proximoDiaDeDose(medicamento, deIso)
  if (!primeiro || primeiro > ateIso) return 0
  return Math.floor(diasEntre(primeiro, ateIso) / intervalo) + 1
}

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

export function construirDosesHoje(medicamentosAtivos, historicoHoje, hojeIso = dataAtualISO()) {
  const doses = []
  for (const medicamento of medicamentosAtivos) {
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

export function dosesSemRegistro(medicamentos, historico, deIso, ateIso, agora = new Date()) {
  const hojeIso = dataAtualISO(agora)
  const fim = ateIso > hojeIso ? hojeIso : ateIso
  const inicios = medicamentos.map((medicamento) => medicamento.inicio).filter(Boolean).sort()
  let dia = inicios.length && inicios[0] > deIso ? inicios[0] : deIso
  const registrados = new Set(historico.map((item) => `${item.medicamentoId}|${item.data}|${item.horario}`))
  const agoraEmMinutos = minutosAgora(agora)
  const doses = []
  for (; dia <= fim; dia = somarDias(dia, 1)) {
    for (const medicamento of medicamentos) {
      if (!temDoseNoDia(medicamento, dia)) continue
      for (const horario of medicamento.horarios) {
        if (registrados.has(`${medicamento.id}|${dia}|${horario}`)) continue
        const status = dia < hojeIso ? 'perdido' : calcularStatusAtual({ status: 'pendente', horario }, agoraEmMinutos)
        if (status === 'pendente') continue
        doses.push({
          medicamentoId: medicamento.id,
          data: dia,
          horario,
          medicamento: medicamento.nome,
          dosagem: medicamento.dosagem,
          status,
          semRegistro: true,
        })
      }
    }
  }
  return doses
}

export const DIAS_JANELA_ADESAO = 30

export const DIAS_JANELA_HISTORICO = DIAS_JANELA_ADESAO + 1

export function inicioJanelaHistorico(hojeIso = dataAtualISO()) {
  return somarDias(hojeIso, -DIAS_JANELA_HISTORICO)
}

export function calcularAdesao(historico, medicamentos = [], hojeIso = dataAtualISO()) {
  const inicioJanela = new Date(`${hojeIso}T00:00:00Z`)
  inicioJanela.setUTCDate(inicioJanela.getUTCDate() - (DIAS_JANELA_ADESAO - 1))
  const inicioIso = inicioJanela.toISOString().slice(0, 10)
  const perdidasSemRegistro = dosesSemRegistro(medicamentos, historico, inicioIso, hojeIso).filter(
    (dose) => dose.status === 'perdido',
  )
  const recentes = [...historico.filter((item) => item.data >= inicioIso && item.data <= hojeIso), ...perdidasSemRegistro]
  if (!recentes.length) return 100
  const tomados = recentes.filter((item) => item.status === 'tomado').length
  return Math.round((tomados / recentes.length) * 100)
}

const LIMIAR_DIAS_ESTOQUE_BAIXO = 5

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
  const diasRestantes = Math.floor(quantidade / (dosesPorDia * consumoPorDose)) * intervaloEntreDiasDeDose(medicamento)
  const necessarias = unidadesAteOFim(medicamento, historico, hojeIso, dosesPorDia, consumoPorDose)
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

export function avisosEstoque(medicamentosAtivos, historico = [], hojeIso = dataAtualISO()) {
  const avisos = []
  for (const medicamento of medicamentosAtivos) {
    const estoque = calcularEstoque(medicamento, historico, hojeIso)
    if (!estoque) continue
    if (estoque.esgotado) {
      avisos.push({ id: medicamento.id, nome: medicamento.nome, esgotado: true, texto: 'Estoque esgotado. Reponha o quanto antes.' })
    } else if (estoque.baixo) {
      const duracao = estoque.diasRestantes <= 0 ? 'não dá para o dia todo' : `dura ${estoque.diasRestantes} dia${estoque.diasRestantes === 1 ? '' : 's'}`
      avisos.push({ id: medicamento.id, nome: medicamento.nome, esgotado: false, texto: `Restam ${estoque.quantidade} ${estoque.unidade} (${duracao}).` })
    }
  }
  return avisos
}
