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

## Segurança (não afrouxar)

- Login gera um JWT (7 dias), enviado como `Authorization: Bearer`. Rotas
  públicas: login, cadastro (`POST /api/cuidadores`, `POST /api/pacientes`),
  `POST /api/pacientes/definir-senha` e `GET /actuator/health`.
- `seguranca/Autorizacao.java`: o paciente acessa só os próprios dados; o
  cuidador, só os pacientes vinculados. Os controllers usam o id do token e
  ignoram o `cuidadorId` enviado no corpo.
- Remédios: o cuidador vinculado altera; o paciente só se `permiteAlteracoes`
  estiver ligado (ou se não tiver cuidador).
- "Ativar meu acesso" exige e-mail + código de ativação (o cuidador vê o código
  nos detalhes do paciente).
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
