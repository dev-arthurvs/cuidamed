import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { api } from '../utilitarios/api'
import { definirAoExpirarSessao, lerSessao, limparSessao, salvarSessao } from '../utilitarios/sessao'
import { tocarAlertaSonoro } from '../utilitarios/alertaSonoro'
import {
  calcularIdade,
  calcularStatusAtual,
  construirDosesHoje,
  dataAtualISO,
  medicamentoEncerrado,
  minutosAgora,
  obterIniciais,
  paraMinutos,
} from '../utilitarios/horarios'
import { notificarDose } from '../utilitarios/notificacoes'
import { ZOOM_POR_TAMANHO, obterTamanhoFonteSalvo, salvarTamanhoFonte } from '../utilitarios/preferenciaFonte'
import {
  FORMA_DA_API,
  FORMA_PARA_API,
  FREQUENCIA_DA_API,
  FREQUENCIA_PARA_API,
  SEXO_DA_API,
  SEXO_PARA_API,
  STATUS_HISTORICO_DA_API,
} from '../utilitarios/mapeamentoApi'
import { ContextoAppContexto } from './contexto'

const INTERVALO_VERIFICACAO_MS = 30000

function mapearPacienteDaApi(paciente) {
  return {
    id: paciente.id,
    nome: paciente.nome,
    email: paciente.email || '',
    dataNascimento: paciente.dataNascimento || '',
    sexo: paciente.sexo ? SEXO_DA_API[paciente.sexo] : '',
    enfermidade: paciente.enfermidade || '',
    telefone: paciente.telefone || '',
    endereco: paciente.endereco || '',
    observacoesClinicas: paciente.observacoesClinicas || '',
    cuidadorId: paciente.cuidadorId,
    cuidadorSolicitadoId: paciente.cuidadorSolicitadoId,
    alertaManualPendente: paciente.alertaManualPendente,
    alertaManualMensagem: paciente.alertaManualMensagem,
    permiteAlteracoes: paciente.permiteAlteracoes,
    codigoAtivacao: paciente.codigoAtivacao || '',
    iniciais: obterIniciais(paciente.nome),
  }
}

function mapearMedicamentoDaApi(medicamento) {
  return {
    id: medicamento.id,
    nome: medicamento.nome,
    dosagem: medicamento.dosagem,
    forma: FORMA_DA_API[medicamento.forma] || medicamento.forma,
    frequencia: FREQUENCIA_DA_API[medicamento.frequencia] || medicamento.frequencia,
    horarios: medicamento.horarios,
    inicio: medicamento.dataInicio,
    fim: medicamento.dataFim || '',
    observacoes: medicamento.observacoes || '',
    quantidadeEstoque: medicamento.quantidadeEstoque ?? '',
    quantidadePorDose: medicamento.quantidadePorDose ?? '',
  }
}

function mapearHistoricoDaApi(historico) {
  return {
    medicamentoId: historico.medicamentoId,
    data: historico.data,
    horario: historico.hora,
    medicamento: historico.nomeMedicamento,
    dosagem: historico.dosagem,
    status: STATUS_HISTORICO_DA_API[historico.status] || historico.status,
  }
}

async function hidratarPaciente(pacienteBase) {
  const [medicamentosApi, historicoApi] = await Promise.all([
    api.get(`/api/pacientes/${pacienteBase.id}/medicamentos`),
    api.get(`/api/pacientes/${pacienteBase.id}/historicos`),
  ])
  return {
    ...mapearPacienteDaApi(pacienteBase),
    medicamentos: medicamentosApi.map(mapearMedicamentoDaApi),
    historico: historicoApi.map(mapearHistoricoDaApi),
  }
}

