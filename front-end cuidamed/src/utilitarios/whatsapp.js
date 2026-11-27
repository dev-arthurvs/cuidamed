import { UNIDADE_ESTOQUE_POR_FORMA } from '../dados/dadosMock'
import { calcularDiasRestantesCiclo } from './horarios'

export function formatarTelefoneWhatsApp(telefone) {
  const digitos = (telefone || '').replace(/\D/g, '')
  if (!digitos) return ''
  if (digitos.startsWith('55') && digitos.length >= 12) return digitos
  return `55${digitos}`
}

export function formatarQuantidadePorDose({ forma, quantidadePorDose, dosagem }) {
  const temQuantidade = quantidadePorDose !== '' && quantidadePorDose != null
  if (!temQuantidade) return dosagem || ''
  const unidade = UNIDADE_ESTOQUE_POR_FORMA[forma] || 'unidades'
  return `${quantidadePorDose} ${unidade}`
}

export function montarMensagemLembrete({ nomePaciente, medicamento, horario, forma, quantidadePorDose, dosagem, dataFim }) {
  const primeiroNome = (nomePaciente || '').trim().split(' ')[0] || nomePaciente
  const quantidadeTexto = formatarQuantidadePorDose({ forma, quantidadePorDose, dosagem })
  const diasRestantes = calcularDiasRestantesCiclo(dataFim)

  const linhas = [
    'CUIDAMED💊💙',
    `Olá ${primeiroNome}! Está na hora do seu remédio das ${horario}.`,
    `Medicamento: ${medicamento}`,
  ]
  if (quantidadeTexto) linhas.push(`Quantidade: ${quantidadeTexto}`)
  if (diasRestantes != null) {
    linhas.push(
      diasRestantes <= 0
        ? 'Hoje é o último dia do ciclo deste medicamento.'
        : diasRestantes === 1
          ? 'Falta 1 dia para acabar o ciclo deste medicamento.'
          : `Faltam ${diasRestantes} dias para acabar o ciclo deste medicamento.`,
    )
  }
  linhas.push('')
  linhas.push('Lembre-se, cuidar da saúde é muito importante!')
  return linhas.join('\n')
}

export function montarLinkWhatsApp({ telefone, nomePaciente, medicamento, horario, forma, quantidadePorDose, dosagem, dataFim }) {
  const numero = formatarTelefoneWhatsApp(telefone)
  if (!numero) return null
  const mensagem = montarMensagemLembrete({ nomePaciente, medicamento, horario, forma, quantidadePorDose, dosagem, dataFim })
  return `https://api.whatsapp.com/send/?phone=${numero}&text=${encodeURIComponent(mensagem)}&type=phone_number&app_absent=0`
}
