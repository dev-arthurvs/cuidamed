package com.cuidamed.cuidamed_backend.chat;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.Period;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import com.cuidamed.cuidamed_backend.historico.Historico;
import com.cuidamed.cuidamed_backend.historico.StatusHistorico;
import com.cuidamed.cuidamed_backend.medicamento.FormaMedicamento;
import com.cuidamed.cuidamed_backend.medicamento.FrequenciaMedicamento;
import com.cuidamed.cuidamed_backend.medicamento.Horario;
import com.cuidamed.cuidamed_backend.medicamento.Medicamento;
import com.cuidamed.cuidamed_backend.paciente.Paciente;

/**
 * Monta o texto com os dados do paciente que vai para a IA. Próxima dose, doses
 * atrasadas/perdidas e estoque já vão calculados, para a IA não fazer contas.
 * Mesmas regras do web (utilitarios/horarios.js) e do mobile (utilitarios/horarios.dart).
 */
final class ContextoDoChat {

    private static final int TOLERANCIA_ATRASO_MIN = 15;
    private static final int LIMITE_PERDIDA_MIN = 180;
    private static final int LIMIAR_DIAS_ESTOQUE_BAIXO = 5;
    static final int DIAS_DE_HISTORICO = 7;

    private static final Locale PT_BR = Locale.of("pt", "BR");
    private static final DateTimeFormatter DATA_BR = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter DATA_COM_SEMANA = DateTimeFormatter.ofPattern("EEEE, dd/MM/yyyy", PT_BR);
    private static final DateTimeFormatter HORA = DateTimeFormatter.ofPattern("HH:mm");

    private record Dose(Medicamento medicamento, LocalDate dia, LocalTime hora) {
    }

    private record LinhaDeDose(LocalDate dia, LocalTime hora, String nome, String situacao) {
    }

    private ContextoDoChat() {
    }

    /** @param nomeCuidador nome do cuidador do vínculo ativo; null se o paciente não tem cuidador. */
    static String montar(Paciente paciente, String nomeCuidador, List<Medicamento> medicamentos,
            List<Historico> historico, LocalDateTime agora) {
        LocalDate hoje = agora.toLocalDate();
        Set<String> registrados = historico.stream()
                .map(item -> chave(item.getMedicamento().getId(), item.getData(), item.getHora()))
                .collect(Collectors.toSet());

        StringBuilder texto = new StringBuilder();
        texto.append("AGORA: ").append(hoje.format(DATA_COM_SEMANA)).append(", ").append(agora.format(HORA)).append('\n');

        escreverPaciente(texto, paciente, nomeCuidador, hoje);
        escreverProximaDose(texto, medicamentos, registrados, agora);

        List<Medicamento> encerrados = medicamentos.stream()
                .filter(medicamento -> medicamento.getDataFim() != null && medicamento.getDataFim().isBefore(hoje))
                .toList();
        List<Medicamento> aIniciar = medicamentos.stream()
                .filter(medicamento -> !encerrados.contains(medicamento) && medicamento.getDataInicio() != null
                        && medicamento.getDataInicio().isAfter(hoje))
                .toList();
        // Tratamento com início no futuro ainda não é "ativo": sem essa separação
        // a IA mandava tomar hoje um remédio que só começa amanhã.
        List<Medicamento> ativos = medicamentos.stream()
                .filter(medicamento -> !encerrados.contains(medicamento) && !aIniciar.contains(medicamento))
                .toList();

        texto.append("\nMEDICAMENTOS ATIVOS:\n");
        if (ativos.isEmpty()) {
            texto.append("Nenhum medicamento ativo no momento.\n");
        }
        for (Medicamento medicamento : ativos) {
            escreverMedicamento(texto, medicamento, historico, registrados, agora);
        }

        if (!aIniciar.isEmpty()) {
            texto.append("\nMEDICAMENTOS QUE AINDA VÃO COMEÇAR (não devem ser tomados antes da data de início):\n");
            for (Medicamento medicamento : aIniciar) {
                escreverMedicamento(texto, medicamento, historico, registrados, agora);
            }
        }

        if (!encerrados.isEmpty()) {
            texto.append("\nMEDICAMENTOS ENCERRADOS (tratamento já terminou, não devem mais ser tomados):\n");
            for (Medicamento medicamento : encerrados) {
                texto.append("- ").append(nomeComDosagem(medicamento))
                        .append(" (").append(nomeDaForma(medicamento.getForma())).append(')')
                        .append(" — período: ").append(formatar(medicamento.getDataInicio()))
                        .append(" até ").append(formatar(medicamento.getDataFim())).append('\n');
                escreverObservacoes(texto, medicamento);
            }
        }

        escreverDoses(texto, medicamentos, historico, registrados, agora);
        return texto.toString();
    }

