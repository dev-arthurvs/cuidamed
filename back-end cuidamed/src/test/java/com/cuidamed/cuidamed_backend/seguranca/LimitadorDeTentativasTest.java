package com.cuidamed.cuidamed_backend.seguranca;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;

import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

class LimitadorDeTentativasTest {

    /** Relógio que o teste avança à vontade (sem esperar de verdade). */
    private static final class RelogioManual extends Clock {
        private Instant agora = Instant.parse("2026-09-30T12:00:00Z");

        void avancar(Duration tempo) {
            agora = agora.plus(tempo);
        }

        @Override
        public Instant instant() {
            return agora;
        }

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zona) {
            return this;
        }
    }

    private final RelogioManual relogio = new RelogioManual();
    private final LimitadorDeTentativas limitador = new LimitadorDeTentativas(relogio);
    private static final Duration QUINZE_MIN = Duration.ofMinutes(15);

    @Test
    void consumirRecusaAcimaDoLimiteCom429() {
        for (int i = 0; i < 3; i++) {
            limitador.consumir("chave", 3, QUINZE_MIN, "limite");
        }
        ResponseStatusException erro = assertThrows(ResponseStatusException.class,
                () -> limitador.consumir("chave", 3, QUINZE_MIN, "limite"));
        assertEquals(429, erro.getStatusCode().value());
        assertEquals("limite", erro.getReason());
    }

    @Test
    void liberaDepoisQueAJanelaPassa() {
        for (int i = 0; i < 3; i++) {
            limitador.consumir("chave", 3, QUINZE_MIN, "limite");
        }
        relogio.avancar(QUINZE_MIN.plusSeconds(1));
        assertDoesNotThrow(() -> limitador.consumir("chave", 3, QUINZE_MIN, "limite"));
    }

    @Test
    void falhasRegistradasBloqueiamEAcertoZera() {
        for (int i = 0; i < 5; i++) {
            limitador.registrar("login:maria");
        }
        assertThrows(ResponseStatusException.class,
                () -> limitador.exigirDisponivel("login:maria", 5, QUINZE_MIN, "espere"));
        limitador.limpar("login:maria");
        assertDoesNotThrow(() -> limitador.exigirDisponivel("login:maria", 5, QUINZE_MIN, "espere"));
    }

    @Test
    void chavesSaoIndependentes() {
        for (int i = 0; i < 5; i++) {
            limitador.registrar("login:maria");
        }
        assertDoesNotThrow(() -> limitador.exigirDisponivel("login:joao", 5, QUINZE_MIN, "espere"));
    }
}
