-- Vínculos entre paciente e cuidador em tabela própria, com histórico.
--
-- Antes, o paciente guardava o cuidador atual (cuidador_id_pac) e um pedido
-- pendente (cuidador_solicitado_id_pac); ao desvincular, não sobrava registro
-- de quem cuidou, nem de quando a quando. Agora cada vínculo é uma linha:
--   PENDENTE  -> pedido do paciente aguardando o cuidador
--   ATIVO     -> vínculo em vigor (o id é o "nº do cartão" do paciente)
--   RECUSADO  -> pedido recusado pelo cuidador
--   CANCELADO -> pedido substituído por outro antes da resposta
--   ENCERRADO -> vínculo desfeito pelo cuidador
-- Regra: um paciente tem no máximo um vínculo ATIVO e um pedido PENDENTE.

CREATE TABLE pacientecuidador (
    id_pcu           BIGSERIAL PRIMARY KEY,
    paciente_id_pcu  BIGINT NOT NULL,
    cuidador_id_pcu  BIGINT NOT NULL,
    situacao_pcu     VARCHAR(20) NOT NULL,
    solicitadoem_pcu TIMESTAMP,
    iniciadoem_pcu   TIMESTAMP,
    encerradoem_pcu  TIMESTAMP,
    criadoem_pcu     TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT ck_pacientecuidador_situacao CHECK (
        situacao_pcu IN ('PENDENTE', 'ATIVO', 'RECUSADO', 'CANCELADO', 'ENCERRADO')
    ),
    CONSTRAINT fk_pacientecuidador_paciente FOREIGN KEY (paciente_id_pcu)
        REFERENCES paciente (id_pac) ON DELETE CASCADE,
    CONSTRAINT fk_pacientecuidador_cuidador FOREIGN KEY (cuidador_id_pcu)
        REFERENCES cuidador (id_cui) ON DELETE CASCADE
);

CREATE UNIQUE INDEX uq_pacientecuidador_um_ativo
    ON pacientecuidador (paciente_id_pcu) WHERE situacao_pcu = 'ATIVO';
CREATE UNIQUE INDEX uq_pacientecuidador_um_pendente
    ON pacientecuidador (paciente_id_pcu) WHERE situacao_pcu = 'PENDENTE';
CREATE INDEX ix_pacientecuidador_cuidador
    ON pacientecuidador (cuidador_id_pcu, situacao_pcu);

-- Copia os vínculos e pedidos que já existiam (a data exata do início não era
-- registrada antes; fica a do momento da migração).
INSERT INTO pacientecuidador (paciente_id_pcu, cuidador_id_pcu, situacao_pcu, iniciadoem_pcu)
SELECT id_pac, cuidador_id_pac, 'ATIVO', now()
FROM paciente
WHERE cuidador_id_pac IS NOT NULL;

INSERT INTO pacientecuidador (paciente_id_pcu, cuidador_id_pcu, situacao_pcu, solicitadoem_pcu)
SELECT id_pac, cuidador_solicitado_id_pac, 'PENDENTE', now()
FROM paciente
WHERE cuidador_solicitado_id_pac IS NOT NULL;

ALTER TABLE paciente DROP COLUMN cuidador_id_pac;
ALTER TABLE paciente DROP COLUMN cuidador_solicitado_id_pac;
