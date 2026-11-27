package com.cuidamed.cuidamed_backend.paciente;

public record DefinirSenhaDTO(String login, String email, String codigo, String novaSenha) {

    public String identificador() {
        return login != null && !login.isBlank() ? login : email;
    }
}
