package com.cuidamed.cuidamed_backend.seguranca;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
public class LimitadorDeTentativas {

    private static final int LIMITE_DE_CHAVES = 10_000;
    private static final Duration JANELA_MAXIMA = Duration.ofDays(1);

    private final Map<String, Deque<Instant>> eventos = new ConcurrentHashMap<>();
    private final Clock relogio;

    @Autowired
    public LimitadorDeTentativas() {
        this(Clock.systemUTC());
    }

    LimitadorDeTentativas(Clock relogio) {
        this.relogio = relogio;
    }

    public void consumir(String chave, int limite, Duration janela, String mensagem) {
        Deque<Instant> lista = eventos.computeIfAbsent(chave, k -> new ArrayDeque<>());
        synchronized (lista) {
            descartarAntigos(lista, janela);
            if (lista.size() >= limite) {
                throw muitasTentativas(mensagem);
            }
            lista.addLast(relogio.instant());
        }
        limparSeNecessario();
    }

    public void exigirDisponivel(String chave, int limite, Duration janela, String mensagem) {
        Deque<Instant> lista = eventos.get(chave);
        if (lista == null) {
            return;
        }
        synchronized (lista) {
            descartarAntigos(lista, janela);
            if (lista.size() >= limite) {
                throw muitasTentativas(mensagem);
            }
        }
    }

    public void registrar(String chave) {
        Deque<Instant> lista = eventos.computeIfAbsent(chave, k -> new ArrayDeque<>());
        synchronized (lista) {
            lista.addLast(relogio.instant());
        }
        limparSeNecessario();
    }

    public void limpar(String chave) {
        eventos.remove(chave);
    }

    private void descartarAntigos(Deque<Instant> lista, Duration janela) {
        Instant limite = relogio.instant().minus(janela);
        while (!lista.isEmpty() && lista.peekFirst().isBefore(limite)) {
            lista.pollFirst();
        }
    }

    private void limparSeNecessario() {
        if (eventos.size() <= LIMITE_DE_CHAVES) {
            return;
        }
        Instant limite = relogio.instant().minus(JANELA_MAXIMA);
        eventos.entrySet().removeIf(entrada -> {
            synchronized (entrada.getValue()) {
                Instant ultimo = entrada.getValue().peekLast();
                return ultimo == null || ultimo.isBefore(limite);
            }
        });
    }

    private static ResponseStatusException muitasTentativas(String mensagem) {
        return new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, mensagem);
    }
}
