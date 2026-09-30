// Alerta sintetizado via Web Audio API — sem precisar de nenhum arquivo de
// áudio. Campainha "ding-dong" (duas notas em onda senoidal com decaimento
// tipo sino), repetida algumas vezes pra garantir que o paciente perceba.
const VOLUME = 0.8
const FREQ_DING_HZ = 1319 // E6
const FREQ_DONG_HZ = 988 // B5
const DURACAO_NOTA_S = 0.6
const INTERVALO_ENTRE_NOTAS_S = 0.45
const NUMERO_DE_REPETICOES = 3
const INTERVALO_ENTRE_REPETICOES_S = 1.6

function tocarNota(contexto, frequencia, inicioEm, duracao) {
  const oscilador = contexto.createOscillator()
  const ganho = contexto.createGain()
  oscilador.type = 'sine'
  oscilador.frequency.value = frequencia
  oscilador.connect(ganho)
  ganho.connect(contexto.destination)

  const agora = contexto.currentTime + inicioEm
  ganho.gain.setValueAtTime(0.0001, agora)
  ganho.gain.exponentialRampToValueAtTime(VOLUME, agora + 0.02)
  ganho.gain.exponentialRampToValueAtTime(0.0001, agora + duracao)

  oscilador.start(agora)
  oscilador.stop(agora + duracao + 0.05)
}

export function tocarAlertaSonoro() {
  try {
    const Contexto = window.AudioContext || window.webkitAudioContext
    if (!Contexto) return
    const contexto = new Contexto()

    if (contexto.state === 'suspended') {
      contexto.resume().catch(() => {})
    }

    for (let repeticao = 0; repeticao < NUMERO_DE_REPETICOES; repeticao += 1) {
      const inicioRepeticao = repeticao * INTERVALO_ENTRE_REPETICOES_S
      tocarNota(contexto, FREQ_DING_HZ, inicioRepeticao, DURACAO_NOTA_S)
      tocarNota(contexto, FREQ_DONG_HZ, inicioRepeticao + INTERVALO_ENTRE_NOTAS_S, DURACAO_NOTA_S)
    }
  } catch {
    // Navegador sem suporte a Web Audio — ignora silenciosamente.
  }
}
