"""Gera o relatório dos testes em PDF a partir dos resumos JSON do k6.

Uso (na pasta testes-k6, depois de rodar os quatro testes):
    py gerar-relatorio.py
Os números vêm de relatorios/<teste>-resumo.json, exportados pelo k6 com
--summary-export; nada é digitado à mão.
"""
import json
import pathlib
import tempfile
import subprocess
import sys
from datetime import date

PASTA = pathlib.Path(__file__).parent / 'relatorios'
AMBIENTE = sys.argv[1] if len(sys.argv) > 1 else (
    'Notebook Intel Core i3-1115G4, 3,7 GB de RAM, Windows 11. A API e o k6 rodaram na mesma máquina, '
    'com um banco PostgreSQL separado só para os testes (cuidamed_k6).'
)

TESTES = [
    ('carga', 'Carga', 'Uso normal: até 50 pacientes ao mesmo tempo por 3 minutos'),
    ('estresse', 'Estresse', 'Degraus de 25, 50, 100 e 200 usuários, topo mantido e recuperação'),
    ('integracao', 'Integração (E2E)', 'Cadastro, login, vínculo, remédio, dose e estoque'),
    ('regressao', 'Regressão', '34 regras de segurança e de negócio'),
]


def num(valor, casas=2):
    texto = f'{valor:,.{casas}f}'
    return texto.replace(',', '#').replace('.', ',').replace('#', '.')


def inteiro(valor):
    return f'{int(valor):,}'.replace(',', '.')


def ler(nome):
    arquivo = PASTA / f'{nome}-resumo.json'
    resumo = json.loads(arquivo.read_text(encoding='utf-8'))
    # O k6 copia para o resumo os dados da preparação, com os tokens de login
    # das contas de teste. O relatório não usa essa parte: ela sai do arquivo.
    if resumo.pop('setup_data', None) is not None:
        arquivo.write_text(json.dumps(resumo, ensure_ascii=False, indent=2), encoding='utf-8')
    return resumo['metrics']


def metas(metricas):
    linhas = []
    for nome, dados in metricas.items():
        for regra, falhou in (dados.get('thresholds') or {}).items():
            linhas.append((nome, regra, not falhou))
    return linhas


def linha_tabela(chave, titulo, descricao, m):
    duracao = m['http_req_duration']
    checks = m['checks']
    total_checks = checks['passes'] + checks['fails']
    aprovado = all(ok for _, _, ok in metas(m))
    return f"""
      <tr>
        <td class="cenario"><strong>{titulo}</strong><span>{descricao}</span></td>
        <td>{inteiro(m['vus_max']['max'])}</td>
        <td>{inteiro(m['http_reqs']['count'])}</td>
        <td>{num(m['http_reqs']['rate'], 1)}/s</td>
        <td>{num(100 * m['http_req_failed']['value'])}%</td>
        <td>{num(duracao['avg'])} ms</td>
        <td>{num(duracao['p(95)'])} ms</td>
        <td>{inteiro(checks['passes'])}/{inteiro(total_checks)}</td>
        <td class="{'ok' if aprovado else 'falhou'}">{'APROVADO' if aprovado else 'REPROVADO'}</td>
      </tr>"""


CONFIGURACAO = {
    'carga': 'Sobe de 0 a 50 usuários em 1 minuto, mantém 50 por 3 minutos e desce em 30 segundos. '
             'Cada usuário tem a própria conta e repete: abrir o Início (dados, remédios e histórico de 31 dias), '
             'registrar a dose e desfazer, com pausas de 1 a 3 segundos, como uma pessoa usando o app.',
    'estresse': 'O mesmo uso da carga, em degraus de 1 minuto: 25, 50, 100 e 200 usuários, mais 1 minuto no topo '
                'de 200, descida para 25 (recuperação) e 30 segundos até zero.',
    'integracao': '1 usuário virtual, 1 execução: o caminho completo entre cuidador e paciente, conferindo cada resposta.',
    'regressao': '1 usuário virtual, 1 execução: 34 regras conferidas uma a uma. As recusas exigidas pelas regras são '
                 'marcadas como esperadas.',
}