    private static void escreverPaciente(StringBuilder texto, Paciente paciente, String nomeCuidador, LocalDate hoje) {
        texto.append("\nDADOS DO PACIENTE:\n");
        texto.append("Nome: ").append(paciente.getNome()).append('\n');
        if (paciente.getDataNascimento() != null) {
            int idade = Period.between(paciente.getDataNascimento(), hoje).getYears();
            texto.append("Idade: ").append(idade).append(" anos\n");
        }
        if (paciente.getEnfermidade() != null && !paciente.getEnfermidade().isBlank()) {
            texto.append("Condição de saúde: ").append(paciente.getEnfermidade()).append('\n');
        }
        if (paciente.getObservacoesClinicas() != null && !paciente.getObservacoesClinicas().isBlank()) {
            texto.append("Observações clínicas: ").append(paciente.getObservacoesClinicas()).append('\n');
        }
        texto.append("Cuidador: ").append(nomeCuidador != null ? nomeCuidador : "não tem cuidador vinculado").append('\n');
        // Mesma regra de Autorizacao: sem cuidador, o paciente altera os próprios remédios.
        boolean podeAlterar = nomeCuidador == null || paciente.isPermiteAlteracoes();
        texto.append("Pode inserir, editar e excluir os próprios remédios: ").append(podeAlterar ? "sim" : "não").append('\n');
    }

    private static void escreverProximaDose(StringBuilder texto, List<Medicamento> medicamentos,
            Set<String> registrados, LocalDateTime agora) {
        List<Dose> proximas = medicamentos.stream()
                .map(medicamento -> proximaDose(medicamento, registrados, agora))
                .flatMap(Optional::stream)
                .toList();
        texto.append("\nPRÓXIMA DOSE: ");
        Optional<Dose> primeira = proximas.stream()
                .min(Comparator.comparing(Dose::dia).thenComparing(Dose::hora));
        if (primeira.isEmpty()) {
            texto.append("nenhuma dose futura na agenda.\n");
            return;
        }
        String nomes = proximas.stream()
                .filter(dose -> dose.dia().equals(primeira.get().dia()) && dose.hora().equals(primeira.get().hora()))
                .map(dose -> nomeComDosagem(dose.medicamento()) + quantidadeEntreParenteses(dose.medicamento()))
                .collect(Collectors.joining(" e "));
        texto.append(quando(primeira.get(), agora.toLocalDate())).append(" — ").append(nomes).append('\n');
    }

    private static void escreverMedicamento(StringBuilder texto, Medicamento medicamento, List<Historico> historico,
            Set<String> registrados, LocalDateTime agora) {
        LocalDate hoje = agora.toLocalDate();
        String horarios = horariosEmOrdem(medicamento).stream()
                .map(hora -> hora.format(HORA))
                .collect(Collectors.joining(", "));

        texto.append("- ").append(nomeComDosagem(medicamento)).append('\n');
        texto.append("  forma: ").append(nomeDaForma(medicamento.getForma())).append('\n');
        texto.append("  frequência: ").append(nomeDaFrequencia(medicamento.getFrequencia())).append('\n');
        texto.append("  horários: ").append(horarios).append('\n');
        if (medicamento.getQuantidadePorDose() != null) {
            texto.append("  quantidade por dose: ").append(quantidade(medicamento, medicamento.getQuantidadePorDose())).append('\n');
        }
        texto.append("  início: ").append(formatar(medicamento.getDataInicio())).append('\n');
        texto.append("  fim: ").append(medicamento.getDataFim() != null
                ? formatar(medicamento.getDataFim()) : "uso contínuo, sem data para acabar").append('\n');
        texto.append("  estoque: ").append(descreverEstoque(medicamento, historico, hoje)).append('\n');
        texto.append("  próxima dose: ").append(proximaDose(medicamento, registrados, agora)
                .map(dose -> quando(dose, hoje)).orElse("nenhuma")).append('\n');
        escreverObservacoes(texto, medicamento);
    }

