import { AnimatePresence, motion } from 'framer-motion'
import { useState } from 'react'
import { Link, useOutletContext } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Cabecalho from '../componentes/Cabecalho'
import Cartao from '../componentes/Cartao'
import Rotulo from '../componentes/Rotulo'
import { useApp } from '../contexto/useApp'
import { pedirPermissaoNotificacao, statusPermissaoNotificacao } from '../utilitarios/notificacoes'
import { formatarQuantidadePorDose } from '../utilitarios/whatsapp'
import './PainelIdoso.css'

export default function PainelIdoso() {
  const { usuario, pacienteFoco, marcarDoseComoTomada } = useApp()
  const { abrirMenu } = useOutletContext()
  const [statusNotificacao, setStatusNotificacao] = useState(() => statusPermissaoNotificacao())

  async function ativarNotificacoes() {
    const resultado = await pedirPermissaoNotificacao()
    setStatusNotificacao(resultado)
  }

  if (!pacienteFoco) return null

  const doses = [...pacienteFoco.dosesHoje].sort((a, b) => a.horario.localeCompare(b.horario))
  const proxima = doses.find((dose) => dose.status !== 'tomado' && dose.status !== 'perdido')
  const temDosePerdida = doses.some((dose) => dose.status === 'perdido')
  const primeiroNome = usuario.nome.split(' ')[0]
  const horaAtual = new Date().getHours()
  const saudacao = horaAtual < 12 ? 'Bom dia' : horaAtual < 18 ? 'Boa tarde' : 'Boa noite'

  const contagem = {
    tomados: doses.filter((d) => d.status === 'tomado').length,
    aTomar: doses.filter((d) => d.status === 'pendente').length,
    atrasados: doses.filter((d) => d.status === 'atrasado' || d.status === 'perdido').length,
  }

  return (
    <>
      <Cabecalho
        kicker="Painel do paciente"
        titulo={`${saudacao}, ${primeiroNome}!`}
        aoAbrirMenu={abrirMenu}
      />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo painel-idoso">
          {statusNotificacao === 'default' && (
            <div className="painel-idoso__banner-notificacao">
              <div>
                <strong>Ative os lembretes sonoros e notificações</strong>
                <p>Receba um aviso no dispositivo e um som quando for a hora de tomar um remédio.</p>
              </div>
              <Botao tamanho="pequeno" onClick={ativarNotificacoes}>
                Ativar
              </Botao>
            </div>
          )}

          <div className="painel-idoso__proximo">
            <div className="painel-idoso__proximo-kicker">Próximo medicamento</div>
            <AnimatePresence mode="wait">
              {proxima ? (
                <motion.div
                  key={proxima.id}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -8 }}
                  transition={{ duration: 0.2, ease: 'easeOut' }}
                >
                  <div className="painel-idoso__proximo-linha">
                    <span className="painel-idoso__proximo-hora">{proxima.horario}</span>
                  </div>
                  <div className="painel-idoso__proximo-nome">{proxima.nome}</div>
                  {/* Quantidade por dose (ex.: "1 comp"); sem ela cadastrada, cai na dosagem. */}
                  <div className="painel-idoso__proximo-dose">{formatarQuantidadePorDose(proxima)}</div>
                  <Botao className="painel-idoso__proximo-botao" onClick={() => marcarDoseComoTomada(pacienteFoco.id, proxima.id)}>
                    Registrar dose
                  </Botao>
                </motion.div>
              ) : (
                <motion.div
                  key="nada-pendente"
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -8 }}
                  transition={{ duration: 0.2, ease: 'easeOut' }}
                >
                  <div className="painel-idoso__proximo-nome">Nada pendente</div>
                  <div className="painel-idoso__proximo-dose">
                    {temDosePerdida
                      ? 'Sem doses pendentes no momento — algumas doses de hoje foram perdidas.'
                      : 'Todas as doses de hoje foram tomadas.'}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          <div className="painel-idoso__coluna-direita">
            <div className="painel-idoso__estatisticas">
              <div className="painel-idoso__estatistica">
                <div className="painel-idoso__estatistica-numero" style={{ color: 'var(--verde)' }}>
                  {contagem.tomados}
                </div>
                <div className="painel-idoso__estatistica-rotulo">Tomados</div>
              </div>
              <div className="painel-idoso__estatistica">
                <div className="painel-idoso__estatistica-numero" style={{ color: 'var(--azul)' }}>
                  {contagem.aTomar}
                </div>
                <div className="painel-idoso__estatistica-rotulo">A tomar</div>
              </div>
              <div className="painel-idoso__estatistica">
                <div className="painel-idoso__estatistica-numero" style={{ color: 'var(--amarelo)' }}>
                  {contagem.atrasados}
                </div>
                <div className="painel-idoso__estatistica-rotulo">Atrasados</div>
              </div>
            </div>

          </div>

          <Cartao
            titulo="Agenda de hoje"
            className="painel-idoso__agenda-completa"
            acao={
              <Link to="/agenda" className="painel-idoso__link">
                Ver agenda completa ›
              </Link>
            }
          >
            <div className="painel-idoso__lista-doses">
              {doses.map((dose) => (
                <div className="painel-idoso__dose" key={dose.id}>
                  <div className="painel-idoso__dose-hora">{dose.horario}</div>
                  <div className="painel-idoso__dose-info">
                    <div className="painel-idoso__dose-nome">{dose.nome}</div>
                    <div className="painel-idoso__dose-dosagem">{dose.dosagem}</div>
                  </div>
                  <Rotulo status={dose.status} />
                </div>
              ))}
            </div>
          </Cartao>
        </div>
      </div>
    </>
  )
}
