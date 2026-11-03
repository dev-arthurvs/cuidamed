import { useState } from 'react'
import Botao from '../componentes/Botao'
import Campo from '../componentes/Campo'
import OpcaoSemEmail from '../componentes/OpcaoSemEmail'
import { useApp } from '../contexto/useApp'
import { OPCOES_SEXO } from '../dados/dadosMock'
import { dataDeHojeISO, telefoneCompleto } from '../utilitarios/mascaras'
import './CadastroPaciente.css'

const FORMULARIO_VAZIO = {
  nome: '',
  dataNascimento: '',
  sexo: OPCOES_SEXO[0],
  enfermidade: '',
  email: '',
  telefone: '',
}

export default function CadastroPaciente({ aoFechar }) {
  const { cadastrarPaciente, mostrarToast } = useApp()
  const [form, setForm] = useState(FORMULARIO_VAZIO)
  const [semEmail, setSemEmail] = useState(false)

  function definirCampo(chave, valor) {
    setForm((atual) => ({ ...atual, [chave]: valor }))
  }

  async function salvar(evento) {
    evento.preventDefault()
    if (!form.nome.trim()) {
      mostrarToast('Informe o nome do paciente.')
      return
    }
    if (semEmail ? !telefoneCompleto(form.telefone) : !form.email.trim()) {
      mostrarToast(semEmail ? 'Sem e-mail, informe o telefone com DDD.' : 'Informe o e-mail ou marque "Não tenho e-mail".')
      return
    }
    try {
      await cadastrarPaciente({ ...form, email: semEmail ? '' : form.email })
      mostrarToast('Paciente cadastrado e vinculado com sucesso.')
      aoFechar()
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível cadastrar o paciente.')
    }
  }

  return (
    <div className="cadastro-paciente__fundo" role="dialog" aria-modal="true">
      <div className="cadastro-paciente__caixa">
        <div className="cadastro-paciente__cabecalho">
          <div>
            <div className="cadastro-paciente__kicker">Pacientes</div>
            <h2 className="cadastro-paciente__titulo">Cadastrar novo paciente</h2>
          </div>
          <button type="button" className="cadastro-paciente__fechar" onClick={aoFechar} aria-label="Fechar">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.3" strokeLinecap="round">
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>
        </div>

        <form className="cadastro-paciente__formulario" onSubmit={salvar}>
          <div className="cadastro-paciente__grade">
            <Campo
              className="cadastro-paciente__campo-largo"
              rotulo="Nome completo"
              placeholder="Ex.: Maria Aparecida Souza"
              value={form.nome}
              onChange={(e) => definirCampo('nome', e.target.value)}
            />
            <Campo
              rotulo="Data de nascimento"
              tipo="date"
              value={form.dataNascimento}
              max={dataDeHojeISO()}
              onChange={(e) => definirCampo('dataNascimento', e.target.value)}
            />
            <Campo rotulo="Sexo" tipo="select" value={form.sexo} onChange={(e) => definirCampo('sexo', e.target.value)}>
              {OPCOES_SEXO.map((opcao) => (
                <option key={opcao}>{opcao}</option>
              ))}
            </Campo>
            <Campo
              className="cadastro-paciente__campo-largo"
              rotulo="Enfermidade / condição principal"
              placeholder="Ex.: Hipertensão e diabetes tipo 2"
              value={form.enfermidade}
              onChange={(e) => definirCampo('enfermidade', e.target.value)}
            />
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {!semEmail && (
                <Campo
                  rotulo="E-mail"
                  tipo="email"
                  placeholder="paciente@email.com"
                  value={form.email}
                  onChange={(e) => definirCampo('email', e.target.value)}
                />
              )}
              <OpcaoSemEmail marcado={semEmail} aoMudar={setSemEmail} />
            </div>
            <Campo
              rotulo="Telefone"
              tipo="tel"
              placeholder="(11) 98765-4321"
              value={form.telefone}
              onChange={(e) => definirCampo('telefone', e.target.value)}
            />
          </div>

          <div className="cadastro-paciente__rodape">
            <Botao type="button" variante="contorno" onClick={aoFechar}>
              Cancelar
            </Botao>
            <Botao type="submit">Cadastrar paciente</Botao>
          </div>
        </form>
      </div>
    </div>
  )
}
