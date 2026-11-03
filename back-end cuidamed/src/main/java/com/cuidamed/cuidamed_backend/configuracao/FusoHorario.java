package com.cuidamed.cuidamed_backend.configuracao;

import java.time.LocalDate;
import java.time.ZoneId;

/** O servidor pode estar em outro fuso: o "hoje" do paciente é sempre o de Brasília. */
public final class FusoHorario {

    public static final ZoneId BRASIL = ZoneId.of("America/Sao_Paulo");

    private FusoHorario() {
    }

    public static LocalDate hoje() {
        return LocalDate.now(BRASIL);
    }
}
