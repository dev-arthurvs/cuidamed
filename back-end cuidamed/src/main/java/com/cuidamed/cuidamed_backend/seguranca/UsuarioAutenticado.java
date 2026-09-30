package com.cuidamed.cuidamed_backend.seguranca;

/**
 * Quem fez a requisição, lido do token JWT: o tipo ("PACIENTE" ou "CUIDADOR",
 * o mesmo do login) e o id na tabela correspondente.
 */
public record UsuarioAutenticado(String tipo, Long id) {

    public static final String PACIENTE = "PACIENTE";
    public static final String CUIDADOR = "CUIDADOR";

    public boolean ehPaciente() {
        return PACIENTE.equals(tipo);
    }

    public boolean ehCuidador() {
        return CUIDADOR.equals(tipo);
    }
}
