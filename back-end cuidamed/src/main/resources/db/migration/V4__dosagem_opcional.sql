-- A dosagem saiu do formulário de medicamento (web e mobile): passa a ser
-- opcional. Remédios já cadastrados mantêm a dosagem que tinham; o histórico
-- copia a do medicamento, então também precisa aceitar vazio.
ALTER TABLE medicamento ALTER COLUMN dosagem_med DROP NOT NULL;
ALTER TABLE historico ALTER COLUMN dosagem_hist DROP NOT NULL;
