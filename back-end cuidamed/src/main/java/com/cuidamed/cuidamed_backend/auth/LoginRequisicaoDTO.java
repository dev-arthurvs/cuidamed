package com.cuidamed.cuidamed_backend.auth;

public record LoginRequisicaoDTO(String login, String email, String senha) {

    public String identificador() {
        return login != null && !login.isBlank() ? login : email;
    }
}
