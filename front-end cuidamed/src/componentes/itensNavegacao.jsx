export const ICONES_NAVEGACAO = {
  inicio: (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 11 12 4l8 7" />
      <path d="M6.5 11v8h11v-8" />
    </svg>
  ),
  agenda: (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3.5" y="5" width="17" height="15.5" rx="3" />
      <path d="M8 3v4M16 3v4M3.5 10h17" />
    </svg>
  ),
  encerrados: (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3.5" y="4.5" width="17" height="5" rx="1.5" />
      <path d="M4.5 9.5v7.5a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2V9.5" />
      <path d="M10 13.5h4" />
    </svg>
  ),
  historico: (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="8.5" />
      <path d="M12 7.5V12l3.2 2" />
    </svg>
  ),
  perfil: (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="8" r="3.6" />
      <path d="M5 20c0-3.6 3.1-5.6 7-5.6s7 2 7 5.6" />
    </svg>
  ),
  acessibilidade: (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="4.8" r="1.8" />
      <path d="M5 8.5c2.3.7 4.6 1 7 1s4.7-.3 7-1" />
      <path d="M12 9.5v4.5M12 14l-3 6M12 14l3 6" />
    </svg>
  ),
  farmacias: (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3.5 4 7.5v9L12 20.5l8-4v-9L12 3.5Z" />
      <path d="M12 8v8M8.5 10v6M15.5 10v6" />
    </svg>
  ),
}

export const ITENS_NAVEGACAO = [
  { rota: '/painel', rotulo: 'Início', icone: 'inicio' },
  { rota: '/agenda', rotulo: 'Agenda', icone: 'agenda' },
  { rota: '/ciclos-encerrados', rotulo: 'Ciclos encerrados', icone: 'encerrados' },
  { rota: '/historico', rotulo: 'Histórico', icone: 'historico' },
  { rota: '/farmacias', rotulo: 'Farmácias', icone: 'farmacias' },
  { rota: '/perfil', rotulo: 'Perfil', icone: 'perfil' },
]
