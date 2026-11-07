-- Buscas por paciente, as mais frequentes do app (Início, Histórico, chat).
CREATE INDEX ix_historico_paciente_data ON historico (paciente_id_hist, data_hist DESC, hora_hist DESC);
CREATE INDEX ix_medicamento_paciente ON medicamento (paciente_id_med);
