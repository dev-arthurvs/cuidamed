import { useState } from 'react'
import { Link, NavLink, useNavigate } from 'react-router-dom'
import { useApp } from '../contexto/useApp'
import { obterIniciais } from '../utilitarios/horarios'
import Botao from './Botao'
import { ICONES_NAVEGACAO, ITENS_NAVEGACAO } from './itensNavegacao'
import LogoMarca from './LogoMarca'
import './BarraNavegacao.css'

const ROTAS_POR_PACIENTE = new Set(['/agenda', '/ciclos-encerrados', '/historico'])

export default function BarraNavegacao({ aberta, aoFechar }) {
  const { usuario, pacientes, pacienteFoco, selecionarPaciente, sair } = useApp()
  const navegar = useNavigate()
  const [itemExpandido, setItemExpandido] = useState(null)
  const ehCuidador = usuario?.tipo === 'cuidador'

  function sairDaConta() {
    aoFechar()
    sair()
    navegar('/login')
  }

  function escolherPaciente(rota, paciente) {
    selecionarPaciente(paciente.id)
    navegar(rota)
    setItemExpandido(null)
    aoFechar()
  }

  return (
    <>
      {aberta && <div className="barra-navegacao__sobreposicao" onClick={aoFechar} />}
      <nav className={`barra-navegacao${aberta ? ' barra-navegacao--aberta' : ''}`}>
        <div className="barra-navegacao__topo">
          <Link to="/painel" className="barra-navegacao__logo" onClick={aoFechar} aria-label="Ir para o início">
            <LogoMarca tamanho={42} />
          </Link>
          <button type="button" className="barra-navegacao__fechar" onClick={aoFechar} aria-label="Fechar menu de navegação">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>
        </div>

        <div className="barra-navegacao__itens">
          {ITENS_NAVEGACAO.map((item) => {
            if (!(ehCuidador && ROTAS_POR_PACIENTE.has(item.rota))) {
              return (
                <NavLink
                  key={item.rota}
                  to={item.rota}
                  onClick={aoFechar}
                  className={({ isActive }) => `barra-navegacao__item${isActive ? ' barra-navegacao__item--ativo' : ''}`}
                >
                  <span className="barra-navegacao__icone">{ICONES_NAVEGACAO[item.icone]}</span>
                  <span className="barra-navegacao__rotulo">{item.rotulo}</span>
                </NavLink>
              )
            }

            const expandido = itemExpandido === item.rota

            return (
              <div key={item.rota} className="barra-navegacao__grupo">
                <button
                  type="button"
                  className={`barra-navegacao__item${expandido ? ' barra-navegacao__item--ativo' : ''}`}
                  onClick={() => setItemExpandido(expandido ? null : item.rota)}
                >
                  <span className="barra-navegacao__icone">{ICONES_NAVEGACAO[item.icone]}</span>
                  <span className="barra-navegacao__rotulo">{item.rotulo}</span>
                  <svg
                    className="barra-navegacao__seta"
                    width="14"
                    height="14"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M6 9l6 6 6-6" />
                  </svg>
                </button>

                {expandido && (
                  <div className="barra-navegacao__sublista">
                    {pacientes.map((paciente) => (
                      <button
                        type="button"
                        key={paciente.id}
                        className={`barra-navegacao__paciente${
                          pacienteFoco?.id === paciente.id ? ' barra-navegacao__paciente--selecionado' : ''
                        }`}
                        onClick={() => escolherPaciente(item.rota, paciente)}
                      >
                        <span className="barra-navegacao__paciente-avatar">{paciente.iniciais}</span>
                        <span className="barra-navegacao__paciente-nome">{paciente.nome}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )
          })}

          {/* Só no menu hambúrguer (a barra superior não tem): atalho direto para a
              tela de acessibilidade, sem precisar passar pelo Perfil — igual ao mobile. */}
          <NavLink
            to="/acessibilidade"
            onClick={aoFechar}
            className={({ isActive }) => `barra-navegacao__item${isActive ? ' barra-navegacao__item--ativo' : ''}`}
          >
            <span className="barra-navegacao__icone">{ICONES_NAVEGACAO.acessibilidade}</span>
            <span className="barra-navegacao__rotulo">Ajuda e acessibilidade</span>
          </NavLink>
        </div>

        <div className="barra-navegacao__rodape">
          <div className="barra-navegacao__usuario">
            <div className="barra-navegacao__avatar">{usuario ? obterIniciais(usuario.nome) : ''}</div>
            <div className="barra-navegacao__usuario-info">
              <div className="barra-navegacao__usuario-nome">{usuario?.nome}</div>
              <div className="barra-navegacao__usuario-papel">
                {usuario?.tipo === 'cuidador' ? 'Cuidador(a) / Médico(a)' : 'Paciente'}
              </div>
            </div>
          </div>
          <Botao variante="contorno" larguraTotal onClick={sairDaConta}>
            Sair da conta
          </Botao>
        </div>
      </nav>
    </>
  )
}
