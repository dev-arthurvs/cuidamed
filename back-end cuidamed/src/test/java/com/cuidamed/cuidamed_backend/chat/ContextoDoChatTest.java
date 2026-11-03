package com.cuidamed.cuidamed_backend.chat;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import org.junit.jupiter.api.Test;

import com.cuidamed.cuidamed_backend.historico.Historico;
import com.cuidamed.cuidamed_backend.historico.StatusHistorico;
import com.cuidamed.cuidamed_backend.medicamento.FormaMedicamento;
import com.cuidamed.cuidamed_backend.medicamento.FrequenciaMedicamento;
import com.cuidamed.cuidamed_backend.medicamento.Horario;
import com.cuidamed.cuidamed_backend.medicamento.Medicamento;
import com.cuidamed.cuidamed_backend.paciente.Paciente;

/** O que a IA recebe: as contas de dose e estoque, com o relógio fixo. Não usa banco. */
class ContextoDoChatTest {

    private static final LocalDate HOJE = LocalDate.of(2026, 11, 2);
    private static long proximoId = 1;

    private static Paciente paciente() {
        Paciente paciente = new Paciente();
        paciente.setNome("Maria");
        return paciente;
    }

    private static Medicamento remedio(String nome, FrequenciaMedicamento frequencia, LocalDate inicio, String... horas) {
        Medicamento medicamento = new Medicamento();
        medicamento.setId(proximoId++);
        medicamento.setNome(nome);
        medicamento.setForma(FormaMedicamento.COMPRIMIDO);
        medicamento.setFrequencia(frequencia);
        medicamento.setDataInicio(inicio);
        for (String hora : horas) {
            Horario horario = new Horario();
            horario.setHora(LocalTime.parse(hora));
            medicamento.getHorarios().add(horario);
        }
        return medicamento;
    }

    private static Medicamento diario(String nome, String... horas) {
        return remedio(nome, FrequenciaMedicamento.UMA_VEZ_AO_DIA, HOJE, horas);
    }

    private static Historico registro(Medicamento medicamento, LocalDate dia, String hora, StatusHistorico status) {
        Historico historico = new Historico();
        historico.setMedicamento(medicamento);
        historico.setNomeMedicamento(medicamento.getNome());
        historico.setData(dia);
        historico.setHora(LocalTime.parse(hora));
        historico.setStatus(status);
        return historico;
    }

    private static String montar(String agora, List<Medicamento> medicamentos, List<Historico> historico) {
        return ContextoDoChat.montar(paciente(), "Ana", medicamentos, historico,
                LocalDateTime.of(HOJE, LocalTime.parse(agora)));
    }

    @Test
    void informaAHoraAtualEAProximaDoseDoDia() {
        String texto = montar("09:30", List.of(diario("Losartana", "08:00", "20:00"), diario("Insulina", "12:00")), List.of());

        assertThat(texto).contains("AGORA: segunda-feira, 02/11/2026, 09:30");
        assertThat(texto).contains("PRÓXIMA DOSE: hoje às 12:00 — Insulina");
    }

    @Test
    void remediosNoMesmoHorarioAparecemJuntosNaProximaDose() {
        String texto = montar("09:30", List.of(diario("Losartana", "12:00"), diario("Insulina", "12:00")), List.of());

        assertThat(texto).contains("PRÓXIMA DOSE: hoje às 12:00 — Losartana e Insulina");
    }

    @Test
    void doseJaRegistradaNaoEAProxima() {
        Medicamento losartana = diario("Losartana", "08:00", "20:00");
        String texto = montar("07:50", List.of(losartana), List.of(registro(losartana, HOJE, "08:00", StatusHistorico.TOMADO)));

        assertThat(texto).contains("PRÓXIMA DOSE: hoje às 20:00");
        assertThat(texto).contains("- 08:00 Losartana: tomada");
    }

    @Test
    void depoisDaUltimaDoseAProximaEAmanha() {
        String texto = montar("22:00", List.of(diario("Losartana", "08:00")), List.of());

        assertThat(texto).contains("PRÓXIMA DOSE: amanhã às 08:00");
    }

    @Test
    void doseSemRegistroFicaPendenteAtrasadaOuPerdidaPeloHorario() {
        Medicamento losartana = diario("Losartana", "08:00");

        assertThat(montar("08:14", List.of(losartana), List.of())).contains("- 08:00 Losartana: pendente");
        assertThat(montar("08:15", List.of(losartana), List.of())).contains("- 08:00 Losartana: atrasada (sem registro)");
        assertThat(montar("10:59", List.of(losartana), List.of())).contains("- 08:00 Losartana: atrasada (sem registro)");
        assertThat(montar("11:00", List.of(losartana), List.of())).contains("- 08:00 Losartana: perdida (sem registro)");
    }

    @Test
    void doseDeDiaAnteriorSemRegistroContaComoPerdida() {
        Medicamento losartana = remedio("Losartana", FrequenciaMedicamento.UMA_VEZ_AO_DIA, HOJE.minusDays(1), "08:00");

        assertThat(montar("07:00", List.of(losartana), List.of())).contains("- 01/11/2026 08:00 Losartana: perdida (sem registro)");
    }

    @Test
    void diasAlternadosPulaODiaSemDose() {
        Medicamento alternado = remedio("Vitamina", FrequenciaMedicamento.DIAS_ALTERNADOS, HOJE.minusDays(1), "08:00");

        assertThat(montar("07:00", List.of(alternado), List.of()))
                .contains("PRÓXIMA DOSE: amanhã às 08:00");
        assertThat(montar("07:00", List.of(alternado), List.of())).contains("Nenhuma dose hoje.");
    }

