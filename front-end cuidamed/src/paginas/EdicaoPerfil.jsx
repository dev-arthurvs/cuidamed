import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Cabecalho from '../componentes/Cabecalho'
import Campo from '../componentes/Campo'
import Cartao from '../componentes/Cartao'
import OpcaoSemEmail from '../componentes/OpcaoSemEmail'
import { useApp } from '../contexto/useApp'
import { OPCOES_SEXO } from '../dados/dadosMock'
import { api } from '../utilitarios/api'
import { obterIniciais } from '../utilitarios/horarios'
import { OPCOES_TAMANHO_FONTE } from '../utilitarios/preferenciaFonte'
import { dataDeHojeISO, formatarTelefone, telefoneCompleto } from '../utilitarios/mascaras'
import './EdicaoPerfil.css'

const OPCOES_TEMA = [
  { valor: 'claro', rotulo: 'Claro' },
  { valor: 'escuro', rotulo: 'Escuro' },
]

export default function EdicaoPerfil() {
  const {
    usuario,
    pacienteFoco,
    atualizarPerfil,
    alterarSenha,
    solicitarVinculoCuidador,
    sair,
    mostrarToast,
    tamanhoFonte,
    definirTamanhoFonte,
    tema,
    alternarTema,
  } = useApp()
  const navegar = useNavigate()
  const ehPaciente = usuario.tipo === 'paciente'

  const [nome, setNome] = useState(usuario.nome)
  const [email, setEmail] = useState(usuario.email || '')
  const [semEmail, setSemEmail] = useState(!usuario.email)
  const [dataNascimento, setDataNascimento] = useState(pacienteFoco?.dataNascimento || '')
  const [sexo, setSexo] = useState(pacienteFoco?.sexo || OPCOES_SEXO[0])
  // Telefones salvos antes da máscara aparecem já formatados.
  const [telefone, setTelefone] = useState(() => formatarTelefone((ehPaciente ? pacienteFoco?.telefone : usuario.telefone) || ''))
  const [profissao, setProfissao] = useState(usuario.profissao || '')
  const [senhaAtual, setSenhaAtual] = useState('')
  const [novaSenha, setNovaSenha] = useState('')
  const [confirmarNovaSenha, setConfirmarNovaSenha] = useState('')
  const [cuidadorResponsavel, setCuidadorResponsavel] = useState(null)
  const [emailCuidadorSolicitado, setEmailCuidadorSolicitado] = useState('')
  const [enviandoSolicitacao, setEnviandoSolicitacao] = useState(false)

  useEffect(() => {
    if (!ehPaciente || !pacienteFoco?.cuidadorId) return undefined
    let cancelado = false
    api
      .get(`/api/cuidadores/${pacienteFoco.cuidadorId}`)
      .then((dados) => {
        if (!cancelado) setCuidadorResponsavel(dados)
      })
      .catch(() => {
        if (!cancelado) setCuidadorResponsavel(null)
      })
    return () => {
      cancelado = true
    }
  }, [ehPaciente, pacienteFoco?.cuidadorId])

  async function salvarDados(evento) {
    evento.preventDefault()
    if (!nome.trim()) {
      mostrarToast('Preencha o nome.')
      return
    }
    if (semEmail ? !telefoneCompleto(telefone) : !email.trim()) {
      mostrarToast(semEmail ? 'Sem e-mail, informe o telefone com DDD.' : 'Preencha o e-mail ou marque "Não tenho e-mail".')
      return
    }
    const emailSalvo = semEmail ? '' : email.trim()
    try {
      if (ehPaciente) {
        await atualizarPerfil({
          nome: nome.trim(),
          email: emailSalvo,
          dataNascimento,
          sexo,
          telefone: telefone.trim(),
        })
      } else {
        await atualizarPerfil({
          nome: nome.trim(),
          email: emailSalvo,
          profissao: profissao.trim(),
          telefone: telefone.trim(),
        })
      }
      mostrarToast('Dados atualizados.')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível atualizar os dados.')
    }
  }

  async function atualizarSenha(evento) {
    evento.preventDefault()
    if (novaSenha.length < 8) {
      mostrarToast('A nova senha deve ter no mínimo 8 caracteres.')
      return
    }
    if (novaSenha !== confirmarNovaSenha) {
      mostrarToast('As senhas não coincidem.')
      return
    }
    try {
      await alterarSenha({ senhaAtual, novaSenha })
      setSenhaAtual('')
      setNovaSenha('')
      setConfirmarNovaSenha('')
      mostrarToast('Senha atualizada.')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível atualizar a senha.')
    }
  }

  async function enviarSolicitacaoVinculo(evento) {
    evento.preventDefault()
    if (!emailCuidadorSolicitado.trim()) {
      mostrarToast('Informe o e-mail ou telefone do cuidador.')
      return
    }
    setEnviandoSolicitacao(true)
    try {
      await solicitarVinculoCuidador(emailCuidadorSolicitado.trim())
      mostrarToast('Solicitação enviada! Aguarde a confirmação do cuidador.')
      setEmailCuidadorSolicitado('')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível enviar a solicitação.')
    } finally {
      setEnviandoSolicitacao(false)
    }
  }

  function sairDaConta() {
    sair()
    navegar('/login')
  }

  // Paciente: card do cuidador (vinculado, pedido pendente ou formulário de
  // vínculo), ao lado da Aparência.
  let cartaoCuidador = null
  if (ehPaciente) {
    if (cuidadorResponsavel) {
      cartaoCuidador = (
        <Cartao titulo="Cuidador(a) responsável" className="edicao-perfil__cartao">
          <div className="edicao-perfil__cabecalho">
            <div className="edicao-perfil__avatar">{obterIniciais(cuidadorResponsavel.nome)}</div>
            <div>
              <div className="edicao-perfil__nome">{cuidadorResponsavel.nome}</div>
              <div className="edicao-perfil__papel">{cuidadorResponsavel.profissao || 'Cuidador(a) / Médico(a)'}</div>
            </div>
          </div>
          <div className="edicao-perfil__cuidador-info">
            <div className="edicao-perfil__cuidador-linha">
              <span className="edicao-perfil__cuidador-rotulo">E-mail</span>
              <span>{cuidadorResponsavel.email || '—'}</span>
            </div>
            <div className="edicao-perfil__cuidador-linha">
              <span className="edicao-perfil__cuidador-rotulo">Telefone</span>
              <span>{cuidadorResponsavel.telefone || '—'}</span>
            </div>
          </div>
          <p className="edicao-perfil__cuidador-nota">
            Seu cuidador(a) vê no painel e recebe um aviso, com o app aberto, quando uma dose fica atrasada.
          </p>
        </Cartao>
      )
    } else if (pacienteFoco?.cuidadorSolicitadoId) {
      cartaoCuidador = (
        <Cartao titulo="Cuidador(a) responsável" className="edicao-perfil__cartao">
          <p className="edicao-perfil__cuidador-nota">
            Solicitação enviada — aguardando confirmação do cuidador. Assim que ele aceitar, os dados aparecem
            aqui.
          </p>
        </Cartao>
      )
    } else {
      cartaoCuidador = (
        <Cartao titulo="Vincular cuidador(a)" className="edicao-perfil__cartao">
          <form className="edicao-perfil__formulario" onSubmit={enviarSolicitacaoVinculo}>
            <p className="edicao-perfil__cuidador-nota">
              Informe o e-mail ou telefone do seu cuidador(a) já cadastrado — ele(a) precisa confirmar antes do vínculo valer.
            </p>
            <Campo
              rotulo="E-mail ou telefone do cuidador"
              placeholder="cuidador@email.com ou (79) 99999-9999"
              value={emailCuidadorSolicitado}
              onChange={(e) => setEmailCuidadorSolicitado(e.target.value)}
            />
            <Botao type="submit" variante="secundario" larguraTotal disabled={enviandoSolicitacao}>
              {enviandoSolicitacao ? 'Enviando...' : 'Enviar solicitação'}
            </Botao>
          </form>
        </Cartao>
      )
    }
  }

  const aparencia = (
    <Cartao titulo="Aparência" className="edicao-perfil__cartao">
      <div className="edicao-perfil__opcao">
        <span className="edicao-perfil__opcao-rotulo">Tamanho da fonte</span>
        <div className="edicao-perfil__opcoes">
          {OPCOES_TAMANHO_FONTE.map((opcao) => (
            <Botao
              key={opcao.valor}
              variante={tamanhoFonte === opcao.valor ? 'primario' : 'secundario'}
              onClick={() => definirTamanhoFonte(opcao.valor)}
              aria-pressed={tamanhoFonte === opcao.valor}
            >
              {opcao.rotulo}
            </Botao>
          ))}
        </div>
      </div>
      <div className="edicao-perfil__opcao">
        <span className="edicao-perfil__opcao-rotulo">Tema</span>
        <div className="edicao-perfil__opcoes">
          {OPCOES_TEMA.map((opcao) => (
            <Botao
              key={opcao.valor}
              variante={tema === opcao.valor ? 'primario' : 'secundario'}
              onClick={() => tema !== opcao.valor && alternarTema()}
              aria-pressed={tema === opcao.valor}
            >
              {opcao.rotulo}
            </Botao>
          ))}
        </div>
      </div>
      <Botao variante="secundario" larguraTotal onClick={() => navegar('/acessibilidade')}>
        Ajuda e acessibilidade
      </Botao>
    </Cartao>
  )

  return (
    <>
      <Cabecalho kicker="Minha conta" titulo="Configurações" />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo edicao-perfil">
          <div className="edicao-perfil__linha-dupla">
            <Cartao titulo="Dados pessoais" className="edicao-perfil__cartao">
              <div className="edicao-perfil__cabecalho">
                <div className="edicao-perfil__avatar">{obterIniciais(usuario.nome)}</div>
                <div>
                  <div className="edicao-perfil__nome">{usuario.nome}</div>
                  <div className="edicao-perfil__papel">{usuario.tipo === 'cuidador' ? 'Cuidador(a) / Médico(a)' : 'Paciente'}</div>
                </div>
              </div>
              <form className="edicao-perfil__formulario" onSubmit={salvarDados}>
                <Campo rotulo="Nome de usuário" value={nome} onChange={(e) => setNome(e.target.value)} />
                {ehPaciente ? (
                  <>
                    <div className="edicao-perfil__grade-dupla">
                      <Campo
                        rotulo="Data de nascimento"
                        tipo="date"
                        value={dataNascimento}
                        max={dataDeHojeISO()}
                        onChange={(e) => setDataNascimento(e.target.value)}
                      />
                      <Campo rotulo="Sexo" tipo="select" value={sexo} onChange={(e) => setSexo(e.target.value)}>
                        {OPCOES_SEXO.map((opcao) => (
                          <option key={opcao}>{opcao}</option>
                        ))}
                      </Campo>
                    </div>
                    <Campo
                      rotulo="Telefone"
                      tipo="tel"
                      placeholder="(11) 98765-4321"
                      value={telefone}
                      onChange={(e) => setTelefone(e.target.value)}
                    />
                  </>
                ) : (
                  <>
                    <Campo
                      rotulo="Profissão"
                      placeholder="Ex.: Médica, Enfermeira, Cuidadora"
                      value={profissao}
                      onChange={(e) => setProfissao(e.target.value)}
                    />
                    <Campo
                      rotulo="Telefone"
                      tipo="tel"
                      placeholder="(11) 98765-4321"
                      value={telefone}
                      onChange={(e) => setTelefone(e.target.value)}
                    />
                  </>
                )}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                  {!semEmail && <Campo rotulo="E-mail" tipo="email" value={email} onChange={(e) => setEmail(e.target.value)} />}
                  <OpcaoSemEmail marcado={semEmail} aoMudar={setSemEmail} />
                </div>
                <Botao type="submit" larguraTotal>
                  Salvar alterações
                </Botao>
              </form>
            </Cartao>

            <Cartao titulo="Senha" className="edicao-perfil__cartao">
              <form className="edicao-perfil__formulario edicao-perfil__formulario--senha" onSubmit={atualizarSenha}>
                <Campo
                  rotulo="Senha atual"
                  tipo="password"
                  placeholder="••••••••"
                  value={senhaAtual}
                  onChange={(e) => setSenhaAtual(e.target.value)}
                />
                <Campo
                  rotulo="Nova senha"
                  tipo="password"
                  placeholder="Mínimo 8 caracteres"
                  value={novaSenha}
                  onChange={(e) => setNovaSenha(e.target.value)}
                />
                <Campo
                  rotulo="Confirmar nova senha"
                  tipo="password"
                  placeholder="Repita a nova senha"
                  value={confirmarNovaSenha}
                  onChange={(e) => setConfirmarNovaSenha(e.target.value)}
                />
                <Botao type="submit" variante="secundario" larguraTotal>
                  Atualizar senha
                </Botao>
                <div className="edicao-perfil__divisor" />
                <Botao type="button" variante="perigo" larguraTotal onClick={sairDaConta}>
                  Sair da conta
                </Botao>
              </form>
            </Cartao>
          </div>

          {cartaoCuidador ? (
            <div className="edicao-perfil__linha-dupla">
              {aparencia}
              {cartaoCuidador}
            </div>
          ) : (
            aparencia
          )}
        </div>
      </div>
    </>
  )
}
