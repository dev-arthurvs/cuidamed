import { AnimatePresence, motion } from 'framer-motion'
import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useOutletContext, useParams } from 'react-router-dom'
import Botao from '../componentes/Botao'
import BotaoWhatsApp from '../componentes/BotaoWhatsApp'
import Cabecalho from '../componentes/Cabecalho'
import Cartao from '../componentes/Cartao'
import CartaoObservacoes from '../componentes/CartaoObservacoes'
import Rotulo from '../componentes/Rotulo'
import { useApp } from '../contexto/useApp'
import { api } from '../utilitarios/api'
import { TRANSICAO_ITEM_LISTA, VARIANTES_ITEM_LISTA } from '../utilitarios/animacoes'
import { calcularAdesao } from '../utilitarios/horarios'
import CadastroPaciente from './CadastroPaciente'
import './PainelCuidador.css'

function corAdesao(pct) {
  if (pct >= 85) return 'var(--verde)'
  if (pct >= 60) return 'var(--amarelo)'
  return 'var(--vermelho)'
}

export default function PainelCuidador() {
  const { usuario, pacientes, selecionarPaciente, aceitarVinculoCuidador, recusarVinculoCuidador, enviarAlertaManual, mostrarToast } =
    useApp()
  const [enviandoAlerta, setEnviandoAlerta] = useState(false)
  const { pacienteId } = useParams()
  const navegar = useNavigate()
  const { abrirMenu } = useOutletContext()
  const [cadastroAberto, setCadastroAberto] = useState(false)
  const [solicitacoes, setSolicitacoes] = useState([])

  const pacientesComResumo = useMemo(
    () =>
      pacientes.map((paciente) => {
        const pct = calcularAdesao(paciente.historico)
        const precisaAtencao = paciente.dosesHoje.some((dose) => dose.status === 'atrasado' || dose.status === 'perdido')
        return { ...paciente, pct, precisaAtencao }
      }),
    [pacientes],
  )

  function carregarSolicitacoes() {
    api
      .get(`/api/cuidadores/${usuario.id}/solicitacoes`)
      .then(setSolicitacoes)
      .catch(() => setSolicitacoes([]))
  }

  useEffect(() => {
    carregarSolicitacoes()
    // Pedidos de vínculo feitos no app do paciente aparecem sozinhos (a cada 30 s).
    const intervalo = setInterval(() => {
      if (!document.hidden) carregarSolicitacoes()
    }, 30000)
    return () => clearInterval(intervalo)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [usuario.id])

  async function aceitar(paciente) {
    try {
      await aceitarVinculoCuidador(paciente.id, usuario.id)
      mostrarToast(`${paciente.nome} agora está vinculado(a) a você.`)
      carregarSolicitacoes()
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível aceitar o vínculo.')
    }
  }

  async function recusar(paciente) {
    try {
      await recusarVinculoCuidador(paciente.id, usuario.id)
      mostrarToast('Solicitação recusada.')
      carregarSolicitacoes()
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível recusar o vínculo.')
    }
  }

  if (pacienteId) {
    const paciente = pacientesComResumo.find((item) => String(item.id) === pacienteId)
    if (!paciente) return null

    function irParaAgenda() {
      selecionarPaciente(paciente.id)
      navegar('/agenda')
    }

    function irParaCiclosEncerrados() {
      selecionarPaciente(paciente.id)
      navegar('/ciclos-encerrados')
    }

    async function lembrarAgora() {
      setEnviandoAlerta(true)
      try {
        await enviarAlertaManual(paciente.id)
        mostrarToast(`Lembrete enviado para ${paciente.nome}.`)
      } catch (erro) {
        mostrarToast(erro.message || 'Não foi possível enviar o lembrete.')
      } finally {
        setEnviandoAlerta(false)
      }
    }

    return (
      <>
        <Cabecalho kicker="Detalhes do paciente" titulo={paciente.nome} aoAbrirMenu={abrirMenu} />
        <div className="pagina-corpo">
          <div className="pagina-corpo__miolo painel-cuidador-detalhe">
            <Botao variante="texto" onClick={() => navegar('/painel')}>
              ‹ Todos os pacientes
            </Botao>

            <div className="painel-cuidador-detalhe__grade">
              <Cartao>
                <div className="painel-cuidador-detalhe__cabecalho">
                  <div className="painel-cuidador__avatar painel-cuidador__avatar--grande">{paciente.iniciais}</div>
                  <div className="painel-cuidador-detalhe__info">
                    <div className="painel-cuidador-detalhe__nome">{paciente.nome}</div>
                    <div className="painel-cuidador-detalhe__sub">
                      {paciente.idade ? `${paciente.idade} anos · ` : ''}
                      {paciente.medicamentosAtivos.length} medicamentos
                    </div>
                  </div>
                  <div className="painel-cuidador-detalhe__pct">
                    <div className="painel-cuidador-detalhe__pct-numero">{paciente.pct}%</div>
                    <div className="painel-cuidador-detalhe__pct-rotulo">adesão 30 dias</div>
                  </div>
                </div>

                <h3 className="painel-cuidador-detalhe__subtitulo">Doses de hoje</h3>
                <div className="painel-idoso__lista-doses">
                  {paciente.dosesHoje.map((dose) => (
                    <div className="painel-idoso__dose" key={dose.id}>
                      <div className="painel-idoso__dose-hora">{dose.horario}</div>
                      <div className="painel-idoso__dose-info">
                        <div className="painel-idoso__dose-nome">{dose.nome}</div>
                      </div>
                      <Rotulo status={dose.status} />
                      <BotaoWhatsApp
                        nomePaciente={paciente.nome}
                        telefone={paciente.telefone}
                        medicamento={dose.nome}
                        dosagem={dose.dosagem}
                        forma={dose.forma}
                        quantidadePorDose={dose.quantidadePorDose}
                        dataFim={dose.dataFim}
                        horario={dose.horario}
                        status={dose.status}
                      />
                    </div>
                  ))}
                  {paciente.dosesHoje.length === 0 && (
                    <p style={{ color: 'var(--texto-suave)' }}>Nenhuma dose agendada para hoje.</p>
                  )}
                </div>
              </Cartao>

              <div className="painel-cuidador-detalhe__coluna">
                <Cartao titulo="Ações">
                  <div className="painel-cuidador-detalhe__acoes">
                    <Botao onClick={lembrarAgora} disabled={enviandoAlerta}>
                      {enviandoAlerta ? 'Enviando...' : 'Lembrar agora 🔔'}
                    </Botao>
                    <Botao variante="secundario" onClick={() => navegar(`/historico/${paciente.id}`)}>
                      Ver histórico completo
                    </Botao>
                    <Botao variante="secundario" onClick={irParaAgenda}>
                      Acessar agenda
                    </Botao>
                    <Botao variante="contorno" onClick={irParaCiclosEncerrados}>
                      Ver ciclos encerrados
                    </Botao>
                    <Botao variante="contorno" onClick={() => navegar(`/cuidador/paciente/${paciente.id}/painel`)}>
                      Painel do paciente ⚙️
                    </Botao>
                  </div>
                </Cartao>
                {paciente.codigoAtivacao && (
                  // Paciente cadastrado pelo cuidador que ainda não criou a senha.
                  <Cartao titulo="Acesso do paciente">
                    <p className="painel-cuidador-detalhe__ativacao-texto">
                      Ainda não ativou o acesso ao app. Passe este código para usar em “Ativar meu acesso”, junto com o
                      e-mail cadastrado.
                    </p>
                    <div className="painel-cuidador-detalhe__codigo">{paciente.codigoAtivacao}</div>
                  </Cartao>
                )}
                <CartaoObservacoes paciente={paciente} />
              </div>
            </div>
          </div>
        </div>
      </>
    )
  }

  const emAtencao = pacientesComResumo.filter((paciente) => paciente.precisaAtencao).length
  // Só os ativos: medicamentos de ciclos encerrados não estão mais sendo monitorados.
  const totalMedicamentos = pacientesComResumo.reduce((soma, paciente) => soma + paciente.medicamentosAtivos.length, 0)
  const adesaoMedia = pacientesComResumo.length
    ? Math.round(pacientesComResumo.reduce((soma, paciente) => soma + paciente.pct, 0) / pacientesComResumo.length)
    : 0

  return (
    <>
      <Cabecalho kicker="Painel do cuidador" titulo="Acompanhe seus pacientes" aoAbrirMenu={abrirMenu} />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo painel-cuidador">
          <div className="painel-cuidador__estatisticas">
            <div className="painel-cuidador__estatistica">
              <div className="painel-cuidador__estatistica-numero" style={{ color: 'var(--azul-texto)' }}>
                {pacientesComResumo.length}
              </div>
              <div className="painel-cuidador__estatistica-rotulo">Pacientes vinculados</div>
            </div>
            <div className="painel-cuidador__estatistica painel-cuidador__estatistica--alerta">
              <div className="painel-cuidador__estatistica-numero" style={{ color: 'var(--amarelo)' }}>
                {emAtencao}
              </div>
              <div className="painel-cuidador__estatistica-rotulo">Precisam de atenção</div>
            </div>
            <div className="painel-cuidador__estatistica">
              <div className="painel-cuidador__estatistica-numero" style={{ color: 'var(--verde)' }}>
                {adesaoMedia}%
              </div>
              <div className="painel-cuidador__estatistica-rotulo">Adesão média (30 dias)</div>
            </div>
            <div className="painel-cuidador__estatistica">
              <div className="painel-cuidador__estatistica-numero">{totalMedicamentos}</div>
              <div className="painel-cuidador__estatistica-rotulo">Medicamentos monitorados</div>
            </div>
          </div>

          {solicitacoes.length > 0 && (
            <Cartao titulo={`Solicitações pendentes (${solicitacoes.length})`} className="painel-cuidador__solicitacoes">
              <div className="painel-cuidador__grade-pacientes">
                <AnimatePresence>
                {solicitacoes.map((paciente) => (
                  <motion.div
                    key={paciente.id}
                    className="painel-cuidador__solicitacao"
                    layout
                    initial={VARIANTES_ITEM_LISTA.initial}
                    animate={VARIANTES_ITEM_LISTA.animate}
                    exit={VARIANTES_ITEM_LISTA.exit}
                    transition={TRANSICAO_ITEM_LISTA}
                  >
                    <div className="painel-cuidador__avatar">{paciente.nome.slice(0, 2).toUpperCase()}</div>
                    <div className="painel-cuidador__paciente-info">
                      <div className="painel-cuidador__paciente-nome">{paciente.nome}</div>
                      <div className="painel-cuidador__paciente-sub">{paciente.email}</div>
                    </div>
                    <div className="painel-cuidador__solicitacao-acoes">
                      <Botao tamanho="pequeno" onClick={() => aceitar(paciente)}>
                        Aceitar
                      </Botao>
                      <Botao tamanho="pequeno" variante="contorno" onClick={() => recusar(paciente)}>
                        Recusar
                      </Botao>
                    </div>
                  </motion.div>
                ))}
                </AnimatePresence>
              </div>
            </Cartao>
          )}

          <Cartao
            titulo="Pacientes vinculados"
            acao={
              <div className="painel-cuidador__acao-cabecalho">
                <Botao tamanho="pequeno" onClick={() => setCadastroAberto(true)}>
                  + Cadastrar paciente
                </Botao>
              </div>
            }
          >
            <div className="painel-cuidador__grade-pacientes">
              <AnimatePresence>
              {pacientesComResumo.map((paciente) => (
                <motion.div
                  key={paciente.id}
                  layout
                  initial={VARIANTES_ITEM_LISTA.initial}
                  animate={VARIANTES_ITEM_LISTA.animate}
                  exit={VARIANTES_ITEM_LISTA.exit}
                  transition={TRANSICAO_ITEM_LISTA}
                >
                  <Link
                    to={`/cuidador/paciente/${paciente.id}`}
                    className="painel-cuidador__paciente"
                    onClick={() => selecionarPaciente(paciente.id)}
                  >
                    <div className="painel-cuidador__avatar">{paciente.iniciais}</div>
                    <div className="painel-cuidador__paciente-info">
                      <div className="painel-cuidador__paciente-nome">{paciente.nome}</div>
                      <div className="painel-cuidador__paciente-sub">
                        {paciente.idade ? `${paciente.idade} anos · ` : ''}
                        {paciente.medicamentosAtivos.length} medicamentos
                      </div>
                      <div className="painel-cuidador__barra">
                        <div
                          className="painel-cuidador__barra-preenchida"
                          style={{ width: `${paciente.pct}%`, background: corAdesao(paciente.pct) }}
                        />
                      </div>
                    </div>
                    <div className="painel-cuidador__paciente-status">
                      <span
                        className="painel-cuidador__status-badge"
                        style={
                          paciente.precisaAtencao
                            ? { background: 'var(--amarelo-fundo)', color: 'var(--amarelo-texto)' }
                            : { background: 'var(--verde-fundo)', color: 'var(--verde-texto)' }
                        }
                      >
                        {paciente.precisaAtencao ? 'Atrasado' : 'Em dia'}
                      </span>
                      <div className="painel-cuidador__paciente-pct">{paciente.pct}%</div>
                    </div>
                  </Link>
                </motion.div>
              ))}
              </AnimatePresence>
            </div>
          </Cartao>
        </div>
      </div>

      {cadastroAberto && <CadastroPaciente aoFechar={() => setCadastroAberto(false)} />}
    </>
  )
}
