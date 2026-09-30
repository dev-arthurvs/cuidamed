package com.cuidamed.cuidamed_backend.paciente;

import java.time.LocalDate;

public record PacienteCriacaoDTO(
        String nome,
        String email,
        String senha,
        LocalDate dataNascimento,
        Sexo sexo,
        String enfermidade,
        String telefone,
        String endereco,
        String observacoesClinicas,
        Long cuidadorId) {
}
