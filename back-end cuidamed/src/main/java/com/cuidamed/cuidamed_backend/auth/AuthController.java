package com.cuidamed.cuidamed_backend.auth;

import java.time.Duration;
import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.seguranca.LimitadorDeTentativas;

@RestController
public class AuthController {

    // Até 5 senhas erradas por e-mail a cada 15 minutos; depois, espera.
    static final int MAXIMO_ERROS_LOGIN = 5;
    static final Duration JANELA_ERROS_LOGIN = Duration.ofMinutes(15);
    static final String MUITAS_TENTATIVAS = "Muitas tentativas de login. Aguarde 15 minutos e tente de novo.";

    private final AuthService authService;
    private final LimitadorDeTentativas limitador;

    public AuthController(AuthService authService, LimitadorDeTentativas limitador) {
        this.authService = authService;
        this.limitador = limitador;
    }

    @PostMapping("/api/auth/login")
    public LoginRespostaDTO login(@RequestBody LoginRequisicaoDTO dto) {
        String chave = "login:" + (dto.email() == null ? "" : dto.email().trim().toLowerCase(Locale.ROOT));
        limitador.exigirDisponivel(chave, MAXIMO_ERROS_LOGIN, JANELA_ERROS_LOGIN, MUITAS_TENTATIVAS);
        try {
            LoginRespostaDTO resposta = authService.login(dto);
            limitador.limpar(chave);
            return resposta;
        } catch (ResponseStatusException erro) {
            if (erro.getStatusCode().value() == HttpStatus.UNAUTHORIZED.value()) {
                limitador.registrar(chave);
            }
            throw erro;
        }
    }
}