    private static void escreverObservacoes(StringBuilder texto, Medicamento medicamento) {
        if (medicamento.getObservacoes() != null && !medicamento.getObservacoes().isBlank()) {
            texto.append("  observações: ").append(medicamento.getObservacoes()).append('\n');
        }
    }

    /** Doses de hoje e dos últimos dias: as registradas e as que passaram sem registro. */
    private static void escreverDoses(StringBuilder texto, List<Medicamento> medicamentos, List<Historico> historico,
            Set<String> registrados, LocalDateTime agora) {
        LocalDate hoje = agora.toLocalDate();
        LocalDate inicio = hoje.minusDays(DIAS_DE_HISTORICO);

        List<LinhaDeDose> linhas = new ArrayList<>();
        for (Historico item : historico) {
            if (!item.getData().isBefore(inicio) && !item.getData().isAfter(hoje)) {
                linhas.add(new LinhaDeDose(item.getData(), item.getHora(), item.getNomeMedicamento(), nomeDoStatus(item.getStatus())));
            }
        }
        for (LocalDate dia = inicio; !dia.isAfter(hoje); dia = dia.plusDays(1)) {
            for (Medicamento medicamento : medicamentos) {
                if (!medicamento.temDoseEm(dia)) {
                    continue;
                }
                for (LocalTime hora : horariosEmOrdem(medicamento)) {
                    if (!registrados.contains(chave(medicamento.getId(), dia, hora))) {
                        linhas.add(new LinhaDeDose(dia, hora, medicamento.getNome(), situacaoSemRegistro(dia, hora, agora)));
                    }
                }
            }
        }
        linhas.sort(Comparator.comparing(LinhaDeDose::dia).thenComparing(LinhaDeDose::hora));

        texto.append("\nDOSES DE HOJE:\n");
        List<LinhaDeDose> deHoje = linhas.stream().filter(linha -> linha.dia().equals(hoje)).toList();
        if (deHoje.isEmpty()) {
            texto.append("Nenhuma dose hoje.\n");
        }
        for (LinhaDeDose linha : deHoje) {
            texto.append("- ").append(linha.hora().format(HORA)).append(' ').append(linha.nome())
                    .append(": ").append(linha.situacao()).append('\n');
        }

        texto.append("\nDOSES DOS ÚLTIMOS ").append(DIAS_DE_HISTORICO).append(" DIAS (sem contar hoje):\n");
        List<LinhaDeDose> anteriores = linhas.stream().filter(linha -> !linha.dia().equals(hoje)).toList();
        if (anteriores.isEmpty()) {
            texto.append("Nenhuma dose nesse período.\n");
        }
        for (LinhaDeDose linha : anteriores) {
            texto.append("- ").append(formatar(linha.dia())).append(' ').append(linha.hora().format(HORA))
                    .append(' ').append(linha.nome()).append(": ").append(linha.situacao()).append('\n');
        }
    }

    // Dose sem registro não é gravada: atrasada de 15 min a 3 h, perdida depois disso.
    private static String situacaoSemRegistro(LocalDate dia, LocalTime hora, LocalDateTime agora) {
        if (dia.isBefore(agora.toLocalDate())) {
            return "perdida (sem registro)";
        }
        int diferenca = minutos(agora.toLocalTime()) - minutos(hora);
        if (diferenca < TOLERANCIA_ATRASO_MIN) {
            return "pendente";
        }
        return diferenca < LIMITE_PERDIDA_MIN ? "atrasada (sem registro)" : "perdida (sem registro)";
    }

    private static Optional<Dose> proximaDose(Medicamento medicamento, Set<String> registrados, LocalDateTime agora) {
        List<LocalTime> horarios = horariosEmOrdem(medicamento);
        if (horarios.isEmpty()) {
            return Optional.empty();
        }
        LocalDate hoje = agora.toLocalDate();
        if (medicamento.temDoseEm(hoje)) {
            for (LocalTime hora : horarios) {
                if (!registrados.contains(chave(medicamento.getId(), hoje, hora))
                        && situacaoSemRegistro(hoje, hora, agora).equals("pendente")) {
                    return Optional.of(new Dose(medicamento, hoje, hora));
                }
            }
        }
        LocalDate dia = proximoDiaDeDose(medicamento, hoje.plusDays(1));
        return dia == null ? Optional.empty() : Optional.of(new Dose(medicamento, dia, horarios.get(0)));
    }

