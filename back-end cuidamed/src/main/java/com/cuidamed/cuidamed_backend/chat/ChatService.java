package com.cuidamed.cuidamed_backend.chat;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.Period;
import java.util.List;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.historico.Historico;
import com.cuidamed.cuidamed_backend.historico.HistoricoRepository;
import com.cuidamed.cuidamed_backend.medicamento.Medicamento;
import com.cuidamed.cuidamed_backend.medicamento.MedicamentoRepository;
import com.cuidamed.cuidamed_backend.paciente.Paciente;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;

@Service
public class ChatService {

    private static final Logger LOG = LoggerFactory.getLogger(ChatService.class);
    private static final String RESPOSTA_INDISPONIVEL = "Não consegui responder agora, tente novamente.";
    private static final String ANTHROPIC_VERSION = "2023-06-01";
    private static final DateTimeFormatter DATA_BR = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private static final String SYSTEM_PROMPT = """
            Você é o assistente virtual do CuidaMed, um aplicativo de lembretes de \
            medicamentos para idosos. Você conversa diretamente com o paciente.

            Regras que você deve seguir sempre:
            - Responda apenas com base nos dados do paciente fornecidos nesta conversa \
            (medicamentos, horários, observações e histórico). Não invente informações.
            - Nunca prescreva, diagnostique ou dê qualquer tipo de conselho médico. Se \
            perguntarem algo desse tipo, explique que isso deve ser conversado com o \
            médico ou cuidador responsável.
            - Seja direto, breve e use linguagem simples e acessível para idosos. Evite \
            termos técnicos.
            - Se a pergunta fugir da rotina de medicamentos do próprio paciente, explique \
            educadamente que você só pode ajudar com isso.
            - Você só responde perguntas: não envia avisos, lembretes nem mensagens depois. \
            Nunca prometa avisar o paciente no futuro (os lembretes são feitos pelo próprio aplicativo).
            """;

    private final PacienteRepository pacienteRepository;
    private final MedicamentoRepository medicamentoRepository;
    private final HistoricoRepository historicoRepository;
    private final RestTemplate restTemplate;

    @Value("${anthropic.api.key}")
    private String chaveApi;

    @Value("${anthropic.api.url}")
    private String urlApi;

    @Value("${anthropic.api.model}")
    private String modelo;

    public ChatService(
            PacienteRepository pacienteRepository,
            MedicamentoRepository medicamentoRepository,
            HistoricoRepository historicoRepository,
            RestTemplate restTemplate) {
        this.pacienteRepository = pacienteRepository;
        this.medicamentoRepository = medicamentoRepository;
        this.historicoRepository = historicoRepository;
        this.restTemplate = restTemplate;
    }

