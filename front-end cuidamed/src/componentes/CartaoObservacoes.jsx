import { useState } from 'react'
import { useApp } from '../contexto/useApp'
import Botao from './Botao'

export default function CartaoObservacoes({ paciente }) {
  const { atualizarObservacoesClinicas, mostrarToast } = useApp()
  const salvo = paciente.observacoesClinicas || ''
  const [rascunho, setRascunho] = useState(salvo)
  const [base, setBase] = useState(salvo)
  const [salvando, setSalvando] = useState(false)

  if (salvo !== base) {
    setBase(salvo)
    if (rascunho === base) setRascunho(salvo)
  }

  const alterado = rascunho.trim() !== salvo.trim()

  async function salvar() {
    setSalvando(true)
    try {
      await atualizarObservacoesClinicas(paciente.id, rascunho)
      mostrarToast('Observações clínicas salvas.')
    } catch (erro) {
      mostrarToast(erro.message || 'Não foi possível salvar as observações.')
    } finally {
      setSalvando(false)
    }
  }

  return (
    <div className="painel-cuidador-detalhe__observacoes">
      <label className="painel-cuidador-detalhe__observacoes-titulo" htmlFor={`observacoes-${paciente.id}`}>
        Observações clínicas
      </label>
      <textarea
        id={`observacoes-${paciente.id}`}
        className="painel-cuidador-detalhe__observacoes-campo"
        placeholder="Ex.: alergia a dipirona, toma os remédios em jejum, dificuldade para engolir comprimidos..."
        rows={4}
        value={rascunho}
        onChange={(e) => setRascunho(e.target.value)}
      />
      <div className="painel-cuidador-detalhe__observacoes-acoes">
        {alterado && (
          <Botao tamanho="pequeno" variante="contorno" type="button" onClick={() => setRascunho(salvo)} disabled={salvando}>
            Descartar
          </Botao>
        )}
        <Botao tamanho="pequeno" type="button" onClick={salvar} disabled={!alterado || salvando}>
          {salvando ? 'Salvando...' : 'Salvar observações'}
        </Botao>
      </div>
    </div>
  )
}
