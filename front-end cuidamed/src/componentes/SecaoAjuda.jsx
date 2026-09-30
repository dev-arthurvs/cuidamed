import './SecaoAjuda.css'

export default function SecaoAjuda({ secao, mostrarTitulo = true, ...resto }) {
  if (!secao) return null

  return (
    <div className="secao-ajuda" {...resto}>
      {mostrarTitulo && <h3 className="secao-ajuda__titulo">{secao.titulo}</h3>}
      <p className="secao-ajuda__para-que-serve">{secao.paraQueServe}</p>
      <ol className="secao-ajuda__passos">
        {secao.passos.map((passo, indice) => (
          <li key={indice}>{passo}</li>
        ))}
      </ol>
    </div>
  )
}