    public ChatRespostaDTO perguntar(Long pacienteId, ChatMensagemDTO dto) {
        if (dto.mensagem() == null || dto.mensagem().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe a mensagem.");
        }

        Paciente paciente = pacienteRepository.findById(pacienteId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Paciente não encontrado."));

        String contexto = montarContexto(paciente);
        String conteudoUsuario = contexto + "\n\nPERGUNTA DO PACIENTE: " + dto.mensagem();

        AnthropicRequisicao requisicao = new AnthropicRequisicao(
                modelo, 500, SYSTEM_PROMPT, List.of(new AnthropicMensagem("user", conteudoUsuario)));

        try {
            HttpHeaders cabecalhos = new HttpHeaders();
            cabecalhos.setContentType(MediaType.APPLICATION_JSON);
            cabecalhos.set("x-api-key", chaveApi);
            cabecalhos.set("anthropic-version", ANTHROPIC_VERSION);

            AnthropicResposta resposta = restTemplate.postForObject(
                    urlApi, new HttpEntity<>(requisicao, cabecalhos), AnthropicResposta.class);

            String texto = extrairTexto(resposta);
            if (texto == null) {
                LOG.warn("Resposta da Anthropic sem conteúdo de texto: {}", resposta);
                return new ChatRespostaDTO(RESPOSTA_INDISPONIVEL);
            }
            return new ChatRespostaDTO(texto);
        } catch (RestClientException erro) {
            LOG.warn("Falha ao chamar a API da Anthropic", erro);
            return new ChatRespostaDTO(RESPOSTA_INDISPONIVEL);
        }
    }

    private String extrairTexto(AnthropicResposta resposta) {
        if (resposta == null || resposta.content() == null || resposta.content().isEmpty()) {
            return null;
        }
        return resposta.content().get(0).text();
    }

    private String montarContexto(Paciente paciente) {
        LocalDate hoje = LocalDate.now();

        StringBuilder texto = new StringBuilder();
        texto.append("DATA DE HOJE: ").append(hoje.format(DATA_BR)).append('\n');
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

        List<Medicamento> naoEncerrados = medicamentoRepository.findByPacienteId(paciente.getId()).stream()
                .filter(medicamento -> medicamento.getDataFim() == null || !medicamento.getDataFim().isBefore(hoje))
                .toList();
        // Tratamento com início no futuro ainda não é "ativo": sem essa separação
        // a IA mandava tomar hoje um remédio que só começa amanhã.
        List<Medicamento> medicamentosAtivos = naoEncerrados.stream()
                .filter(medicamento -> medicamento.getDataInicio() == null || !medicamento.getDataInicio().isAfter(hoje))
                .toList();
        List<Medicamento> aIniciar = naoEncerrados.stream()
                .filter(medicamento -> medicamento.getDataInicio() != null && medicamento.getDataInicio().isAfter(hoje))
                .toList();

        texto.append("\nMEDICAMENTOS ATIVOS:\n");
        if (medicamentosAtivos.isEmpty()) {
            texto.append("Nenhum medicamento ativo no momento.\n");
        } else {
            for (Medicamento medicamento : medicamentosAtivos) {
                String horarios = medicamento.getHorarios().stream()
                        .map(horario -> horario.getHora().toString())
                        .collect(Collectors.joining(", "));
                texto.append("- ").append(medicamento.getNome())
                        .append(" ").append(medicamento.getDosagem())
                        .append(" (").append(medicamento.getForma()).append(", ")
                        .append(medicamento.getFrequencia()).append(")")
                        .append(" — horários: ").append(horarios);
                if (medicamento.getQuantidadePorDose() != null) {
                    texto.append(" — quantidade por dose: ").append(medicamento.getQuantidadePorDose());
                }
                if (medicamento.getDataFim() != null) {
                    texto.append(" — até ").append(medicamento.getDataFim().format(DATA_BR));
                }
                texto.append(medicamento.temDoseEm(hoje) ? " — TEM dose hoje" : " — NÃO tem dose hoje");
                texto.append('\n');
                if (medicamento.getObservacoes() != null && !medicamento.getObservacoes().isBlank()) {
                    texto.append("  observações: ").append(medicamento.getObservacoes()).append('\n');
                }
            }
        }

        if (!aIniciar.isEmpty()) {
            texto.append("\nMEDICAMENTOS QUE AINDA VÃO COMEÇAR (não devem ser tomados antes da data de início):\n");
            for (Medicamento medicamento : aIniciar) {
                texto.append("- ").append(medicamento.getNome()).append(" ").append(medicamento.getDosagem())
                        .append(" — começa em ").append(medicamento.getDataInicio().format(DATA_BR)).append('\n');
            }
        }

        LocalDate seteDiasAtras = hoje.minusDays(7);
        List<Historico> historicoRecente = historicoRepository.findByPacienteIdOrderByDataDescHoraDesc(paciente.getId())
                .stream()
                .filter(historico -> !historico.getData().isBefore(seteDiasAtras))
                .toList();

        texto.append("\nHISTÓRICO DOS ÚLTIMOS 7 DIAS:\n");
        if (historicoRecente.isEmpty()) {
            texto.append("Nenhum registro nos últimos 7 dias.\n");
        } else {
            for (Historico historico : historicoRecente) {
                texto.append("- ").append(historico.getData()).append(' ').append(historico.getHora())
                        .append(' ').append(historico.getNomeMedicamento())
                        .append(": ").append(historico.getStatus())
                        .append('\n');
            }
        }

        return texto.toString();
    }
}