    @Test
    void estoqueUsaAMesmaContaDoWeb() {
        Medicamento continuo = diario("Losartana", "08:00", "20:00");
        continuo.setQuantidadeEstoque(20);
        continuo.setQuantidadePorDose(2);
        assertThat(montar("07:00", List.of(continuo), List.of())).contains("estoque: 20 comprimidos — baixo, dura 5 dias");

        continuo.setQuantidadeEstoque(60);
        assertThat(montar("07:00", List.of(continuo), List.of())).contains("estoque: 60 comprimidos — dura 15 dias");

        continuo.setQuantidadeEstoque(0);
        assertThat(montar("07:00", List.of(continuo), List.of())).contains("estoque: 0 comprimidos — esgotado");
    }

    @Test
    void estoqueQueCobreOTratamentoNaoPrecisaRepor() {
        Medicamento curto = diario("Antibiótico", "08:00");
        curto.setDataFim(HOJE.plusDays(2));
        curto.setQuantidadeEstoque(3);

        assertThat(montar("07:00", List.of(curto), List.of())).contains("suficiente até o fim do tratamento");
    }

    @Test
    void informaQuantoComprarParaTerminarOTratamento() {
        Medicamento cetoprofeno = diario("Cetoprofeno", "08:00");
        cetoprofeno.setDataFim(HOJE.plusDays(4));
        cetoprofeno.setQuantidadeEstoque(2);

        assertThat(montar("07:00", List.of(cetoprofeno), List.of()))
                .contains("estoque: 2 comprimidos — baixo, dura 2 dias — para terminar o tratamento, precisa comprar 3 comprimidos");
    }

    @Test
    void compraUsaAUnidadeDoRemedioEAQuantidadePorDose() {
        Medicamento xarope = diario("Xarope", "08:00", "20:00");
        xarope.setForma(FormaMedicamento.XAROPE);
        xarope.setDataFim(HOJE.plusDays(1));
        xarope.setQuantidadePorDose(10);
        xarope.setQuantidadeEstoque(15);

        assertThat(montar("07:00", List.of(xarope), List.of())).contains("precisa comprar 25 ml");

        Medicamento gotas = diario("Gotas", "08:00");
        gotas.setForma(FormaMedicamento.GOTA);
        gotas.setDataFim(HOJE);
        gotas.setQuantidadePorDose(20);
        gotas.setQuantidadeEstoque(0);

        assertThat(montar("07:00", List.of(gotas), List.of())).contains("esgotado, precisa repor — para terminar o tratamento, precisa comprar 20 gotas");
    }

    @Test
    void doseTomadaHojeNaoEntraNaCompra() {
        Medicamento cetoprofeno = diario("Cetoprofeno", "08:00");
        cetoprofeno.setDataFim(HOJE.plusDays(4));
        cetoprofeno.setQuantidadeEstoque(2);

        assertThat(montar("09:00", List.of(cetoprofeno), List.of(registro(cetoprofeno, HOJE, "08:00", StatusHistorico.TOMADO))))
                .contains("precisa comprar 2 comprimidos");
    }

    @Test
    void usoContinuoNaoTemCompraCalculada() {
        Medicamento continuo = diario("Losartana", "08:00");
        continuo.setQuantidadeEstoque(2);

        assertThat(montar("07:00", List.of(continuo), List.of())).contains("baixo, dura 2 dias").doesNotContain("precisa comprar");
    }

    @Test
    void quantidadePorDoseZeroNaoQuebra() {
        Medicamento medicamento = diario("Losartana", "08:00");
        medicamento.setQuantidadeEstoque(10);
        medicamento.setQuantidadePorDose(0);

        assertThat(montar("07:00", List.of(medicamento), List.of())).contains("dura 10 dias");
    }

    @Test
    void separaAtivosFuturosEEncerrados() {
        Medicamento futuro = remedio("Futuro", FrequenciaMedicamento.UMA_VEZ_AO_DIA, HOJE.plusDays(3), "08:00");
        Medicamento encerrado = remedio("Antigo", FrequenciaMedicamento.UMA_VEZ_AO_DIA, HOJE.minusDays(60), "08:00");
        encerrado.setDataFim(HOJE.minusDays(30));

        String texto = montar("07:00", List.of(diario("Atual", "08:00"), futuro, encerrado), List.of());

        assertThat(texto).contains("MEDICAMENTOS QUE AINDA VÃO COMEÇAR");
        assertThat(texto).contains("MEDICAMENTOS ENCERRADOS");
        assertThat(texto).contains("Antigo (comprimido) — período: 03/09/2026 até 03/10/2026");
        assertThat(texto).contains("PRÓXIMA DOSE: hoje às 08:00 — Atual");
    }

    @Test
    void informaCuidadorEPermissao() {
        List<Medicamento> semRemedios = List.of();
        LocalDateTime agora = LocalDateTime.of(HOJE, LocalTime.NOON);

        String comCuidador = ContextoDoChat.montar(paciente(), "Ana", semRemedios, List.of(), agora);
        assertThat(comCuidador).contains("Cuidador: Ana").contains("próprios remédios: não");

        String semCuidador = ContextoDoChat.montar(paciente(), null, semRemedios, List.of(), agora);
        assertThat(semCuidador).contains("Cuidador: não tem cuidador vinculado").contains("próprios remédios: sim");
    }
}
