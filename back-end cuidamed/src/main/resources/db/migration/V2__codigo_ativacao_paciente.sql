-- Código de ativação do paciente cadastrado pelo cuidador (sem senha).
-- O cuidador vê o código nos detalhes do paciente e o repassa a ele; o
-- "Ativar meu acesso" exige e-mail + código. Apagado quando o acesso é ativado.
-- Antes, bastava saber o e-mail do paciente para definir a senha dele.
ALTER TABLE paciente ADD COLUMN codigoativacao_pac VARCHAR(12);

-- Pacientes que já estavam aguardando ativação ganham um código agora.
UPDATE paciente
SET codigoativacao_pac = upper(substr(md5(random()::text || id_pac::text), 1, 6))
WHERE senha_pac IS NULL;
