package com.cuidamed.cuidamed_backend.medicamento;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

public record MedicamentoRespostaDTO(
        Long id,
        Long pacienteId,
        String nome,
        String dosagem,
        FormaMedicamento forma,
        FrequenciaMedicamento frequencia,
        LocalDate dataInicio,
        LocalDate dataFim,
        String observacoes,
        Integer quantidadeEstoque,
        Integer quantidadePorDose,
        List<String> horarios,
        LocalDateTime criadoEm) {

    private static final DateTimeFormatter FORMATO_HORA = DateTimeFormatter.ofPattern("HH:mm");

    public static MedicamentoRespostaDTO paraDTO(Medicamento medicamento) {
        List<String> horarios = medicamento.getHorarios().stream()
                .map(horario -> horario.getHora().format(FORMATO_HORA))
                .sorted()
                .toList();

        return new MedicamentoRespostaDTO(
                medicamento.getId(),
                medicamento.getPaciente().getId(),
                medicamento.getNome(),
                medicamento.getDosagem(),
                medicamento.getForma(),
                medicamento.getFrequencia(),
                medicamento.getDataInicio(),
                medicamento.getDataFim(),
                medicamento.getObservacoes(),
                medicamento.getQuantidadeEstoque(),
                medicamento.getQuantidadePorDose(),
                horarios,
                medicamento.getCriadoEm());
    }
}
