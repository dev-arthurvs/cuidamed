package com.cuidamed.cuidamed_backend.paciente;

/**
 * "Ativar meu acesso": e-mail ou telefone ([login]; [email] continua aceito) +
 * código de ativação passado pelo cuidador + senha nova.
 */
public record DefinirSenhaDTO(String login, String email, String codigo, String novaSenha) {

    public String identificador() {
        return login != null && !login.isBlank() ? login : email;
    }
}
