-- Apaga só as contas criadas pelos testes do k6 (e-mails k6.…@teste.cuidamed).
-- Contas de pessoas reais não são tocadas. Rode no pgAdmin, no banco testado.
-- Remédios e doses dos pacientes de teste saem junto (ON DELETE CASCADE).
BEGIN;

DELETE FROM paciente WHERE email_pac LIKE 'k6.%@teste.cuidamed';

DELETE FROM pacientecuidador
WHERE cuidador_id_pcu IN (SELECT id_cui FROM cuidador WHERE email_cui LIKE 'k6.%@teste.cuidamed');

DELETE FROM cuidador WHERE email_cui LIKE 'k6.%@teste.cuidamed';

COMMIT;
