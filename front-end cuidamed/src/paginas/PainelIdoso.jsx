import Cabecalho from '../componentes/Cabecalho'
import CarrosselDoses from '../componentes/CarrosselDoses'
import Cartao from '../componentes/Cartao'
import AvisosEstoque from '../componentes/AvisosEstoque'
import CartaoPaciente from '../componentes/CartaoPaciente'
import FaixaNotificacoes from '../componentes/FaixaNotificacoes'
import Rotulo from '../componentes/Rotulo'
import { useApp } from '../contexto/useApp'
import './PainelIdoso.css'

export default function PainelIdoso() {
  const { usuario, pacienteFoco, marcarDoseComoTomada, desfazerDose } = useApp()
  if (!pacienteFoco) return null

  const doses = [...pacienteFoco.dosesHoje].sort((a, b) => a.horario.localeCompare(b.horario))
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
      />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo painel-idoso">
          <FaixaNotificacoes descricao="Receba um aviso no dispositivo e um som quando for a hora de tomar um remédio." />

          <div className="painel-idoso__proximo">
            <CarrosselDoses
              doses={doses}
              aoRegistrar={(doseId) => marcarDoseComoTomada(pacienteFoco.id, doseId)}
              aoDesfazer={(dose) => desfazerDose(pacienteFoco.id, dose)}
            />
          </div>

          {/* À esquerda o card da dose; à direita o Cartão do paciente. */}
          <CartaoPaciente paciente={pacienteFoco} contagem={contagem} />

          <AvisosEstoque paciente={pacienteFoco} className="painel-idoso__agenda-completa" />

          <Cartao titulo="Agenda de hoje" className="painel-idoso__agenda-completa">
            <div className="painel-idoso__lista-doses">
              {doses.map((dose) => (
                <div className="painel-idoso__dose" key={dose.id}>
                  <div className="painel-idoso__dose-hora">{dose.horario}</div>
                  <div className="painel-idoso__dose-info">
                    <div className="painel-idoso__dose-nome">{dose.nome}</div>
                    {dose.dosagem && <div className="painel-idoso__dose-dosagem">{dose.dosagem}</div>}
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