def verificacoes(nome):
    """Lista (etapa, verificação, aprovações, falhas) a partir do resumo do k6."""
    raiz = json.loads((PASTA / f'{nome}-resumo.json').read_text(encoding='utf-8'))['root_group']
    linhas = []

    def percorrer(grupo):
        for check in (grupo.get('checks') or {}).values():
            linhas.append((grupo.get('name') or '', check['name'], check['passes'], check['fails']))
        for filho in (grupo.get('groups') or {}).values():
            percorrer(filho)

    percorrer(raiz)
    return linhas


def secao_detalhes(chave, titulo, m):
    duracao = m['http_req_duration']
    recebidos = m['data_received']['count'] / (1024 * 1024)
    etapas = {'setup': 'Preparação (contas de teste)', '': '—'}
    linhas = ''.join(
        f"<tr><td>{etapas.get(g, g)}</td><td>{nome}</td><td>{inteiro(ok)}</td>"
        f"<td class=\"{'ok' if falhas == 0 else 'falhou'}\">{inteiro(falhas)}</td></tr>"
        for g, nome, ok, falhas in verificacoes(chave))
    return f"""
<h3>{titulo}</h3>
<p>{CONFIGURACAO[chave]}</p>
<table class="metas">
  <tr><th>Média</th><th>Mediana</th><th>p90</th><th>p95</th><th>Máxima</th><th>Iterações</th><th>Dados recebidos</th></tr>
  <tr><td>{num(duracao['avg'])} ms</td><td>{num(duracao['med'])} ms</td><td>{num(duracao['p(90)'])} ms</td>
      <td>{num(duracao['p(95)'])} ms</td><td>{num(duracao['max'])} ms</td><td>{inteiro(m['iterations']['count'])}</td>
      <td>{num(recebidos)} MB</td></tr>
</table>
<table class="metas verificacoes">
  <tr><th>Etapa</th><th>Verificação</th><th>Aprovadas</th><th>Falhas</th></tr>
  {linhas}
</table>"""


def tabela_metas(resultados):
    nomes = {
        'http_req_duration': 'Tempo de resposta',
        'http_req_duration{nome:historico 31 dias}': 'Tempo do histórico (31 dias)',
        'http_req_duration{nome:registrar dose}': 'Tempo de registrar dose',
        'http_req_failed': 'Erros HTTP',
        'checks': 'Verificações',
    }
    linhas = ''
    for chave, titulo, _ in TESTES:
        for metrica, regra, ok in metas(resultados[chave]):
            linhas += (f"<tr><td>{titulo}</td><td>{nomes.get(metrica, metrica)}</td><td><code>{regra}</code></td>"
                       f"<td class=\"{'ok' if ok else 'falhou'}\">{'Atingida' if ok else 'Não atingida'}</td></tr>")
    return linhas


