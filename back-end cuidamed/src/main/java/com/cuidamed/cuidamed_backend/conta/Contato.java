package com.cuidamed.cuidamed_backend.conta;

import java.util.Locale;

/**
 * Login por e-mail ou telefone. O e-mail deixou de ser obrigatório (muitos
 * idosos não têm): quem não tem entra pelo número do celular. O telefone fica
 * salvo com máscara ("(79) 99999-9999"); a comparação usa só os dígitos.
 */
public final class Contato {

    private Contato() {
    }

    /** Tem "@": é e-mail. Senão, é tratado como telefone. */
    public static boolean ehEmail(String identificador) {
        return identificador != null && identificador.contains("@");
    }

    /** Só os dígitos do telefone, sem o 55 do Brasil quando vier com ele. */
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

    /** DDD + número: 10 dígitos (fixo) ou 11 (celular). */
    public static boolean telefoneValido(String telefone) {
        int tamanho = digitos(telefone).length();
        return tamanho == 10 || tamanho == 11;
    }

    public static boolean temTexto(String valor) {
        return valor != null && !valor.isBlank();
    }

    /** E-mail vazio vira nulo (a coluna é única: dois "" dariam conflito). */
    public static String emailOuNulo(String email) {
        return temTexto(email) ? email.trim() : null;
    }

    /** Chave do limitador de tentativas: o mesmo telefone com ou sem máscara conta junto. */
    public static String chaveLimite(String identificador) {
        if (!temTexto(identificador)) {
            return "";
        }
        return ehEmail(identificador) ? identificador.trim().toLowerCase(Locale.ROOT) : digitos(identificador);
    }
}
