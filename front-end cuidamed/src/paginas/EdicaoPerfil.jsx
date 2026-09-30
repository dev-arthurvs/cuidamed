import { useEffect, useState } from 'react'
import { useNavigate, useOutletContext } from 'react-router-dom'
import Botao from '../componentes/Botao'
import Cabecalho from '../componentes/Cabecalho'
import Campo from '../componentes/Campo'
import Cartao from '../componentes/Cartao'
import { useApp } from '../contexto/useApp'
import { OPCOES_SEXO } from '../dados/dadosMock'
import { api } from '../utilitarios/api'
import { obterIniciais } from '../utilitarios/horarios'
import { OPCOES_TAMANHO_FONTE } from '../utilitarios/preferenciaFonte'
import './EdicaoPerfil.css'

export default function EdicaoPerfil() {
  const { usuario, pacienteFoco, atualizarPerfil, alterarSenha, solicitarVinculoCuidador, sair, mostrarToast, tamanhoFonte, definirTamanhoFonte } =
    useApp()
  const navegar = useNavigate()
  const { abrirMenu } = useOutletContext()
  const ehPaciente = usuario.tipo === 'paciente'

  const [nome, setNome] = useState(usuario.nome)
  const [email, setEmail] = useState(usuario.email)
  const [dataNascimento, setDataNascimento] = useState(pacienteFoco?.dataNascimento || '')
  const [sexo, setSexo] = useState(pacienteFoco?.sexo || OPCOES_SEXO[0])
  const [telefone, setTelefone] = useState((ehPaciente ? pacienteFoco?.telefone : usuario.telefone) || '')
  const [endereco, setEndereco] = useState(pacienteFoco?.endereco || '')
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
    if (!nome.trim() || !email.trim()) {
      mostrarToast('Preencha nome e e-mail.')
      return
    }
    try {
      if (ehPaciente) {
        await atualizarPerfil({
          nome: nome.trim(),
          email: email.trim(),
          dataNascimento,
          sexo,
          telefone: telefone.trim(),
          endereco: endereco.trim(),
        })
      } else {
        await atualizarPerfil({
          nome: nome.trim(),
          email: email.trim(),
          profissao: profissao.trim(),
          telefone: telefone.trim(),
        })
      }
      mostrarToast('Perfil atualizado.')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível atualizar o perfil.')
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
      mostrarToast('Informe o e-mail do cuidador.')
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

  return (
    <>
      <Cabecalho kicker="Configurações" titulo="Edição de perfil" aoAbrirMenu={abrirMenu} />
      <div className="pagina-corpo">
        <div className="pagina-corpo__miolo edicao-perfil">
          <div className="edicao-perfil__linha-dupla">
            <Cartao className="edicao-perfil__cartao">
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
                    <Campo
                      rotulo="Endereço"
                      placeholder="Rua, número, bairro - cidade/UF"
                      value={endereco}
                      onChange={(e) => setEndereco(e.target.value)}
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
                <Campo rotulo="E-mail" tipo="email" value={email} onChange={(e) => setEmail(e.target.value)} />
                <Botao type="submit" larguraTotal>
                  Salvar alterações
                </Botao>
              </form>
            </Cartao>

            <Cartao titulo="Alterar senha" className="edicao-perfil__cartao">
              <form className="edicao-perfil__formulario" onSubmit={atualizarSenha}>
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

          <div className="edicao-perfil__linha-dupla">
            <Cartao titulo="Ajuda e acessibilidade" className="edicao-perfil__cartao">
              <p className="edicao-perfil__cuidador-nota">
                Não sabe como usar alguma parte do sistema? Veja o guia completo com explicações e passo a passo de
                cada tela.
              </p>
              <Botao variante="secundario" larguraTotal onClick={() => navegar('/acessibilidade')}>
                Ajuda e acessibilidade
              </Botao>
            </Cartao>

            <Cartao titulo="Tamanho da fonte" className="edicao-perfil__cartao">
              <p className="edicao-perfil__cuidador-nota">Ajusta o tamanho do texto em todo o sistema.</p>
              <div className="edicao-perfil__fonte-opcoes">
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
            </Cartao>
          </div>

          {ehPaciente && cuidadorResponsavel && (
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
                  <span>{cuidadorResponsavel.email}</span>
                </div>
                <div className="edicao-perfil__cuidador-linha">
                  <span className="edicao-perfil__cuidador-rotulo">Telefone</span>
                  <span>{cuidadorResponsavel.telefone || '—'}</span>
                </div>
              </div>
              <p className="edicao-perfil__cuidador-nota">
                Seu cuidador(a) recebe alertas quando uma dose fica atrasada ou é perdida.
              </p>
            </Cartao>
          )}

          {ehPaciente && !cuidadorResponsavel && pacienteFoco?.cuidadorSolicitadoId && (
            <Cartao titulo="Cuidador(a) responsável" className="edicao-perfil__cartao">
              <p className="edicao-perfil__cuidador-nota">
                Solicitação enviada — aguardando confirmação do cuidador. Assim que ele aceitar, os dados aparecem
                aqui.
              </p>
            </Cartao>
          )}

          {ehPaciente && !cuidadorResponsavel && !pacienteFoco?.cuidadorSolicitadoId && (
            <Cartao titulo="Vincular cuidador(a)" className="edicao-perfil__cartao">
              <form className="edicao-perfil__formulario" onSubmit={enviarSolicitacaoVinculo}>
                <p className="edicao-perfil__cuidador-nota">
                  Informe o e-mail do seu cuidador(a) já cadastrado — ele(a) precisa confirmar antes do vínculo valer.
                </p>
                <Campo
                  rotulo="E-mail do cuidador"
                  tipo="email"
                  placeholder="cuidador@email.com"
                  value={emailCuidadorSolicitado}
                  onChange={(e) => setEmailCuidadorSolicitado(e.target.value)}
                />
                <Botao type="submit" variante="secundario" larguraTotal disabled={enviandoSolicitacao}>
                  {enviandoSolicitacao ? 'Enviando...' : 'Enviar solicitação'}
                </Botao>
              </form>
            </Cartao>
          )}
        </div>
      </div>
    </>
  )
}