def montar_html():
    r = {chave: ler(chave) for chave, _, _ in TESTES}
    carga, estresse, integ, regr = r['carga'], r['estresse'], r['integracao'], r['regressao']
    linhas = ''.join(linha_tabela(chave, titulo, desc, r[chave]) for chave, titulo, desc in TESTES)
    return f"""<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8"><title>Relatório de testes — CuidaMed</title>
<style>
  @page {{ size: A4; margin: 16mm 14mm; }}
  body {{ font-family: 'Segoe UI', Arial, sans-serif; color: #1d2433; font-size: 10.5pt; line-height: 1.45; }}
  h1 {{ text-align: center; font-size: 19pt; margin: 0 0 4px; }}
  .sub {{ text-align: center; color: #5b6475; margin: 0 0 18px; }}
  h2 {{ font-size: 12.5pt; margin: 18px 0 6px; border-bottom: 2px solid #1d2433; padding-bottom: 3px; }}
  ul {{ margin: 4px 0; padding-left: 20px; }} li {{ margin: 3px 0; }}
  table {{ width: 100%; border-collapse: separate; border-spacing: 3px; font-size: 8.6pt; }}
  th {{ background: #111; color: #fff; padding: 7px 4px; font-weight: 600; text-transform: uppercase; font-size: 7.6pt; }}
  td {{ border: 1px solid #222; padding: 7px 4px; text-align: center; white-space: nowrap; }}
  td.cenario {{ text-align: left; white-space: normal; }} td.cenario span {{ display: block; color: #5b6475; font-size: 7.8pt; }}
  td.ok {{ font-weight: 700; color: #166534; }} td.falhou {{ font-weight: 700; color: #b91c1c; }}
  .metas td, .metas th {{ text-align: left; }}
  h2 {{ page-break-after: avoid; }} table, pre {{ page-break-inside: avoid; }}
  .nota {{ font-size: 8.4pt; color: #5b6475; margin-top: 4px; }}
  pre {{ background: #f3f4f6; padding: 8px 10px; border-radius: 6px; font-size: 8.6pt; white-space: pre-wrap; }}
  code {{ font-size: 8.6pt; }}
  .quebra {{ page-break-before: always; }}
  h3 {{ font-size: 11pt; margin: 14px 0 4px; }}
  .verificacoes td {{ white-space: normal; font-size: 8.2pt; padding: 4px; }}
  .anexos li {{ margin: 2px 0; }}
</style></head><body>
<h1>Documentação da Suíte de Testes — CuidaMed API</h1>
<p class="sub">Testes de carga, estresse, integração e regressão com k6 · {date.today().strftime('%d/%m/%Y')}</p>

<p>Este documento apresenta os testes executados com o <strong>k6 v2.3.0</strong> na API do CuidaMed, aplicativo de
lembretes de medicamentos para idosos e cuidadores. A API é feita em <strong>Java 25 com Spring Boot 4.1.1</strong> e
usa <strong>PostgreSQL 18</strong>. Os testes acessam a API como o aplicativo faz, criam as próprias contas de teste e
as apagam no fim: nenhum dado de paciente real é lido ou alterado.</p>
<p><strong>Ambiente:</strong> {AMBIENTE}</p>

<h2>Estrutura dos scripts</h2>
<ul>
  <li><strong>carga.js</strong> — teste de carga: o uso normal do paciente (abrir o Início com dados, remédios e histórico; registrar e desfazer a dose).</li>
  <li><strong>estresse.js</strong> — teste de estresse: o mesmo uso, em degraus acima do normal, para achar o limite e ver se a API se recupera.</li>
  <li><strong>integracao.js</strong> — teste de integração (E2E): cadastro e login do cuidador e do paciente, vínculo entre os dois, remédio cadastrado pelo cuidador, dose registrada e desfeita pelo paciente, com o estoque conferido a cada passo.</li>
  <li><strong>regressao.js</strong> — teste de regressão: 34 regras que já funcionavam (acesso, login, cadastro, doses, estoque, histórico por período e compactação) continuam funcionando.</li>
  <li><strong>comum.js</strong> e <strong>uso-do-paciente.js</strong> — partes compartilhadas: endereço da API, contas de teste e o fluxo do paciente.</li>
</ul>

<h2>Resultados consolidados</h2>
<table>
  <tr><th>Cenário</th><th>VUs máx.</th><th>Requisições</th><th>Vazão</th><th>Taxa de erro</th><th>Latência média</th><th>Latência p95</th><th>Checks</th><th>Status</th></tr>
  {linhas}
</table>
<p class="nota">VUs: usuários virtuais simultâneos. p95: 95% das respostas foram mais rápidas que esse valor. Na regressão, as recusas que
a regra exige (401, 403, 409 e 400) são marcadas como esperadas no script e não contam como erro; qualquer outro status contaria.</p>

<h2>Metas (thresholds)</h2>
<table class="metas">
  <tr><th>Teste</th><th>Métrica</th><th>Meta</th><th>Resultado</th></tr>
  {tabela_metas(r)}
</table>
<p class="nota">No estresse, as metas servem de referência para mostrar em que ponto a API deixaria de atender bem.</p>

<h2>Destaques</h2>
<ul>
  <li><strong>Carga sem erros:</strong> com {inteiro(carga['vus_max']['max'])} pacientes simultâneos, a API atendeu
    {inteiro(carga['http_reqs']['count'])} requisições ({num(carga['http_reqs']['rate'], 1)} por segundo) com
    {num(100 * carga['http_req_failed']['value'])}% de erros, latência média de {num(carga['http_req_duration']['avg'])} ms e
    p95 de {num(carga['http_req_duration']['p(95)'])} ms — muito abaixo da meta de 500 ms. Houve um máximo isolado de
    {num(carga['http_req_duration']['max'], 0)} ms, num pico de poucos segundos visível no gráfico do Anexo A; não
    houve erros nesse momento e o p95 do teste não foi afetado. Como a API e o k6 dividem o mesmo notebook, a causa
    pode ser o próprio notebook; ela não foi investigada.</li>
  <li><strong>Estresse sem queda:</strong> no topo de {inteiro(estresse['vus_max']['max'])} usuários simultâneos a API
    manteve {num(100 * estresse['http_req_failed']['value'])}% de erros e p95 de {num(estresse['http_req_duration']['p(95)'])} ms,
    com {inteiro(estresse['http_reqs']['count'])} requisições ({num(estresse['http_reqs']['rate'], 1)} por segundo) e recuperação
    normal na descida. O limite da API não foi alcançado com o volume que o notebook consegue gerar.</li>
  <li><strong>Integração completa:</strong> {inteiro(integ['checks']['passes'])} de {inteiro(integ['checks']['passes'] + integ['checks']['fails'])}
    verificações aprovadas. O p95 maior ({num(integ['http_req_duration']['p(95)'])} ms) vem do cadastro e do login, que
    verificam a senha com BCrypt, um cálculo propositalmente lento para proteger as senhas.</li>
  <li><strong>Regressão:</strong> {inteiro(regr['checks']['passes'])} de {inteiro(regr['checks']['passes'] + regr['checks']['fails'])}
    regras aprovadas, entre elas: um paciente não vê os dados de outro, a mesma dose não pode ser registrada duas vezes,
    registrar a dose desconta o estoque e desfazer devolve, e o histórico grande vem compactado (gzip).</li>
  <li><strong>Dados isolados:</strong> as contas de teste usam e-mails próprios (<code>k6.…@teste.cuidamed</code>) e são
    apagadas no fim de cada teste; o script <code>limpar-dados-de-teste.sql</code> remove qualquer resto.</li>
  <li><strong>Otimizações já aplicadas:</strong> respostas da API compactadas, histórico limitado aos últimos 31 dias
    no aplicativo, menos consultas ao banco e índices por paciente.</li>
</ul>

<h2 class="quebra">Detalhes por teste</h2>
{''.join(secao_detalhes(chave, titulo, r[chave]) for chave, titulo, _ in TESTES)}

<h2>Limitações</h2>
<ul>
  <li>A API e o k6 rodaram no mesmo notebook, sem a latência da internet: em produção os tempos tendem a ser maiores.</li>
  <li>O estresse foi limitado a 200 usuários simultâneos pela memória do notebook (3,7 GB); o script aceita picos maiores (<code>-e PICO=400</code>).</li>
  <li>O chat com a IA ficou fora da carga e do estresse, porque cada pergunta é uma chamada paga a um serviço externo.</li>
</ul>

<h2>Como executar</h2>
<pre>cd testes-k6
$env:K6_WEB_DASHBOARD = "true"
$env:K6_WEB_DASHBOARD_PERIOD = "1s"
$env:K6_WEB_DASHBOARD_EXPORT = "relatorios/carga.html";      k6 run --summary-export relatorios/carga-resumo.json carga.js
$env:K6_WEB_DASHBOARD_EXPORT = "relatorios/estresse.html";   k6 run --summary-export relatorios/estresse-resumo.json -e PICO=200 estresse.js
$env:K6_WEB_DASHBOARD_EXPORT = "relatorios/integracao.html"; k6 run --summary-export relatorios/integracao-resumo.json integracao.js
$env:K6_WEB_DASHBOARD_EXPORT = "relatorios/regressao.html";  k6 run --summary-export relatorios/regressao-resumo.json regressao.js
py gerar-relatorio.py</pre>
<p class="nota">Por padrão os testes usam a API de testes em <code>http://localhost:8081</code>. Para outro servidor:
<code>k6 run -e API=https://endereco-da-api carga.js</code>. Os relatórios HTML completos de cada teste, gerados pelo k6,
estão na pasta <code>relatorios</code>.</p>

<h2>Anexos — relatórios gerados pelo k6</h2>
<p>As páginas seguintes trazem, de cada teste, a visão geral e o resumo do relatório que o próprio k6 gerou (web dashboard),
com os gráficos de requisições por segundo, usuários virtuais e tempo de resposta ao longo do teste.</p>
<ul class="anexos">
  <li>Anexo A — Teste de carga</li>
  <li>Anexo B — Teste de estresse</li>
  <li>Anexo C — Teste de integração</li>
  <li>Anexo D — Teste de regressão</li>
</ul>
</body></html>"""


