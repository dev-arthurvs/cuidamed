# CuidaMed

App de lembretes e acompanhamento de medicamentos para idosos (pacientes) e
seus cuidadores. Três projetos na mesma pasta, todos com código, nomes e
comentários em português:

| Pasta | O quê | Rodar no PC |
|---|---|---|
| `back-end cuidamed` | API Spring Boot 4.1.1, Java 25, PostgreSQL 18 | `.\mvnw.cmd spring-boot:run` (porta 8080) |
| `front-end cuidamed` | Web React + Vite | `npm run dev` (porta 5173) |
| `mobile cuidamed` | App Flutter (Android e Chrome) | F5 no VS Code ou `flutter run -d chrome --web-port 5050 --dart-define=API_BASE_URL=http://localhost:8080` |

Repositório: https://github.com/dev-arthurvs/cuidamed (privado, branch `main`).

## Regras do projeto

- **Web e mobile andam juntos**: toda mudança de tela ou regra feita num app
  vale para o outro. O web é a referência visual.
- **Interface minimalista**: sem textos explicando a finalidade da tela (o guia
  "?" cobre isso); mensagens curtas.
- **Banco**: a estrutura muda só por migração Flyway nova em
  `back-end cuidamed/src/main/resources/db/migration` (V3, V4...). Nunca editar
  V1/V2 nem alterar tabelas à mão. Dados podem ser editados no pgAdmin.
- **Segredos** ficam em `back-end cuidamed/.env` (fora do Git) ou nas variáveis
  do Railway. Os `.env.example` listam os nomes sem valores.

## Doses

- Dose sem registro é calculada na tela, sem gravar nada: atrasada de 15 min a
  3 h, perdida depois disso. Início, Histórico, adesão e relatório usam a mesma
  regra (`dosesSemRegistro` em `horarios.js`/`horarios.dart`). O chat tem a mesma
  regra em Java (`chat/ContextoDoChat.java`), com a hora de Brasília: mudou a regra,
  mude nos três.
- Web e mobile guardam só 31 dias de histórico (`inicioJanelaHistorico`); a tela de
  Histórico busca período mais antigo com `?de=&ate=` e não calcula nada até chegar.
- Registro de hoje pode ser desfeito (`DELETE /api/historicos/{id}`), o que devolve
  o estoque.
- O chat ensina a usar o app pelo guia `back-end cuidamed/src/main/resources/chat/guia-do-paciente.txt`:
  mudou tela ou botão do paciente, atualize esse guia junto com o `ajudaConteudo`.
- Lembretes com o app fechado: só no Android/iOS, agendados no aparelho
  (`estado/lembretes_agendados.dart`). No navegador só tocam com a página aberta.
  O aviso de dose atrasada ao cuidador só sai com o app aberto; não há push.

## Segurança (não afrouxar)

- Login por e-mail **ou telefone** (`conta/Contato.java`; o telefone compara só
  os dígitos). E-mail é opcional ("Não tenho e-mail" nos cadastros); conta com
  senha precisa de um dos dois, e o telefone é único entre pacientes e cuidadores
  (`conta/VerificadorDeContato.java`, regra na API, não no banco).
- Login gera um JWT (7 dias), enviado como `Authorization: Bearer`. Rotas
  públicas: login, cadastro (`POST /api/cuidadores`, `POST /api/pacientes`),
  `POST /api/pacientes/definir-senha` e `GET /actuator/health`.
- `seguranca/Autorizacao.java`: o paciente acessa só os próprios dados; o
  cuidador, só os pacientes vinculados. O vínculo fica na tabela
  `pacientecuidador` (pacote `vinculo`), com histórico: PENDENTE → ATIVO →
  ENCERRADO (ou RECUSADO/CANCELADO); no máximo um ATIVO e um PENDENTE por
  paciente. O id do vínculo ativo é o "nº do cartão" do paciente. Os controllers usam o id do token e
  ignoram o `cuidadorId` enviado no corpo.
- Remédios: o cuidador vinculado altera; o paciente só se `permiteAlteracoes`
  estiver ligado (ou se não tiver cuidador).
- "Ativar meu acesso" exige e-mail ou telefone + código de ativação (o cuidador vê o código
  nos detalhes do paciente).
- "Esqueci minha senha": o cuidador vinculado gera um código de nova senha
  (`POST /api/pacientes/{id}/codigo-nova-senha`, vale 24 horas). O paciente usa na
  mesma tela de "Ativar meu acesso". Quem não tem cuidador ainda não tem saída.
- Sessão: sai sozinho após 30 min sem uso no web e 7 dias no mobile, a não ser
  com "Lembrar de mim".
- `seguranca/LimitadorDeTentativas.java`: limites por conta (login, ativação,
  chat), não por IP.

## Testes

- Back-end: `.\mvnw.cmd test` (precisa do PostgreSQL local; não altera dados).
- Web: `npx eslint src` e `npx vite build` (não há testes automatizados).
- Mobile: `flutter analyze` e `flutter test test/<arquivo>_test.dart`, um ou
  poucos arquivos por vez (o PC tem pouca memória); nunca durante uma depuração.
- Integração contra o back-end rodando:
  `flutter test test/integracao --dart-define=API_BASE_URL=http://localhost:8080`.

## Ambiente (Windows + OneDrive)

- O OneDrive marca pastas como somente leitura e trava builds: `mobile
  cuidamed/build` e `mobile cuidamed/.dart_tool` são atalhos (junctions) para
  `%LOCALAPPDATA%\CuidaMed\...`. A tarefa `.vscode/liberar-build.ps1` roda antes
  de cada F5.
- Abrir a pasta como `CuidaMed` (com essa caixa) no VS Code; aberta como
  `cuidamed`, os breakpoints do Flutter web podem não parar.
