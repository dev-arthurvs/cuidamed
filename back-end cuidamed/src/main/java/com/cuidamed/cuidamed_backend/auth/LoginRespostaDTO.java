package com.cuidamed.cuidamed_backend.auth;

/** Resposta do login: o token vai em "Authorization: Bearer <token>" nas próximas chamadas. */
public record LoginRespostaDTO(String tipo, Long id, String token) {
}