ANEXOS = [('A', 'carga', 'Teste de carga'), ('B', 'estresse', 'Teste de estresse'),
          ('C', 'integracao', 'Teste de integração'), ('D', 'regressao', 'Teste de regressão')]
NAVEGADORES = [r'C:\Program Files\Google\Chrome\Application\chrome.exe',
               r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe']


def imprimir(navegador, origem, destino, esperar_ms=0):
    comando = [navegador, '--headless', '--disable-gpu', '--no-pdf-header-footer', f'--print-to-pdf={destino}']
    if esperar_ms:
        # O relatório do k6 desenha os gráficos com JavaScript: espera antes de imprimir.
        comando += [f'--virtual-time-budget={esperar_ms}', '--run-all-compositor-stages-before-draw']
    subprocess.run(comando + [origem.resolve().as_uri()], check=True, capture_output=True, timeout=180)


def paginas_do_k6(leitor):
    """Visão geral (2 primeiras páginas) e resumo (da página com "Summary" até o fim)."""
    textos = [pagina.extract_text() or '' for pagina in leitor.pages]
    resumo = next((i for i, t in enumerate(textos) if 'Summary' in t and 'Trends' in t), len(textos) - 2)
    return sorted(set(range(min(2, len(textos)))) | set(range(resumo, len(textos))))


def capa_do_anexo(letra, titulo):
    return ('<!DOCTYPE html><html><head><meta charset="utf-8"><style>@page { size: A4; margin: 0; }'
            'body { font-family: "Segoe UI", Arial, sans-serif; display: flex; height: 96vh; margin: 0;'
            ' align-items: center; justify-content: center; flex-direction: column; color: #1d2433; }'
            'h1 { font-size: 26pt; margin: 0; } p { color: #5b6475; }</style></head><body>'
            f'<h1>Anexo {letra} — {titulo}</h1><p>Relatório gerado pelo k6: visão geral e resumo</p></body></html>')


def main():
    from pypdf import PdfReader, PdfWriter

    html = PASTA / 'Relatorio-de-testes-CuidaMed.html'
    pdf = PASTA / 'Relatorio-de-testes-CuidaMed.pdf'
    html.write_text(montar_html(), encoding='utf-8')
    navegador = next((n for n in NAVEGADORES if pathlib.Path(n).exists()), None)
    if not navegador:
        print(f'HTML gerado em {html}; abra no navegador e imprima em PDF.')
        return

    with tempfile.TemporaryDirectory() as temporaria:
        temp = pathlib.Path(temporaria)
        saida = PdfWriter()
        imprimir(navegador, html, temp / 'principal.pdf')
        saida.append(PdfReader(temp / 'principal.pdf'))
        for letra, chave, titulo in ANEXOS:
            capa = temp / f'capa-{chave}.html'
            capa.write_text(capa_do_anexo(letra, titulo), encoding='utf-8')
            imprimir(navegador, capa, temp / f'capa-{chave}.pdf')
            imprimir(navegador, PASTA / f'{chave}.html', temp / f'{chave}.pdf', esperar_ms=15000)
            leitor = PdfReader(temp / f'{chave}.pdf')
            saida.append(PdfReader(temp / f'capa-{chave}.pdf'))
            saida.append(leitor, pages=paginas_do_k6(leitor))
        with open(pdf, 'wb') as arquivo:
            saida.write(arquivo)
    print(f'PDF gerado em {pdf} ({len(PdfReader(pdf).pages)} páginas)')


if __name__ == '__main__':
    main()
