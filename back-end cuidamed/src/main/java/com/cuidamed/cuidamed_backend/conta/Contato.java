package com.cuidamed.cuidamed_backend.conta;

import java.util.Locale;

public final class Contato {

    private Contato() {
    }

    public static boolean ehEmail(String identificador) {
        return identificador != null && identificador.contains("@");
    }

    public static String digitos(String telefone) {
        if (telefone == null) {
            return "";
        }
        String digitos = telefone.replaceAll("\\D", "");
        if (digitos.length() > 11 && digitos.startsWith("55")) {
            digitos = digitos.substring(2);
        }
        return digitos;
    }

    public static boolean telefoneValido(String telefone) {
        int tamanho = digitos(telefone).length();
        return tamanho == 10 || tamanho == 11;
    }

    public static boolean temTexto(String valor) {
        return valor != null && !valor.isBlank();
    }

    public static String emailOuNulo(String email) {
        return temTexto(email) ? email.trim() : null;
    }

    public static String chaveLimite(String identificador) {
        if (!temTexto(identificador)) {
            return "";
        }
        return ehEmail(identificador) ? identificador.trim().toLowerCase(Locale.ROOT) : digitos(identificador);
    }
}
