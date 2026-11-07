package com.cuidamed.cuidamed_backend.conta;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDate;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.annotation.Transactional;

import com.cuidamed.cuidamed_backend.configuracao.FusoHorario;
import com.cuidamed.cuidamed_backend.seguranca.ServicoToken;
import com.cuidamed.cuidamed_backend.seguranca.UsuarioAutenticado;
import com.jayway.jsonpath.JsonPath;

/** Histórico por período. Roda numa transação desfeita no fim: nada fica no banco. */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class HistoricoPorPeriodoTest {

    @Autowired private MockMvc mvc;
    @Autowired private ServicoToken servicoToken;

    private ResultActions postar(String url, String json, String token) throws Exception {
        var requisicao = post(url).contentType(MediaType.APPLICATION_JSON).content(json);
        return mvc.perform(token == null ? requisicao : requisicao.header(HttpHeaders.AUTHORIZATION, token));
    }

    private static long idDe(ResultActions resposta) throws Exception {
        return ((Number) JsonPath.read(resposta.andReturn().getResponse().getContentAsString(), "$.id")).longValue();
    }

    @Test
    void filtraPorPeriodoENaoMostraOutroPaciente() throws Exception {
        long paciente = idDe(postar("/api/pacientes",
                "{\"nome\":\"Periodo\",\"email\":\"periodo." + System.nanoTime() + "@teste.com\",\"senha\":\"senha1234\"}", null)
                .andExpect(status().isCreated()));
        String token = "Bearer " + servicoToken.gerar(UsuarioAutenticado.PACIENTE, paciente);
        LocalDate hoje = FusoHorario.hoje();
        LocalDate antiga = hoje.minusDays(40);
        long medicamento = idDe(postar("/api/medicamentos",
                "{\"pacienteId\":" + paciente + ",\"nome\":\"Remedio\",\"forma\":\"COMPRIMIDO\",\"frequencia\":\"UMA_VEZ_AO_DIA\","
                        + "\"dataInicio\":\"" + antiga + "\",\"horarios\":[\"08:00\"],\"quantidadeEstoque\":10,\"quantidadePorDose\":1}", token)
                .andExpect(status().isCreated()));
        for (LocalDate dia : new LocalDate[] {antiga, hoje}) {
            postar("/api/historicos", "{\"pacienteId\":" + paciente + ",\"medicamentoId\":" + medicamento
                    + ",\"data\":\"" + dia + "\",\"hora\":\"08:00\",\"status\":\"TOMADO\"}", token).andExpect(status().isCreated());
        }
        String url = "/api/pacientes/" + paciente + "/historicos";

        mvc.perform(get(url).header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(jsonPath("$.length()").value(2));
        mvc.perform(get(url + "?de=" + hoje.minusDays(31)).header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].data").value(hoje.toString()));
        mvc.perform(get(url + "?de=" + antiga + "&ate=" + hoje.minusDays(32)).header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].data").value(antiga.toString()));

        long outro = idDe(postar("/api/pacientes",
                "{\"nome\":\"Outro\",\"email\":\"outro." + System.nanoTime() + "@teste.com\",\"senha\":\"senha1234\"}", null));
        mvc.perform(get(url + "?de=" + antiga).header(HttpHeaders.AUTHORIZATION, "Bearer " + servicoToken.gerar(UsuarioAutenticado.PACIENTE, outro)))
                .andExpect(status().isForbidden());
    }
}
