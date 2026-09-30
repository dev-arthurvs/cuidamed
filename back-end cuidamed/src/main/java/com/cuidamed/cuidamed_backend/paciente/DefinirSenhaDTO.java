package com.cuidamed.cuidamed_backend.paciente;

/** "Ativar meu acesso": e-mail + código de ativação passado pelo cuidador + senha nova. */
public record DefinirSenhaDTO(String email, String codigo, String novaSenha) {
}
