// Monta o link do WhatsApp pro lembrete manual de dose que o cuidador dispara
// direto da lista "Doses de hoje". O número de quem ENVIA não é definido aqui —
// é a sessão do WhatsApp Web/app já logada no navegador/celular do cuidador;
// a gente só monta o número de DESTINO (o paciente) e o texto da mensagem.
import { UNIDADE_ESTOQUE_POR_FORMA } from '../dados/dadosMock'
import { calcularDiasRestantesCiclo } from './horarios'

export function formatarTelefoneWhatsApp(telefone) {
  const digitos = (telefone || '').replace(/\D/g, '')
  if (!digitos) return ''
  // Já vem com código do país (55) + DDD (2) + número (8 ou 9) = 12 ou 13 dígitos.
  if (digitos.startsWith('55') && digitos.length >= 12) return digitos
  return `55${digitos}`
}

// Pomada não tem quantidadePorDose (não tem unidade discreta, ver dadosMock.js)
// — nesse caso mostra a dosagem (concentração) como substituta.
export function formatarQuantidadePorDose({ forma, quantidadePorDose, dosagem }) {
  const temQuantidade = quantidadePorDose !== '' && quantidadePorDose != null
  if (!temQuantidade) return dosagem
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
    `Quantidade: ${quantidadeTexto}`,
  ]
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
  // Usa o endpoint direto da WhatsApp (api.whatsapp.com/send) em vez do encurtador
  // wa.me: o redirect do wa.me re-processa a query string e corrompe emojis/símbolos
  // (viram U+FFFD) antes de chegar no destino final — confirmado testando o
  // redirect isoladamente. O endpoint direto entrega o texto intacto.
  return `https://api.whatsapp.com/send/?phone=${numero}&text=${encodeURIComponent(mensagem)}&type=phone_number&app_absent=0`
}
