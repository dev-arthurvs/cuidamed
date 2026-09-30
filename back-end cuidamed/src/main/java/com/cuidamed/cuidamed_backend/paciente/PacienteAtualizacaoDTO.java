package com.cuidamed.cuidamed_backend.paciente;

import java.time.LocalDate;

public record PacienteAtualizacaoDTO(
        String nome,
        String email,
        LocalDate dataNascimento,
        Sexo sexo,
        String enfermidade,
        String telefone,
        String endereco,
        String observacoesClinicas,
        Long cuidadorId) {
}
