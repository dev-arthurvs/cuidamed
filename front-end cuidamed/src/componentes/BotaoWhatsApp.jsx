import { montarLinkWhatsApp } from '../utilitarios/whatsapp'
import './BotaoWhatsApp.css'

// Só faz sentido lembrar de uma dose que ainda pode ser tomada (ou que já foi
// perdida, como reforço pra próxima) — não de uma que já foi tomada.
const STATUS_VISIVEIS = new Set(['pendente', 'atrasado', 'perdido'])

export default function BotaoWhatsApp({ nomePaciente, telefone, medicamento, dosagem, forma, quantidadePorDose, dataFim, horario, status }) {
  if (!STATUS_VISIVEIS.has(status)) return null

  const link = montarLinkWhatsApp({ telefone, nomePaciente, medicamento, dosagem, forma, quantidadePorDose, dataFim, horario })
  const desabilitado = !link

  function abrirWhatsApp() {
    if (!link) return
    window.open(link, '_blank', 'noopener,noreferrer')
  }

  return (
    <button
      type="button"
      className="botao-whatsapp"
      onClick={abrirWhatsApp}
      disabled={desabilitado}
      aria-label={`Enviar lembrete por WhatsApp para ${nomePaciente}`}
      title={desabilitado ? 'Paciente sem telefone cadastrado' : 'Enviar lembrete por WhatsApp'}
    >
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92Z" />
      </svg>
    </button>
  )
}
