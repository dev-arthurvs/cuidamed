# Testes de desempenho e de API do CuidaMed (k6)

Quatro testes, feitos com o [k6](https://k6.io): carga, estresse, integração e
regressão. Os testes falam com a API do mesmo jeito que o app: criam as
próprias contas de teste (e-mails `k6.…@teste.cuidamed`) e as apagam no fim.
Nenhum dado de paciente real é lido ou alterado. O chat com a IA fica fora da
carga e do estresse, pois cada pergunta é uma chamada paga.

| Arquivo | Tipo | O que verifica |
|---|---|---|
| `carga.js` | Carga | Até 50 pacientes ao mesmo tempo por alguns minutos. Meta: 95% das respostas abaixo de 500 ms e menos de 1% de erros |
| `estresse.js` | Estresse | Sobe em degraus até 400 usuários e desce. Mostra o limite do servidor e se ele se recupera |
| `integracao.js` | Integração | Caminho completo: cadastro, login, vínculo paciente–cuidador, remédio, registrar e desfazer dose, estoque |
| `regressao.js` | Regressão | Regras de segurança e de negócio: acessos, login, cadastro, doses, estoque, histórico por período e compactação |

`comum.js` e `uso-do-paciente.js` são as partes compartilhadas.

## Como rodar

Gera o relatório HTML do k6 na pasta `relatorios`:

```powershell
cd testes-k6
$env:K6_WEB_DASHBOARD = "true"
$env:K6_WEB_DASHBOARD_PERIOD = "1s"   # sem isso, o k6 não gera o HTML de testes curtos

$env:K6_WEB_DASHBOARD_EXPORT = "relatorios/carga.html";      k6 run --summary-export relatorios/carga-resumo.json carga.js
$env:K6_WEB_DASHBOARD_EXPORT = "relatorios/estresse.html";   k6 run --summary-export relatorios/estresse-resumo.json -e PICO=200 estresse.js
$env:K6_WEB_DASHBOARD_EXPORT = "relatorios/integracao.html"; k6 run --summary-export relatorios/integracao-resumo.json integracao.js
$env:K6_WEB_DASHBOARD_EXPORT = "relatorios/regressao.html";  k6 run --summary-export relatorios/regressao-resumo.json regressao.js

# Relatório em PDF, com os números dos resumos acima:
py gerar-relatorio.py
```

O relatório final fica em `relatorios/Relatorio-de-testes-CuidaMed.pdf`.
O gerador também apaga dos resumos JSON os tokens de login das contas de teste,
que o k6 grava junto: rode-o antes de enviar a pasta para o GitHub.

Por padrão os testes usam a API de testes no PC (`http://localhost:8081`,
banco `cuidamed_k6`). Para outro servidor, passe o endereço:

```powershell
k6 run -e API=https://endereco-da-api carga.js
```

Ajustes opcionais:

| Teste | Parâmetro | Padrão |
|---|---|---|
| Carga | `-e USUARIOS=50` / `-e MANTER=3m` | 50 usuários por 3 minutos |
| Estresse | `-e PICO=400` / `-e DEGRAU=1m` | Pico de 400, degraus de 1 minuto |

## Limpeza

Os testes apagam os pacientes que criam. Ficam só os cuidadores de teste, pois
a API não tem exclusão de cuidador. Para apagar tudo o que os testes deixaram,
rode `limpar-dados-de-teste.sql` no pgAdmin, no banco testado: ele apaga só os
e-mails `k6.…@teste.cuidamed`.
