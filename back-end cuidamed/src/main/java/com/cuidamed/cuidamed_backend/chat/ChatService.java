package com.cuidamed.cuidamed_backend.chat;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.configuracao.FusoHorario;
import com.cuidamed.cuidamed_backend.historico.HistoricoRepository;
import com.cuidamed.cuidamed_backend.medicamento.MedicamentoRepository;
import com.cuidamed.cuidamed_backend.paciente.Paciente;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;
import com.cuidamed.cuidamed_backend.vinculo.SituacaoVinculo;
import com.cuidamed.cuidamed_backend.vinculo.VinculoRepository;

@Service
public class ChatService {

    private static final Logger LOG = LoggerFactory.getLogger(ChatService.class);
    private static final String RESPOSTA_INDISPONIVEL = "Não consegui responder agora, tente novamente.";
    private static final String ANTHROPIC_VERSION = "2023-06-01";
    private static final int MAX_TOKENS = 1000;

    private static final String SYSTEM_PROMPT = """
            Você é o assistente virtual do CuidaMed, um aplicativo de lembretes de \
            medicamentos para idosos. Você conversa diretamente com o paciente, responde sobre \
            os medicamentos dele e ensina a usar o aplicativo.

            Regras que você deve seguir sempre:
            - Sobre os medicamentos, responda apenas com base nos dados do paciente fornecidos nesta \
            conversa (medicamentos, horários, período, estoque, observações e doses). Não invente informações.
            - Sobre como usar o aplicativo, responda apenas com base no GUIA DO APLICATIVO abaixo, \
            em passos curtos e numerados, com os nomes dos botões como estão no guia. Siga o aparelho \
            informado na mensagem do paciente. Não invente telas nem botões.
            - Se o paciente pedir para inserir, editar ou excluir remédios e os dados disserem que ele \
            não pode, não ensine o passo a passo: explique que só o cuidador pode fazer isso ou liberar \
            a permissão.
            - A próxima dose, a situação das doses e a duração do estoque já vêm calculadas: \
            use como estão, sem refazer as contas.
            - Quando o estoque não bastar até o fim do tratamento, diga quanto precisa comprar, \
            na unidade informada nos dados. Não fale em caixas ou frascos, porque o tamanho da \
            embalagem não está nos dados. Em uso contínuo não há total a comprar: informe só \
            quanto o estoque dura.
            - Se a resposta exata não estiver nos dados nem no guia, diga que não tem essa informação e \
            oriente o paciente a falar com o cuidador, citando o nome do cuidador. Se o paciente \
            não tiver cuidador, oriente a falar com o médico.
            - Nunca prescreva, diagnostique ou dê qualquer tipo de conselho médico. Isso inclui \
            dizer se deve tomar uma dose atrasada ou perdida, repetir, pular ou parar um remédio. \
            Nesses casos, oriente a falar com o cuidador ou com o médico.
            - Seja direto, breve e use linguagem simples e acessível para idosos. Evite \
            termos técnicos.
            - Escreva em texto simples, sem asteriscos, títulos ou qualquer outra marcação: \
            o aplicativo mostra a resposta exatamente como você escreve. Para passos, use só \
            números (1., 2., 3.).
            - Se a pergunta fugir dos medicamentos do próprio paciente e do uso do aplicativo, \
            explique educadamente que você só pode ajudar com isso.
            - Você só responde perguntas: não registra doses, não altera nada no aplicativo e \
            não envia avisos, lembretes nem mensagens depois. Nunca diga que fez alguma dessas \
            coisas nem prometa avisar o paciente no futuro (os lembretes são feitos pelo próprio \
            aplicativo). Se ele pedir para você fazer algo assim, diga que não consegue e ensine \
            como fazer, se estiver no guia.
            """;

    private static final String INSTRUCOES = SYSTEM_PROMPT + "\nGUIA DO APLICATIVO:\n" + carregarGuia();

    private final PacienteRepository pacienteRepository;
    private final MedicamentoRepository medicamentoRepository;
    private final HistoricoRepository historicoRepository;
    private final VinculoRepository vinculoRepository;
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
            VinculoRepository vinculoRepository,
            RestTemplate restTemplate) {
        this.pacienteRepository = pacienteRepository;
        this.medicamentoRepository = medicamentoRepository;
        this.historicoRepository = historicoRepository;
        this.vinculoRepository = vinculoRepository;
        this.restTemplate = restTemplate;
    }

    public ChatRespostaDTO perguntar(Long pacienteId, ChatMensagemDTO dto) {
        if (dto.mensagem() == null || dto.mensagem().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe a mensagem.");
        }

        Paciente paciente = pacienteRepository.findById(pacienteId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Paciente não encontrado."));

        String contexto = montarContexto(paciente);
        String conteudoUsuario = contexto + "\nAPARELHO: " + descreverAparelho(dto.plataforma())
                + "\n\nPERGUNTA DO PACIENTE: " + dto.mensagem();

        AnthropicRequisicao requisicao = new AnthropicRequisicao(
                modelo, MAX_TOKENS, INSTRUCOES, List.of(new AnthropicMensagem("user", conteudoUsuario)));

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
            return new ChatRespostaDTO(semFormatacao(texto));
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

    static String carregarGuia() {
        try {
            return new ClassPathResource("chat/guia-do-paciente.txt").getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException erro) {
            throw new UncheckedIOException("Guia do paciente não encontrado", erro);
        }
    }

    // O valor vem do cliente: nunca entra no texto, só escolhe uma das frases abaixo.
    static String descreverAparelho(String plataforma) {
        return switch (plataforma == null ? "" : plataforma) {
            case "site" -> "site, no navegador. Nos passos, diga \"clique\" e siga o que o guia diz para o site.";
            case "app" -> "aplicativo. Nos passos, diga \"toque\" e siga o que o guia diz para o aplicativo.";
            default -> "não informado. Nos passos, diga \"escolha\" e cite o site e o aplicativo quando forem diferentes.";
        };
    }

    // O prompt já pede texto simples; isto garante caso a IA use marcação mesmo assim.
    static String semFormatacao(String texto) {
        return texto
                .replaceAll("(?m)^#{1,6}\\s+", "")
                .replaceAll("(?m)^(\\s*)\\*\\s+", "$1- ")
                .replaceAll("\\*\\*|__", "")
                .replaceAll("(?<![\\p{L}\\p{N}*])\\*(?=\\S)(.+?)(?<=\\S)\\*(?![\\p{L}\\p{N}*])", "$1");
    }

    private String montarContexto(Paciente paciente) {
        String nomeCuidador = vinculoRepository
                .findFirstByPacienteIdAndSituacao(paciente.getId(), SituacaoVinculo.ATIVO)
                .map(vinculo -> vinculo.getCuidador().getNome())
                .orElse(null);
        return ContextoDoChat.montar(
                paciente,
                nomeCuidador,
                medicamentoRepository.findByPacienteId(paciente.getId()),
                historicoRepository.findByPacienteIdOrderByDataDescHoraDesc(paciente.getId()),
                LocalDateTime.now(FusoHorario.BRASIL));
    }
}
