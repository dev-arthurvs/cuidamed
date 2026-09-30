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

/**
 * Limita quantas vezes algo pode acontecer numa janela de tempo, por chave
 * (ex.: "login:maria@email.com", "chat:12"). Protege contra quem tenta
 * adivinhar senhas/códigos e contra gasto descontrolado com a IA.
 *
 * <p>Os limites são por conta (e-mail ou paciente), não por endereço IP: no
 * Railway todas as requisições passam pelo proxy dele, e um limite por IP
 * bloquearia todo mundo junto ou poderia ser burlado com cabeçalhos falsos.
 *
 * <p>Fica em memória: vale para um servidor só (o caso do Railway) e zera
 * quando ele reinicia.
 */
@Component
public class LimitadorDeTentativas {

    // Acima disso, limpa as chaves sem eventos recentes (evita crescer sem fim
    // com e-mails inventados).
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

    /** Conta mais um uso; se já chegou ao limite na janela, recusa com 429. */
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

    /** Só confere (não conta): usado antes de uma tentativa que pode falhar. */
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

    /** Registra uma falha (ex.: senha errada), sem recusar esta requisição. */
    public void registrar(String chave) {
        Deque<Instant> lista = eventos.computeIfAbsent(chave, k -> new ArrayDeque<>());
        synchronized (lista) {
            lista.addLast(relogio.instant());
        }
        limparSeNecessario();
    }

    /** Zera a chave (ex.: login certo apaga as falhas anteriores). */
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
