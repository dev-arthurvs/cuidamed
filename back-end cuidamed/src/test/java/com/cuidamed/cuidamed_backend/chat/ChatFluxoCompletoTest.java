package com.cuidamed.cuidamed_backend.chat;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.client.RestTemplate;

import com.cuidamed.cuidamed_backend.configuracao.FusoHorario;
import com.cuidamed.cuidamed_backend.medicamento.MedicamentoRepository;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;
import com.cuidamed.cuidamed_backend.seguranca.ServicoToken;
import com.cuidamed.cuidamed_backend.seguranca.UsuarioAutenticado;
import com.jayway.jsonpath.JsonPath;

/**
 * O chat de ponta a ponta, com a Anthropic simulada (não gasta a chave). Sem
 * transação no teste, como em produção; o que é criado aqui é apagado no fim.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ChatFluxoCompletoTest {

    @Autowired private MockMvc mvc;
    @Autowired private ServicoToken servicoToken;
    @Autowired private PacienteRepository pacienteRepository;
    @Autowired private MedicamentoRepository medicamentoRepository;

    @MockitoBean private RestTemplate restTemplate;

    @Test
    void respondeComOsDadosDoPacienteSemPrenderOBancoDuranteAChamada() throws Exception {
        String resposta = mvc.perform(post("/api/pacientes").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nome\":\"Paciente Chat\",\"email\":\"chat." + System.nanoTime() + "@teste.com\",\"senha\":\"senha1234\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        long paciente = ((Number) JsonPath.read(resposta, "$.id")).longValue();
        String token = "Bearer " + servicoToken.gerar(UsuarioAutenticado.PACIENTE, paciente);
        try {
            mvc.perform(post("/api/medicamentos").contentType(MediaType.APPLICATION_JSON).header(HttpHeaders.AUTHORIZATION, token)
                            .content("{\"pacienteId\":" + paciente + ",\"nome\":\"Losartana\",\"forma\":\"COMPRIMIDO\",\"frequencia\":\"UMA_VEZ_AO_DIA\","
                                    + "\"dataInicio\":\"" + FusoHorario.hoje() + "\",\"horarios\":[\"08:00\"],\"quantidadeEstoque\":10,\"quantidadePorDose\":1}"))
                    .andExpect(status().isCreated());

            AtomicReference<AnthropicRequisicao> enviada = new AtomicReference<>();
            AtomicBoolean bancoLivre = new AtomicBoolean();
            when(restTemplate.postForObject(anyString(), any(HttpEntity.class), eq(AnthropicResposta.class))).thenAnswer(chamada -> {
                HttpEntity<?> corpo = chamada.getArgument(1);
                enviada.set((AnthropicRequisicao) corpo.getBody());
                bancoLivre.set(!TransactionSynchronizationManager.isActualTransactionActive()
                        && TransactionSynchronizationManager.getResourceMap().isEmpty());
                return new AnthropicResposta(List.of(new AnthropicConteudo("text", "Tome a **Losartana** às 08:00.")));
            });

            mvc.perform(post("/api/chat/" + paciente).contentType(MediaType.APPLICATION_JSON).header(HttpHeaders.AUTHORIZATION, token)
                            .content("{\"mensagem\":\"Qual meu remédio?\",\"plataforma\":\"site\"}"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.resposta").value("Tome a Losartana às 08:00."));

            assertThat(bancoLivre).as("nenhuma conexão ou sessão do banco presa durante a chamada à IA").isTrue();
            assertThat(enviada.get().system()).contains("GUIA DO APLICATIVO", "Atualizar senha");
            String mensagem = enviada.get().messages().get(0).content();
            assertThat(mensagem).contains("Paciente Chat", "Losartana", "estoque: 10 comprimidos", "APARELHO: site", "Qual meu remédio?");
        } finally {
            medicamentoRepository.deleteAll(medicamentoRepository.findByPacienteId(paciente));
            pacienteRepository.deleteById(paciente);
        }
    }
}
