package com.cuidamed.cuidamed_backend;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.zip.GZIPInputStream;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

import com.cuidamed.cuidamed_backend.configuracao.FusoHorario;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;
import com.cuidamed.cuidamed_backend.seguranca.ServicoToken;
import com.cuidamed.cuidamed_backend.seguranca.UsuarioAutenticado;
import com.jayway.jsonpath.JsonPath;

/** Compactação pelo servidor HTTP de verdade. O que é criado aqui é apagado no fim. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class CompactacaoRespostasTest {

    @LocalServerPort private int porta;
    @Autowired private ServicoToken servicoToken;
    @Autowired private PacienteRepository pacienteRepository;

    private final HttpClient cliente = HttpClient.newHttpClient();

    private String postar(String caminho, String json, String token) throws Exception {
        HttpRequest.Builder requisicao = HttpRequest.newBuilder(URI.create("http://localhost:" + porta + caminho))
                .header("Content-Type", "application/json").POST(HttpRequest.BodyPublishers.ofString(json));
        if (token != null) {
            requisicao.header("Authorization", token);
        }
        return cliente.send(requisicao.build(), HttpResponse.BodyHandlers.ofString()).body();
    }

    @Test
    void historicoGrandeVemCompactadoParaQuemAceitaGzip() throws Exception {
        long paciente = ((Number) JsonPath.read(postar("/api/pacientes",
                "{\"nome\":\"Gzip\",\"email\":\"gzip." + System.nanoTime() + "@teste.com\",\"senha\":\"senha1234\"}", null), "$.id")).longValue();
        String token = "Bearer " + servicoToken.gerar(UsuarioAutenticado.PACIENTE, paciente);
        try {
            LocalDate hoje = FusoHorario.hoje();
            long medicamento = ((Number) JsonPath.read(postar("/api/medicamentos",
                    "{\"pacienteId\":" + paciente + ",\"nome\":\"Remedio\",\"forma\":\"COMPRIMIDO\",\"frequencia\":\"UMA_VEZ_AO_DIA\","
                            + "\"dataInicio\":\"" + hoje.minusDays(20) + "\",\"horarios\":[\"08:00\"],\"quantidadeEstoque\":100,\"quantidadePorDose\":1}", token), "$.id")).longValue();
            for (int dias = 1; dias <= 20; dias++) {
                postar("/api/historicos", "{\"pacienteId\":" + paciente + ",\"medicamentoId\":" + medicamento
                        + ",\"data\":\"" + hoje.minusDays(dias) + "\",\"hora\":\"08:00\",\"status\":\"TOMADO\"}", token);
            }

            URI historico = URI.create("http://localhost:" + porta + "/api/pacientes/" + paciente + "/historicos");
            HttpResponse<byte[]> compactada = cliente.send(
                    HttpRequest.newBuilder(historico).header("Authorization", token).header("Accept-Encoding", "gzip").build(),
                    HttpResponse.BodyHandlers.ofByteArray());
            HttpResponse<String> normal = cliente.send(
                    HttpRequest.newBuilder(historico).header("Authorization", token).build(), HttpResponse.BodyHandlers.ofString());

            assertThat(compactada.headers().firstValue("Content-Encoding")).contains("gzip");
            assertThat(normal.headers().firstValue("Content-Encoding")).isEmpty();
            assertThat(compactada.body().length).isLessThan(normal.body().length() / 2);
            try (GZIPInputStream gzip = new GZIPInputStream(new ByteArrayInputStream(compactada.body()))) {
                assertThat(new String(gzip.readAllBytes(), StandardCharsets.UTF_8)).isEqualTo(normal.body());
            }
        } finally {
            pacienteRepository.deleteById(paciente);
        }
    }
}