    /** Próximo dia (a partir de aPartirDe, inclusive) com dose; null se o tratamento acaba antes. */
    private static LocalDate proximoDiaDeDose(Medicamento medicamento, LocalDate aPartirDe) {
        LocalDate inicio = medicamento.getDataInicio();
        LocalDate dia = inicio != null && inicio.isAfter(aPartirDe) ? inicio : aPartirDe;
        for (int i = 0; i < 8; i++) {
            if (medicamento.getDataFim() != null && dia.isAfter(medicamento.getDataFim())) {
                return null;
            }
            if (medicamento.temDoseEm(dia)) {
                return dia;
            }
            dia = dia.plusDays(1);
        }
        return null;
    }

    private static String descreverEstoque(Medicamento medicamento, List<Historico> historico, LocalDate hoje) {
        Integer quantidade = medicamento.getQuantidadeEstoque();
        if (medicamento.getForma() == FormaMedicamento.POMADA || quantidade == null) {
            return "não informado";
        }
        int dosesPorDia = Math.max(1, medicamento.getHorarios().size());
        int consumoPorDose = consumoPorDose(medicamento);
        // Dias de calendário: em "Dias alternados"/"Semanal" cada dia de dose rende 2/7 dias.
        int diasRestantes = quantidade / (dosesPorDia * consumoPorDose) * intervaloEntreDiasDeDose(medicamento);
        Integer necessarias = unidadesAteOFim(medicamento, historico, hoje, dosesPorDia, consumoPorDose);

        String texto = quantidade(medicamento, quantidade);
        String compra = quantoComprar(medicamento, quantidade, necessarias);
        if (quantidade <= 0 && (necessarias == null || necessarias != 0)) {
            return texto + " — esgotado, precisa repor" + compra;
        }
        // Se o que tem cobre tudo o que falta tomar até a data final, não precisa comprar.
        if (necessarias != null && quantidade >= necessarias) {
            return texto + " — suficiente até o fim do tratamento";
        }
        String duracao = diasRestantes <= 0 ? "não dá para o dia todo"
                : "dura " + diasRestantes + (diasRestantes == 1 ? " dia" : " dias");
        return texto + " — " + (diasRestantes <= LIMIAR_DIAS_ESTOQUE_BAIXO ? "baixo, " : "") + duracao + compra;
    }

    // Só existe com data final: em uso contínuo não há como saber o total do tratamento.
    private static String quantoComprar(Medicamento medicamento, int quantidade, Integer necessarias) {
        if (necessarias == null || necessarias <= quantidade) {
            return "";
        }
        return " — para terminar o tratamento, precisa comprar " + quantidade(medicamento, necessarias - quantidade);
    }

    // Unidades que ainda serão consumidas até o fim do tratamento. null em uso contínuo.
    private static Integer unidadesAteOFim(Medicamento medicamento, List<Historico> historico, LocalDate hoje,
            int dosesPorDia, int consumoPorDose) {
        LocalDate fim = medicamento.getDataFim();
        if (fim == null || fim.isBefore(hoje)) {
            return null;
        }
        LocalDate inicio = medicamento.getDataInicio();
        if (inicio != null && inicio.isAfter(hoje)) {
            return contarDiasDeDose(medicamento, inicio, fim) * dosesPorDia * consumoPorDose;
        }
        int tomadasHoje = (int) historico.stream()
                .filter(item -> item.getMedicamento().getId().equals(medicamento.getId()))
                .filter(item -> item.getData().equals(hoje) && item.getStatus() == StatusHistorico.TOMADO)
                .count();
        int dosesRestantesHoje = medicamento.temDoseEm(hoje) ? Math.max(0, dosesPorDia - tomadasHoje) : 0;
        int diasSeguintes = contarDiasDeDose(medicamento, hoje.plusDays(1), fim);
        return (dosesRestantesHoje + diasSeguintes * dosesPorDia) * consumoPorDose;
    }

