-- Recuperação de senha: o cuidador gera um código para o paciente criar uma
-- senha nova. Como a conta já tem senha, esse código vale só por um tempo. O
-- código de ativação de quem ainda não tem senha continua sem validade (nulo).
ALTER TABLE paciente ADD COLUMN codigoexpiraem_pac TIMESTAMP;
