import { useState } from 'react'
import Botao from '../componentes/Botao'
import Campo from '../componentes/Campo'
import { useApp } from '../contexto/useApp'
import { FORMAS_MEDICAMENTO, FREQUENCIAS_MEDICAMENTO, UNIDADE_ESTOQUE_POR_FORMA } from '../dados/dadosMock'
import { dataAtualISO } from '../utilitarios/horarios'
import './FormularioMedicamento.css'

const FORMULARIO_VAZIO = {
  nome: '',
  dosagem: '',
  forma: FORMAS_MEDICAMENTO[0],
  frequencia: FREQUENCIAS_MEDICAMENTO[0],
  horarios: [],
  inicio: dataAtualISO(),
  fim: '',
  observacoes: '',
  quantidadeEstoque: '',
  quantidadePorDose: '',
}

export default function FormularioMedicamento({ medicamentoExistente, aoFechar }) {
  const { pacienteFoco, adicionarMedicamento, editarMedicamento, mostrarToast } = useApp()

  const [form, setForm] = useState(() =>
    medicamentoExistente ? { ...medicamentoExistente, horarios: [...medicamentoExistente.horarios] } : FORMULARIO_VAZIO,
  )
  const [rascunhoHorario, setRascunhoHorario] = useState('')
  const ehPomada = form.forma === 'Pomada'
  const unidadeEstoque = UNIDADE_ESTOQUE_POR_FORMA[form.forma] || 'unidades'

  if (!pacienteFoco) return null

  function definirCampo(chave, valor) {
    setForm((atual) => ({ ...atual, [chave]: valor }))
  }

  function adicionarHorario() {
    if (!rascunhoHorario) return
    if (form.horarios.includes(rascunhoHorario)) {
      mostrarToast('Esse horário já foi adicionado.')
      return
    }
    definirCampo('horarios', [...form.horarios, rascunhoHorario])
    setRascunhoHorario('')
  }

  function removerHorario(horario) {
    definirCampo(
      'horarios',
      form.horarios.filter((item) => item !== horario),
    )
  }

  async function salvar(evento) {
    evento.preventDefault()
    if (!form.nome.trim()) {
      mostrarToast('Informe o nome do medicamento.')
      return
    }
    if (form.horarios.length === 0) {
      mostrarToast('Adicione ao menos um horário de dose.')
      return
    }
    if (form.fim && form.inicio && form.fim < form.inicio) {
      mostrarToast('A data de fim não pode ser anterior à data de início.')
      return
    }
    if (!ehPomada && (form.quantidadeEstoque === '' || Number(form.quantidadeEstoque) < 0)) {
      mostrarToast('Informe a quantidade em estoque.')
      return
    }
    if (!ehPomada && (form.quantidadePorDose === '' || Number(form.quantidadePorDose) <= 0)) {
      mostrarToast('Informe a quantidade usada por dose.')
      return
    }

    try {
      if (medicamentoExistente) {
        await editarMedicamento(pacienteFoco.id, medicamentoExistente.id, form)
        mostrarToast('Medicamento atualizado.')
      } else {
        await adicionarMedicamento(pacienteFoco.id, form)
        mostrarToast('Medicamento adicionado.')
      }
      aoFechar()
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível salvar o medicamento.')
    }
  }

  return (
    <div className="formulario-medicamento__fundo" role="dialog" aria-modal="true">
      <div className="formulario-medicamento__caixa">
        <div className="formulario-medicamento__cabecalho">
          <div>
            <div className="formulario-medicamento__kicker">{medicamentoExistente ? 'Editar medicamento' : 'Novo medicamento'}</div>
            <h2 className="formulario-medicamento__titulo">
              {medicamentoExistente ? 'Atualize as informações do medicamento' : 'Preencha os dados do medicamento'}
            </h2>
          </div>
          <button type="button" className="formulario-medicamento__fechar" onClick={aoFechar} aria-label="Fechar">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.3" strokeLinecap="round">
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>
        </div>

        <form className="formulario-medicamento__formulario" onSubmit={salvar}>
          <div className="formulario-medicamento__grade">
            <Campo
              className="formulario-medicamento__campo-largo"
              rotulo="Nome do medicamento"
              placeholder="Ex.: Losartana"
              value={form.nome}
              onChange={(e) => definirCampo('nome', e.target.value)}
            />
            <Campo
              rotulo="Dosagem"
              placeholder={ehPomada ? 'Ex.: 1% (concentração)' : '50 mg'}
              value={form.dosagem}
              onChange={(e) => definirCampo('dosagem', e.target.value)}
            />
            <Campo rotulo="Forma" tipo="select" value={form.forma} onChange={(e) => definirCampo('forma', e.target.value)}>
              {FORMAS_MEDICAMENTO.map((forma) => (
                <option key={forma}>{forma}</option>
              ))}
            </Campo>
            <Campo
              rotulo="Frequência"
              tipo="select"
              value={form.frequencia}
              onChange={(e) => definirCampo('frequencia', e.target.value)}
            >
              {FREQUENCIAS_MEDICAMENTO.map((frequencia) => (
                <option key={frequencia}>{frequencia}</option>
              ))}
            </Campo>
            {!ehPomada && (
              <>
                <Campo
                  rotulo={`Estoque atual (${unidadeEstoque})`}
                  tipo="number"
                  min="0"
                  placeholder="Ex.: 30"
                  value={form.quantidadeEstoque}
                  onChange={(e) => definirCampo('quantidadeEstoque', e.target.value)}
                  required
                />
                <Campo
                  rotulo={`Quantidade por dose (${unidadeEstoque})`}
                  tipo="number"
                  min="1"
                  placeholder="Ex.: 1"
                  value={form.quantidadePorDose}
                  onChange={(e) => definirCampo('quantidadePorDose', e.target.value)}
                  required
                />
              </>
            )}
          </div>

          <div className="formulario-medicamento__horarios">
            <label className="campo__rotulo">Horários das doses</label>
            <div className="formulario-medicamento__pilulas">
              {form.horarios.map((horario) => (
                <div className="formulario-medicamento__pilula" key={horario}>
                  <span>{horario}</span>
                  <button type="button" onClick={() => removerHorario(horario)} aria-label={`Remover horário ${horario}`}>
                    ×
                  </button>
                </div>
              ))}
            </div>
            <div className="formulario-medicamento__adicionar">
              <input
                type="time"
                value={rascunhoHorario}
                onChange={(e) => setRascunhoHorario(e.target.value)}
                className="formulario-medicamento__entrada-hora"
              />
              <Botao type="button" variante="secundario" onClick={adicionarHorario}>
                Adicionar horário
              </Botao>
            </div>
          </div>

          <div className="formulario-medicamento__grade">
            <Campo
              rotulo="Data de início"
              tipo="date"
              value={form.inicio}
              onChange={(e) => definirCampo('inicio', e.target.value)}
            />
            <Campo
              rotulo="Data de fim (opcional)"
              tipo="date"
              value={form.fim}
              onChange={(e) => definirCampo('fim', e.target.value)}
            />
          </div>

          <Campo
            rotulo="Observações / prescrição"
            tipo="textarea"
            rows={3}
            placeholder="Ex.: tomar após o café da manhã"
            value={form.observacoes}
            onChange={(e) => definirCampo('observacoes', e.target.value)}
          />

          <div className="formulario-medicamento__rodape">
            <Botao type="button" variante="contorno" onClick={aoFechar}>
              Cancelar
            </Botao>
            <Botao type="submit">{medicamentoExistente ? 'Salvar alterações' : 'Adicionar medicamento'}</Botao>
          </div>
        </form>
      </div>
    </div>
  )
}
