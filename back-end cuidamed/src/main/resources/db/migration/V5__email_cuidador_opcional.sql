-- Login por e-mail OU telefone: o e-mail deixou de ser obrigatório (muitos
-- idosos não têm). O do paciente já era opcional; agora o do cuidador também.
-- Continua único quando informado (o Postgres aceita vários nulos).
ALTER TABLE cuidador ALTER COLUMN email_cui DROP NOT NULL;
