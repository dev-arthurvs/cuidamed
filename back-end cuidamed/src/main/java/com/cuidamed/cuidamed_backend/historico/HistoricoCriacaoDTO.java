package com.cuidamed.cuidamed_backend.historico;

import java.time.LocalDate;

public record HistoricoCriacaoDTO(
        Long pacienteId,
        Long medicamentoId,
        LocalDate data,
        String hora,
        String status) {
}
