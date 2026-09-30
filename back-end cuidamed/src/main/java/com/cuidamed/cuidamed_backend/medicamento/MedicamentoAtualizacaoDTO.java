package com.cuidamed.cuidamed_backend.medicamento;

import java.time.LocalDate;
import java.util.List;

public record MedicamentoAtualizacaoDTO(
        String nome,
        String dosagem,
        FormaMedicamento forma,
        FrequenciaMedicamento frequencia,
        LocalDate dataInicio,
        LocalDate dataFim,
        String observacoes,
        Integer quantidadeEstoque,
        Integer quantidadePorDose,
        List<String> horarios) {
}
