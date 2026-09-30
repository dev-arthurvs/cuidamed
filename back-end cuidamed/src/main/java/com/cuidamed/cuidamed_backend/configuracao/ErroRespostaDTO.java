package com.cuidamed.cuidamed_backend.configuracao;

public record ErroRespostaDTO(String timestamp, int status, String error, String message) {
}
