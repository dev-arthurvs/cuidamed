package com.cuidamed.cuidamed_backend.cuidador;

import java.time.LocalDateTime;

public record CuidadorRespostaDTO(
        Long id, String nome, String email, String profissao, String telefone, LocalDateTime criadoEm) {

    public static CuidadorRespostaDTO paraDTO(Cuidador cuidador) {
        return new CuidadorRespostaDTO(
                cuidador.getId(),
                cuidador.getNome(),
                cuidador.getEmail(),
                cuidador.getProfissao(),
                cuidador.getTelefone(),
                cuidador.getCriadoEm());
    }
}
