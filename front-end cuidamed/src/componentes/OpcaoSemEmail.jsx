import './OpcaoSemEmail.css'

// Caixa "Não tenho e-mail" dos cadastros: muitos idosos não têm e-mail. Marcada,
// o campo de e-mail some e o telefone passa a ser o que permite entrar no app.
export default function OpcaoSemEmail({ marcado, aoMudar }) {
  return (
    <div className="opcao-sem-email">
      <label className="opcao-sem-email__rotulo">
        <input type="checkbox" checked={marcado} onChange={(e) => aoMudar(e.target.checked)} />
        <span>Não tenho e-mail</span>
      </label>
      {marcado && <p className="opcao-sem-email__nota">O acesso ao app será feito pelo número de telefone.</p>}
    </div>
  )
}
