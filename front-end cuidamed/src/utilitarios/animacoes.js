// Variantes do framer-motion reaproveitadas nas listas com itens que entram/saem
// (cards de medicamento, pacientes, solicitações etc.), pra manter a mesma
// sensação de movimento suave em todo o sistema.
export const VARIANTES_ITEM_LISTA = {
  initial: { opacity: 0, y: 12, scale: 0.98 },
  animate: { opacity: 1, y: 0, scale: 1 },
  exit: { opacity: 0, scale: 0.96, transition: { duration: 0.15 } },
}

export const TRANSICAO_ITEM_LISTA = { duration: 0.22, ease: 'easeOut' }
