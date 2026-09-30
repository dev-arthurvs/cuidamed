// Notificações do dispositivo via Web Notifications API. Funciona enquanto o
// app estiver aberto em alguma aba (mesmo em segundo plano) — não funciona
// com o navegador totalmente fechado (isso exigiria Web Push + Service Worker).

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
    // Alguns navegadores mobile não suportam o construtor direto — ignora.
  }
}
