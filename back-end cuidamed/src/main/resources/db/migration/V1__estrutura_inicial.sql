-- CuidaMed - V1: estrutura inicial do banco (antigo database/schema.sql).
--
-- Aplicada pelo Flyway ao subir o servidor num banco vazio (ex.: Railway). No
-- banco local, que já tinha essas tabelas, ela é marcada como aplicada sem
-- rodar (baseline). Não edite este arquivo: mudanças de estrutura entram
-- como uma nova migração (V2__..., V3__...).
--
-- Convenção de nomenclatura: tabelas no singular; toda coluna leva um sufixo
-- abreviando a tabela dona (_cui, _pac, _med, _hor, _hist).

-- ============================================================
-- cuidador
-- ============================================================
CREATE TABLE cuidador (
    id_cui        BIGSERIAL PRIMARY KEY,
    nome_cui      VARCHAR(150) NOT NULL,
    email_cui     VARCHAR(150) NOT NULL,
    senha_cui     VARCHAR(255) NOT NULL,
    profissao_cui VARCHAR(100),
    telefone_cui  VARCHAR(20),
    criadoem_cui  TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT uq_cuidador_email UNIQUE (email_cui)
);

-- ============================================================
-- paciente
-- ============================================================
CREATE TABLE paciente (
    id_pac                     BIGSERIAL PRIMARY KEY,
    cuidador_id_pac            BIGINT,
    cuidador_solicitado_id_pac BIGINT,
    nome_pac                   VARCHAR(150) NOT NULL,
    email_pac                  VARCHAR(150),
    senha_pac                  VARCHAR(255),
    datanascimento_pac         DATE,
    sexo_pac                   VARCHAR(20),
    enfermidade_pac            VARCHAR(255),
    telefone_pac               VARCHAR(20),
    endereco_pac               VARCHAR(255),
    observacoesclinicas_pac    TEXT,
    alertamanualpendente_pac   BOOLEAN NOT NULL DEFAULT FALSE,
    alertamanualmensagem_pac   VARCHAR(255),
    permitealteracoes_pac      BOOLEAN NOT NULL DEFAULT FALSE,
    criadoem_pac               TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT uq_paciente_email UNIQUE (email_pac),
    CONSTRAINT ck_paciente_sexo CHECK (sexo_pac IN ('FEMININO', 'MASCULINO', 'OUTRO')),
    CONSTRAINT fk_paciente_cuidador FOREIGN KEY (cuidador_id_pac)
        REFERENCES cuidador (id_cui) ON DELETE SET NULL,
    CONSTRAINT fk_paciente_cuidador_solicitado FOREIGN KEY (cuidador_solicitado_id_pac)
        REFERENCES cuidador (id_cui) ON DELETE SET NULL
);

-- ============================================================
-- medicamento
-- ============================================================
CREATE TABLE medicamento (
    id_med          BIGSERIAL PRIMARY KEY,
    paciente_id_med BIGINT NOT NULL,
    nome_med        VARCHAR(150) NOT NULL,
    dosagem_med     VARCHAR(50) NOT NULL,
    forma_med       VARCHAR(20) NOT NULL,
    frequencia_med  VARCHAR(30) NOT NULL,
    datainicio_med  DATE NOT NULL,
    datafim_med     DATE,
    observacoes_med TEXT,
    quantidadeestoque_med INTEGER,
    quantidadepordose_med INTEGER,
    criadoem_med    TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT ck_medicamento_forma CHECK (
        forma_med IN ('COMPRIMIDO', 'CAPSULA', 'GOTA', 'XAROPE', 'INJECAO', 'POMADA')
    ),
    CONSTRAINT ck_medicamento_frequencia CHECK (
        frequencia_med IN (
            'UMA_VEZ_AO_DIA', 'DUAS_VEZES_AO_DIA', 'TRES_VEZES_AO_DIA',
            'A_CADA_8_HORAS', 'DIAS_ALTERNADOS', 'SEMANAL'
        )
    ),
    CONSTRAINT fk_medicamento_paciente FOREIGN KEY (paciente_id_med)
        REFERENCES paciente (id_pac) ON DELETE CASCADE
);

-- ============================================================
-- horario (um medicamento pode ter várias doses diárias)
-- ============================================================
CREATE TABLE horario (
    id_hor             BIGSERIAL PRIMARY KEY,
    medicamento_id_hor BIGINT NOT NULL,
    hora_hor           TIME NOT NULL,

    CONSTRAINT uq_horario_medicamento_hora UNIQUE (medicamento_id_hor, hora_hor),
    CONSTRAINT fk_horario_medicamento FOREIGN KEY (medicamento_id_hor)
        REFERENCES medicamento (id_med) ON DELETE CASCADE
);

-- ============================================================
-- historico (vinculado a paciente e medicamento; guarda snapshot de
-- nome/dosagem para preservar o registro mesmo se o medicamento mudar depois)
-- ============================================================
CREATE TABLE historico (
    id_hist              BIGSERIAL PRIMARY KEY,
    paciente_id_hist     BIGINT NOT NULL,
    medicamento_id_hist  BIGINT NOT NULL,
    data_hist            DATE NOT NULL,
    hora_hist            TIME NOT NULL,
    nomemedicamento_hist VARCHAR(150) NOT NULL,
    dosagem_hist         VARCHAR(50) NOT NULL,
    status_hist          VARCHAR(20) NOT NULL,
    criadoem_hist        TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT uq_historico_medicamento_data_hora UNIQUE (medicamento_id_hist, data_hist, hora_hist),
    CONSTRAINT ck_historico_status CHECK (status_hist IN ('TOMADO', 'ATRASADO', 'PERDIDO')),
    CONSTRAINT fk_historico_paciente FOREIGN KEY (paciente_id_hist)
        REFERENCES paciente (id_pac) ON DELETE CASCADE,
    CONSTRAINT fk_historico_medicamento FOREIGN KEY (medicamento_id_hist)
        REFERENCES medicamento (id_med) ON DELETE CASCADE
);
