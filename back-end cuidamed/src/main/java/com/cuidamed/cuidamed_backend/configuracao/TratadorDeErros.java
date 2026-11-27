package com.cuidamed.cuidamed_backend.configuracao;

import java.time.Instant;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice
public class TratadorDeErros {

    private static final Logger LOG = LoggerFactory.getLogger(TratadorDeErros.class);

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ErroRespostaDTO> tratarResponseStatusException(ResponseStatusException erro) {
        HttpStatus status = HttpStatus.valueOf(erro.getStatusCode().value());
        String mensagem = erro.getReason() != null ? erro.getReason() : status.getReasonPhrase();
        return construirResposta(status, mensagem);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErroRespostaDTO> tratarJsonInvalido(HttpMessageNotReadableException erro) {
        return construirResposta(HttpStatus.BAD_REQUEST, "Corpo da requisição inválido.");
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ErroRespostaDTO> tratarRotaInexistente(NoResourceFoundException erro) {
        return construirResposta(HttpStatus.NOT_FOUND, "Endereço não encontrado.");
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ErroRespostaDTO> tratarMetodoNaoSuportado(HttpRequestMethodNotSupportedException erro) {
        return construirResposta(HttpStatus.METHOD_NOT_ALLOWED, "Operação não permitida nesse endereço.");
    }

    @ExceptionHandler({MissingServletRequestParameterException.class, MethodArgumentTypeMismatchException.class})
    public ResponseEntity<ErroRespostaDTO> tratarParametroInvalido(Exception erro) {
        return construirResposta(HttpStatus.BAD_REQUEST, "Parâmetros da requisição inválidos.");
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErroRespostaDTO> tratarErroInesperado(Exception erro) {
        LOG.error("Erro inesperado ao processar requisição", erro);
        return construirResposta(HttpStatus.INTERNAL_SERVER_ERROR, "Erro inesperado no servidor. Tente novamente.");
    }

    private ResponseEntity<ErroRespostaDTO> construirResposta(HttpStatus status, String mensagem) {
        ErroRespostaDTO corpo = new ErroRespostaDTO(Instant.now().toString(), status.value(), status.getReasonPhrase(), mensagem);
        return ResponseEntity.status(status).body(corpo);
    }
}
