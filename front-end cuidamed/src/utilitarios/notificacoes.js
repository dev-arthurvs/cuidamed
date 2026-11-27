export function notificacaoDisponivel() {
  return typeof window !== 'undefined' && 'Notification' in window
}

export function statusPermissaoNotificacao() {
  return notificacaoDisponivel() ? Notification.permission : 'unsupported'
}

export async function pedirPermissaoNotificacao() {
  if (!notificacaoDisponivel()) return 'unsupported'
  try {
    return await Notification.requestPermission()
  } catch {
    return 'denied'
  }
}

export function notificarDose(titulo, corpo) {
  if (!notificacaoDisponivel() || Notification.permission !== 'granted') return
  try {
    new Notification(titulo, { body: corpo, tag: titulo })
  } catch {
    // navegador recusou a notificação
  }
}
