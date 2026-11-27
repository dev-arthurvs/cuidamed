package com.cuidamed.cuidamed_backend.seguranca;

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