    private static int contarDiasDeDose(Medicamento medicamento, LocalDate de, LocalDate ate) {
        if (ate.isBefore(de)) {
            return 0;
        }
        int intervalo = intervaloEntreDiasDeDose(medicamento);
        if (intervalo == 1 || medicamento.getDataInicio() == null) {
            return (int) ChronoUnit.DAYS.between(de, ate) + 1;
        }
        LocalDate primeiro = proximoDiaDeDose(medicamento, de);
        if (primeiro == null || primeiro.isAfter(ate)) {
            return 0;
        }
        return (int) (ChronoUnit.DAYS.between(primeiro, ate) / intervalo) + 1;
    }

    private static int intervaloEntreDiasDeDose(Medicamento medicamento) {
        return medicamento.getFrequencia() == FrequenciaMedicamento.DIAS_ALTERNADOS ? 2
                : medicamento.getFrequencia() == FrequenciaMedicamento.SEMANAL ? 7 : 1;
    }

    // Sem quantidade por dose (ou com zero, que dividiria por zero), conta 1 unidade.
    private static int consumoPorDose(Medicamento medicamento) {
        Integer porDose = medicamento.getQuantidadePorDose();
        return porDose == null || porDose <= 0 ? 1 : porDose;
    }

    private static List<LocalTime> horariosEmOrdem(Medicamento medicamento) {
        return medicamento.getHorarios().stream().map(Horario::getHora).sorted().toList();
    }

    private static String chave(Long medicamentoId, LocalDate dia, LocalTime hora) {
        return medicamentoId + "|" + dia + "|" + minutos(hora);
    }

    private static int minutos(LocalTime hora) {
        return hora.getHour() * 60 + hora.getMinute();
    }

    private static String quando(Dose dose, LocalDate hoje) {
        String dia = dose.dia().equals(hoje) ? "hoje"
                : dose.dia().equals(hoje.plusDays(1)) ? "amanhã" : dose.dia().format(DATA_COM_SEMANA);
        return dia + " às " + dose.hora().format(HORA);
    }

    private static String formatar(LocalDate data) {
        return data == null ? "não informado" : data.format(DATA_BR);
    }

    // Dosagem é opcional: sem ela, só o nome (nada de "Losartana null").
    private static String nomeComDosagem(Medicamento medicamento) {
        String dosagem = medicamento.getDosagem();
        return dosagem == null || dosagem.isBlank() ? medicamento.getNome() : medicamento.getNome() + " " + dosagem;
    }

    private static String quantidadeEntreParenteses(Medicamento medicamento) {
        return medicamento.getQuantidadePorDose() == null ? ""
                : " (" + quantidade(medicamento, medicamento.getQuantidadePorDose()) + ")";
    }

    private static String quantidade(Medicamento medicamento, int valor) {
        boolean uma = valor == 1;
        String unidade = switch (medicamento.getForma()) {
            case COMPRIMIDO -> uma ? "comprimido" : "comprimidos";
            case CAPSULA -> uma ? "cápsula" : "cápsulas";
            case GOTA -> uma ? "gota" : "gotas";
            case XAROPE -> "ml";
            case INJECAO -> uma ? "ampola" : "ampolas";
            case POMADA -> uma ? "aplicação" : "aplicações";
        };
        return valor + " " + unidade;
    }

    private static String nomeDaForma(FormaMedicamento forma) {
        return switch (forma) {
            case COMPRIMIDO -> "comprimido";
            case CAPSULA -> "cápsula";
            case GOTA -> "gotas";
            case XAROPE -> "xarope";
            case INJECAO -> "injeção";
            case POMADA -> "pomada";
        };
    }

    private static String nomeDaFrequencia(FrequenciaMedicamento frequencia) {
        return switch (frequencia) {
            case UMA_VEZ_AO_DIA -> "1 vez ao dia";
            case DUAS_VEZES_AO_DIA -> "2 vezes ao dia";
            case TRES_VEZES_AO_DIA -> "3 vezes ao dia";
            case A_CADA_8_HORAS -> "a cada 8 horas";
            case DIAS_ALTERNADOS -> "dias alternados";
            case SEMANAL -> "uma vez por semana";
        };
    }

    private static String nomeDoStatus(StatusHistorico status) {
        return switch (status) {
            case TOMADO -> "tomada";
            case ATRASADO -> "atrasada";
            case PERDIDO -> "perdida";
        };
    }
}
