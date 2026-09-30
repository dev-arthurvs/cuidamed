package com.cuidamed.cuidamed_backend.historico;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public record HistoricoRespostaDTO(
        Long id,
        Long pacienteId,
        Long medicamentoId,
        LocalDate data,
        String hora,
        String nomeMedicamento,
        String dosagem,
        StatusHistorico status,
        LocalDateTime criadoEm) {

    private static final DateTimeFormatter FORMATO_HORA = DateTimeFormatter.ofPattern("HH:mm");

    public static HistoricoRespostaDTO paraDTO(Historico historico) {
        return new HistoricoRespostaDTO(
                historico.getId(),
                historico.getPaciente().getId(),
                historico.getMedicamento().getId(),
                historico.getData(),
                historico.getHora().format(FORMATO_HORA),
                historico.getNomeMedicamento(),
                historico.getDosagem(),
                historico.getStatus(),
                historico.getCriadoEm());
    }
}