export function ProvedorApp({ children }) {
  const [pacientes, setPacientes] = useState([])
  const [usuario, setUsuario] = useState(null)
  // Com uma sessão salva no navegador, os dados são recarregados ao abrir a
  // página; até lá as rotas esperam, em vez de mandar para o login.
  const [carregandoSessao, setCarregandoSessao] = useState(() => lerSessao() !== null)
  const [pacienteFocoId, setPacienteFocoId] = useState(null)
  const [toast, setToast] = useState('')
  const [tick, setTick] = useState(0)
  const [tamanhoFonte, setTamanhoFonte] = useState(obterTamanhoFonteSalvo)
  const timeoutToast = useRef(null)
  const avisados = useRef(new Set())

  const autenticado = usuario !== null

  const mostrarToast = useCallback((mensagem) => {
    clearTimeout(timeoutToast.current)
    setToast(mensagem)
    timeoutToast.current = setTimeout(() => setToast(''), 2600)
  }, [])

  useEffect(() => {
    const fator = ZOOM_POR_TAMANHO[tamanhoFonte]
    document.documentElement.style.zoom = fator
    // O zoom escala a renderização, mas não o valor de "100vh" — sem essa
    // variável, layouts de tela cheia (login, modais) estouram a viewport
    // visível e ficam com um vão vazio embaixo. Ver autenticacao.css.
    document.documentElement.style.setProperty('--fator-zoom', fator)
  }, [tamanhoFonte])

  const definirTamanhoFonte = useCallback((tamanho) => {
    if (!ZOOM_POR_TAMANHO[tamanho]) return
    setTamanhoFonte(tamanho)
    salvarTamanhoFonte(tamanho)
  }, [])

  useEffect(() => () => clearTimeout(timeoutToast.current), [])

  // Alerta de horário: verifica periodicamente se alguma dose do idoso logado
  // chegou ao horário agendado e ainda não foi confirmada.
  useEffect(() => {
    const intervalo = setInterval(() => setTick((valor) => valor + 1), INTERVALO_VERIFICACAO_MS)
    return () => clearInterval(intervalo)
  }, [])

  const pacientesComStatusAtual = useMemo(() => {
    const hoje = dataAtualISO()
    return pacientes.map((paciente) => {
      const medicamentosAtivos = paciente.medicamentos.filter(
        (medicamento) => !medicamentoEncerrado(medicamento, hoje, paciente.historico),
      )
      const historicoHoje = paciente.historico.filter((item) => item.data === hoje)
      return {
        ...paciente,
        idade: calcularIdade(paciente.dataNascimento),
        medicamentosAtivos,
        dosesHoje: construirDosesHoje(medicamentosAtivos, historicoHoje),
      }
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pacientes, tick])

  const pacienteFoco = useMemo(
    () => pacientesComStatusAtual.find((paciente) => paciente.id === pacienteFocoId) || null,
    [pacientesComStatusAtual, pacienteFocoId],
  )

  useEffect(() => {
    if (!usuario || usuario.tipo !== 'paciente' || !pacienteFoco) return
    const agora = minutosAgora()
    pacienteFoco.dosesHoje.forEach((dose) => {
      if (dose.status === 'tomado' || avisados.current.has(dose.id)) return
      const diferenca = agora - paraMinutos(dose.horario)
      if (diferenca >= 0 && diferenca < 1) {
        avisados.current.add(dose.id)
        const mensagem = `Está na hora de tomar ${dose.nome} (${dose.dosagem}).`
        mostrarToast(mensagem)
        tocarAlertaSonoro()
        notificarDose('Hora do remédio 💊', mensagem)
      }
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tick, usuario, pacienteFoco])

  // Alerta manual: verifica periodicamente se o cuidador pediu pra lembrar o
  // paciente agora, mesmo fora do horário programado de alguma dose.
  useEffect(() => {
    if (!usuario || usuario.tipo !== 'paciente') return
    let cancelado = false

    async function verificarAlertaManual() {
      try {
        const paciente = await api.get(`/api/pacientes/${usuario.id}`)
        if (cancelado || !paciente.alertaManualPendente) return
        const mensagem = paciente.alertaManualMensagem || 'Seu cuidador pediu para lembrá-lo de tomar sua medicação.'
        mostrarToast(mensagem)
        tocarAlertaSonoro()
        notificarDose('Lembrete do seu cuidador 💊', mensagem)
        await api.post(`/api/pacientes/${usuario.id}/alerta-manual/confirmar`)
      } catch {
        // falha de rede num polling não deve interromper a experiência do usuário
      }
    }

    verificarAlertaManual()
    const intervalo = setInterval(verificarAlertaManual, INTERVALO_VERIFICACAO_MS)
    return () => {
      cancelado = true
      clearInterval(intervalo)
    }
  }, [usuario, mostrarToast])

  // Sincronização entre web e mobile: a cada 30 s busca de novo no servidor os
  // dados de quem está logado (o paciente, ou todos os pacientes do cuidador),
  // pra refletir o que foi alterado no outro app sem precisar recarregar a
  // página. Pausa com a aba em segundo plano e sincroniza na hora ao voltar.
  useEffect(() => {
    if (!usuario) return undefined
    let cancelado = false
    let emAndamento = false

    async function sincronizar() {
      if (emAndamento || document.hidden) return
      emAndamento = true
      try {
        if (usuario.tipo === 'paciente') {
          const hidratado = await hidratarPaciente(await api.get(`/api/pacientes/${usuario.id}`))
          if (!cancelado) setPacientes((atual) => atual.map((p) => (p.id === usuario.id ? hidratado : p)))
        } else {
          const base = await api.get(`/api/cuidadores/${usuario.id}/pacientes`)
          const hidratados = await Promise.all(base.map(hidratarPaciente))
          if (!cancelado) setPacientes(hidratados)
        }
      } catch {
        // falha de rede numa sincronização não interrompe o uso — tenta de novo na próxima
      } finally {
        emAndamento = false
      }
    }

    function aoVoltarParaAba() {
      if (!document.hidden) sincronizar()
    }

    const intervalo = setInterval(sincronizar, INTERVALO_VERIFICACAO_MS)
    document.addEventListener('visibilitychange', aoVoltarParaAba)
    return () => {
      cancelado = true
      clearInterval(intervalo)
      document.removeEventListener('visibilitychange', aoVoltarParaAba)
    }
  }, [usuario])

  // Busca os dados de quem entrou (o paciente, ou o cuidador e os pacientes dele).
  const carregarUsuario = useCallback(async (tipo, id) => {
    if (tipo === 'PACIENTE') {
      const pacienteBase = await api.get(`/api/pacientes/${id}`)
      const hidratado = await hidratarPaciente(pacienteBase)
      setPacientes([hidratado])
      setPacienteFocoId(hidratado.id)
      setUsuario({ id: hidratado.id, nome: hidratado.nome, email: hidratado.email, tipo: 'paciente' })
    } else {
      const cuidador = await api.get(`/api/cuidadores/${id}`)
      const base = await api.get(`/api/cuidadores/${id}/pacientes`)
      const hidratados = await Promise.all(base.map(hidratarPaciente))
      setPacientes(hidratados)
      setPacienteFocoId(null)
      setUsuario({
        id: cuidador.id,
        nome: cuidador.nome,
        email: cuidador.email,
        tipo: 'cuidador',
        profissao: cuidador.profissao,
        telefone: cuidador.telefone,
      })
    }
  }, [])

  const entrar = useCallback(
    async (email, senha) => {
      const login = await api.post('/api/auth/login', { email, senha })
      salvarSessao({ token: login.token, tipo: login.tipo, id: login.id })
      try {
        await carregarUsuario(login.tipo, login.id)
      } catch (erro) {
        limparSessao()
        throw erro
      }
    },
    [carregarUsuario],
  )

  const sair = useCallback(() => {
    limparSessao()
    setUsuario(null)
    setPacienteFocoId(null)
    setPacientes([])
  }, [])

  // Sessão salva de uma visita anterior: recarrega os dados sem pedir login.
  useEffect(() => {
    const sessao = lerSessao()
    if (!sessao) return

    async function restaurarSessao() {
      try {
        await carregarUsuario(sessao.tipo, sessao.id)
      } catch {
        limparSessao()
      } finally {
        setCarregandoSessao(false)
      }
    }

    restaurarSessao()
  }, [carregarUsuario])

  // Token recusado pelo servidor (expirou ou ficou inválido): sai da conta e avisa.
  useEffect(() => {
    definirAoExpirarSessao(() => {
      sair()
      mostrarToast('Sua sessão expirou. Entre novamente.')
    })
    return () => definirAoExpirarSessao(null)
  }, [sair, mostrarToast])

  // Depois de criar a conta, entra com o mesmo e-mail e senha (é o login que gera o token).
  const cadastrar = useCallback(async ({ nome, email, senha, tipo, dataNascimento, sexo, telefone, endereco, profissao }) => {
    if (tipo === 'paciente') {
      await api.post('/api/pacientes', {
        nome,
        email,
        senha,
        dataNascimento: dataNascimento || null,
        sexo: sexo ? SEXO_PARA_API[sexo] : null,
        telefone: telefone || null,
        endereco: endereco || null,
      })
    } else {
      await api.post('/api/cuidadores', {
        nome,
        email,
        senha,
        profissao: profissao || null,
        telefone: telefone || null,
      })
    }
    await entrar(email, senha)
  }, [entrar])

  const selecionarPaciente = useCallback((id) => setPacienteFocoId(id), [])

  const recarregarPaciente = useCallback(async (pacienteId) => {
    const pacienteBase = await api.get(`/api/pacientes/${pacienteId}`)
    const hidratado = await hidratarPaciente(pacienteBase)
    setPacientes((atual) => atual.map((paciente) => (paciente.id === pacienteId ? hidratado : paciente)))
    return hidratado
  }, [])

  const cadastrarPaciente = useCallback(
    async (dados) => {
      await api.post('/api/pacientes', {
        nome: dados.nome,
        email: dados.email || null,
        senha: null,
        dataNascimento: dados.dataNascimento || null,
        sexo: dados.sexo ? SEXO_PARA_API[dados.sexo] : null,
        enfermidade: dados.enfermidade || null,
        telefone: dados.telefone || null,
        endereco: dados.endereco || null,
        cuidadorId: usuario?.id,
      })
      const base = await api.get(`/api/cuidadores/${usuario.id}/pacientes`)
      const hidratados = await Promise.all(base.map(hidratarPaciente))
      setPacientes(hidratados)
    },
    [usuario],
  )

  const adicionarMedicamento = useCallback(
    async (pacienteId, dados) => {
      await api.post('/api/medicamentos', {
        pacienteId,
        nome: dados.nome,
        dosagem: dados.dosagem,
        forma: FORMA_PARA_API[dados.forma],
        frequencia: FREQUENCIA_PARA_API[dados.frequencia],
        dataInicio: dados.inicio,
        dataFim: dados.fim || null,
        observacoes: dados.observacoes || null,
        quantidadeEstoque: dados.quantidadeEstoque !== '' && dados.quantidadeEstoque != null ? Number(dados.quantidadeEstoque) : null,
        quantidadePorDose: dados.quantidadePorDose !== '' && dados.quantidadePorDose != null ? Number(dados.quantidadePorDose) : null,
        horarios: dados.horarios,
      })
      await recarregarPaciente(pacienteId)
    },
    [recarregarPaciente],
  )

  const editarMedicamento = useCallback(
    async (pacienteId, medicamentoId, dados) => {
      await api.put(`/api/medicamentos/${medicamentoId}`, {
        nome: dados.nome,
        dosagem: dados.dosagem,
        forma: FORMA_PARA_API[dados.forma],
        frequencia: FREQUENCIA_PARA_API[dados.frequencia],
        dataInicio: dados.inicio,
        dataFim: dados.fim || null,
        observacoes: dados.observacoes || null,
        quantidadeEstoque: dados.quantidadeEstoque !== '' && dados.quantidadeEstoque != null ? Number(dados.quantidadeEstoque) : null,
        quantidadePorDose: dados.quantidadePorDose !== '' && dados.quantidadePorDose != null ? Number(dados.quantidadePorDose) : null,
        horarios: dados.horarios,
      })
      await recarregarPaciente(pacienteId)
    },
    [recarregarPaciente],
  )

  const excluirMedicamento = useCallback(
    async (pacienteId, medicamentoId) => {
      await api.delete(`/api/medicamentos/${medicamentoId}`)
      await recarregarPaciente(pacienteId)
    },
    [recarregarPaciente],
  )

  const marcarDoseComoTomada = useCallback(
    async (pacienteId, doseId) => {
      const paciente = pacientesComStatusAtual.find((item) => item.id === pacienteId)
      const dose = paciente?.dosesHoje.find((item) => item.id === doseId)
      if (!dose) return
      try {
        const statusFinal = calcularStatusAtual(dose) === 'perdido' ? 'PERDIDO' : 'TOMADO'
        await api.post('/api/historicos', {
          pacienteId,
          medicamentoId: dose.medicamentoId,
          data: dataAtualISO(),
          hora: dose.horario,
          status: statusFinal,
        })
        await recarregarPaciente(pacienteId)
      } catch (erro) {
        mostrarToast(erro.message)
      }
    },
    [pacientesComStatusAtual, recarregarPaciente, mostrarToast],
  )

  const atualizarPerfil = useCallback(
    async (dados) => {
      if (usuario.tipo === 'paciente') {
        const atualizado = await api.put(`/api/pacientes/${usuario.id}`, {
          nome: dados.nome,
          email: dados.email,
          dataNascimento: dados.dataNascimento || null,
          sexo: dados.sexo ? SEXO_PARA_API[dados.sexo] : null,
          enfermidade: pacienteFoco?.enfermidade || null,
          telefone: dados.telefone || null,
          endereco: dados.endereco || null,
          observacoesClinicas: pacienteFoco?.observacoesClinicas || null,
          cuidadorId: pacienteFoco?.cuidadorId || null,
        })
        setUsuario((atual) => ({ ...atual, nome: atualizado.nome, email: atualizado.email }))
        setPacientes((atual) =>
          atual.map((paciente) =>
            paciente.id === usuario.id ? { ...paciente, ...mapearPacienteDaApi(atualizado) } : paciente,
          ),
        )
      } else {
        const atualizado = await api.put(`/api/cuidadores/${usuario.id}`, {
          nome: dados.nome,
          email: dados.email,
          profissao: dados.profissao || null,
          telefone: dados.telefone || null,
        })
        setUsuario((atual) => ({
          ...atual,
          nome: atualizado.nome,
          email: atualizado.email,
          profissao: atualizado.profissao,
          telefone: atualizado.telefone,
        }))
      }
    },
    [usuario, pacienteFoco],
  )

  const alterarSenha = useCallback(
    async ({ senhaAtual, novaSenha }) => {
      const caminho = usuario.tipo === 'paciente' ? `/api/pacientes/${usuario.id}/senha` : `/api/cuidadores/${usuario.id}/senha`
      await api.put(caminho, { senhaAtual, novaSenha })
    },
    [usuario],
  )

  const solicitarVinculoCuidador = useCallback(
    async (cuidadorEmail) => {
      await api.post(`/api/pacientes/${usuario.id}/solicitar-vinculo`, { cuidadorEmail })
      await recarregarPaciente(usuario.id)
    },
    [usuario, recarregarPaciente],
  )

  const aceitarVinculoCuidador = useCallback(
    async (pacienteId, cuidadorId) => {
      await api.post(`/api/pacientes/${pacienteId}/aceitar-vinculo`, { cuidadorId })
      const base = await api.get(`/api/cuidadores/${cuidadorId}/pacientes`)
      const hidratados = await Promise.all(base.map(hidratarPaciente))
      setPacientes(hidratados)
    },
    [],
  )

  const recusarVinculoCuidador = useCallback(async (pacienteId, cuidadorId) => {
    await api.post(`/api/pacientes/${pacienteId}/recusar-vinculo`, { cuidadorId })
  }, [])

  const enviarAlertaManual = useCallback(
    async (pacienteId, mensagem) => {
      await api.post(`/api/pacientes/${pacienteId}/alerta-manual`, { cuidadorId: usuario.id, mensagem: mensagem || null })
    },
    [usuario],
  )

  const desvincularPaciente = useCallback(
    async (pacienteId) => {
      await api.post(`/api/pacientes/${pacienteId}/desvincular-cuidador`, { cuidadorId: usuario.id })
      setPacientes((atual) => atual.filter((paciente) => paciente.id !== pacienteId))
      setPacienteFocoId((atual) => (atual === pacienteId ? null : atual))
    },
    [usuario],
  )

  // Salva só as observações clínicas: busca o paciente atual no servidor e
  // reenvia todos os campos como estão (o PUT substitui tudo), trocando apenas
  // as observações — assim nada que foi alterado em outro lugar é apagado.
  const atualizarObservacoesClinicas = useCallback(
    async (pacienteId, texto) => {
      const atual = await api.get(`/api/pacientes/${pacienteId}`)
      await api.put(`/api/pacientes/${pacienteId}`, {
        nome: atual.nome,
        email: atual.email,
        dataNascimento: atual.dataNascimento,
        sexo: atual.sexo,
        enfermidade: atual.enfermidade,
        telefone: atual.telefone,
        endereco: atual.endereco,
        observacoesClinicas: texto.trim() || null,
        cuidadorId: atual.cuidadorId,
      })
      await recarregarPaciente(pacienteId)
    },
    [recarregarPaciente],
  )

  const atualizarPermissaoAlteracoes = useCallback(
    async (pacienteId, permiteAlteracoes) => {
      await api.put(`/api/pacientes/${pacienteId}/permissao-alteracoes`, { cuidadorId: usuario.id, permiteAlteracoes })
      await recarregarPaciente(pacienteId)
    },
    [usuario, recarregarPaciente],
  )

  const valor = useMemo(
    () => ({
      autenticado,
      carregandoSessao,
      usuario,
      pacientes: pacientesComStatusAtual,
      pacienteFoco,
      pacienteFocoId,
      toast,
      entrar,
      cadastrar,
      sair,
      selecionarPaciente,
      cadastrarPaciente,
      adicionarMedicamento,
      editarMedicamento,
      excluirMedicamento,
      marcarDoseComoTomada,
      atualizarPerfil,
      alterarSenha,
      solicitarVinculoCuidador,
      aceitarVinculoCuidador,
      recusarVinculoCuidador,
      enviarAlertaManual,
      desvincularPaciente,
      atualizarPermissaoAlteracoes,
      atualizarObservacoesClinicas,
      mostrarToast,
      tamanhoFonte,
      definirTamanhoFonte,
    }),
    [
      autenticado,
      carregandoSessao,
      usuario,
      pacientesComStatusAtual,
      pacienteFoco,
      pacienteFocoId,
      toast,
      entrar,
      cadastrar,
      sair,
      selecionarPaciente,
      cadastrarPaciente,
      adicionarMedicamento,
      editarMedicamento,
      excluirMedicamento,
      marcarDoseComoTomada,
      atualizarPerfil,
      alterarSenha,
      solicitarVinculoCuidador,
      aceitarVinculoCuidador,
      recusarVinculoCuidador,
      enviarAlertaManual,
      desvincularPaciente,
      atualizarPermissaoAlteracoes,
      atualizarObservacoesClinicas,
      mostrarToast,
      tamanhoFonte,
      definirTamanhoFonte,
    ],
  )

  return <ContextoAppContexto.Provider value={valor}>{children}</ContextoAppContexto.Provider>
}
