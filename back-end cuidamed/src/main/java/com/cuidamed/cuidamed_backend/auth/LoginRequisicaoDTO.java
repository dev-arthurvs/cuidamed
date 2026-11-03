package com.cuidamed.cuidamed_backend.auth;

/**
 * [login]: e-mail ou telefone. [email] continua aceito (versões antigas do app
 * mandavam só ele).
 */
public record LoginRequisicaoDTO(String login, String email, String senha) {

    public String identificador() {
        return login != null && !login.isBlank() ? login : email;
    }
}
