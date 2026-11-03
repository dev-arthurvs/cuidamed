package com.cuidamed.cuidamed_backend.conta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDateTime;
import java.util.TimeZone;

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
import com.cuidamed.cuidamed_backend.paciente.Paciente;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;
import com.cuidamed.cuidamed_backend.seguranca.ServicoToken;
import com.cuidamed.cuidamed_backend.seguranca.UsuarioAutenticado;
import com.jayway.jsonpath.JsonPath;

/**
 * Código de nova senha gerado pelo cuidador e "desfazer" dose. Cada teste roda
 * numa transação desfeita no fim: nada do que é criado aqui fica no banco.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class RecuperacaoEDesfazerTest {

    @Autowired
    private MockMvc mvc;

    @Autowired
    private ServicoToken servicoToken;

    @Autowired
    private PacienteRepository pacienteRepository;

    private static String email(String prefixo) {
        return prefixo + "." + System.nanoTime() + "@teste.com";
    }

    private String bearer(String tipo, Number id) {
        return "Bearer " + servicoToken.gerar(tipo, id.longValue());
    }

    private ResultActions postar(String url, String json, String token) throws Exception {
        var requisicao = post(url).contentType(MediaType.APPLICATION_JSON).content(json);
        if (token != null) {
            requisicao = requisicao.header(HttpHeaders.AUTHORIZATION, token);
        }
        return mvc.perform(requisicao);
    }

    private Number idDe(ResultActions resposta) throws Exception {
        return JsonPath.read(resposta.andReturn().getResponse().getContentAsString(), "$.id");
    }

    /** Paciente com senha, ligado a um cuidador pelo fluxo de pedido + aceite. */
    private long[] pacienteComCuidador(String emailPaciente) throws Exception {
        long paciente = idDe(postar("/api/pacientes",
                "{\"nome\":\"Paciente\",\"email\":\"" + emailPaciente + "\",\"senha\":\"senhaantiga\"}", null)
                .andExpect(status().isCreated())).longValue();
        String emailCuidador = email("cuidador");
        long cuidador = idDe(postar("/api/cuidadores",
                "{\"nome\":\"Cuidador\",\"email\":\"" + emailCuidador + "\",\"senha\":\"senha1234\"}", null)
                .andExpect(status().isCreated())).longValue();
        postar("/api/pacientes/" + paciente + "/solicitar-vinculo", "{\"cuidadorEmail\":\"" + emailCuidador + "\"}",
                bearer(UsuarioAutenticado.PACIENTE, paciente)).andExpect(status().isNoContent());
        postar("/api/pacientes/" + paciente + "/aceitar-vinculo", "{}", bearer(UsuarioAutenticado.CUIDADOR, cuidador))
                .andExpect(status().isNoContent());
        return new long[] {paciente, cuidador};
    }

    @Test
    void cuidadorGeraCodigoEPacienteCriaSenhaNova() throws Exception {
        String emailPaciente = email("paciente");
        long[] ids = pacienteComCuidador(emailPaciente);
        String tokenCuidador = bearer(UsuarioAutenticado.CUIDADOR, ids[1]);

        String resposta = postar("/api/pacientes/" + ids[0] + "/codigo-nova-senha", "{}", tokenCuidador)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.codigoNovaSenha").value(true))
                .andReturn().getResponse().getContentAsString();
        String codigo = JsonPath.read(resposta, "$.codigoAtivacao");
        assertThat(codigo).hasSize(6);

        // A senha antiga vale até o código ser usado.
        postar("/api/auth/login", "{\"login\":\"" + emailPaciente + "\",\"senha\":\"senhaantiga\"}", null)
                .andExpect(status().isOk());

        postar("/api/pacientes/definir-senha",
                "{\"login\":\"" + emailPaciente + "\",\"codigo\":\"" + codigo + "\",\"novaSenha\":\"senhanova1\"}", null)
                .andExpect(status().isNoContent());

        postar("/api/auth/login", "{\"login\":\"" + emailPaciente + "\",\"senha\":\"senhanova1\"}", null)
                .andExpect(status().isOk());
        postar("/api/auth/login", "{\"login\":\"" + emailPaciente + "\",\"senha\":\"senhaantiga\"}", null)
                .andExpect(status().isUnauthorized());

        // O código só vale uma vez.
        postar("/api/pacientes/definir-senha",
                "{\"login\":\"" + emailPaciente + "\",\"codigo\":\"" + codigo + "\",\"novaSenha\":\"outrasenha1\"}", null)
                .andExpect(status().isBadRequest());
    }

    @Test
    void codigoVencidoNaoVale() throws Exception {
        String emailPaciente = email("vencido");
        long[] ids = pacienteComCuidador(emailPaciente);
        postar("/api/pacientes/" + ids[0] + "/codigo-nova-senha", "{}", bearer(UsuarioAutenticado.CUIDADOR, ids[1]))
                .andExpect(status().isOk());

        Paciente paciente = pacienteRepository.findById(ids[0]).orElseThrow();
        String codigo = paciente.getCodigoValido();
        paciente.setCodigoExpiraEm(LocalDateTime.now().minusMinutes(1));
        pacienteRepository.saveAndFlush(paciente);

        postar("/api/pacientes/definir-senha",
                "{\"login\":\"" + emailPaciente + "\",\"codigo\":\"" + codigo + "\",\"novaSenha\":\"senhanova1\"}", null)
                .andExpect(status().isBadRequest());
        mvc.perform(get("/api/pacientes/" + ids[0]).header(HttpHeaders.AUTHORIZATION, bearer(UsuarioAutenticado.CUIDADOR, ids[1])))
                .andExpect(jsonPath("$.codigoAtivacao").doesNotExist());
    }

    @Test
    void soOCuidadorVinculadoGeraOCodigo() throws Exception {
        long[] ids = pacienteComCuidador(email("regra"));
        postar("/api/pacientes/" + ids[0] + "/codigo-nova-senha", "{}", bearer(UsuarioAutenticado.PACIENTE, ids[0]))
                .andExpect(status().isForbidden());
        long outro = idDe(postar("/api/cuidadores",
                "{\"nome\":\"Outro\",\"email\":\"" + email("outro") + "\",\"senha\":\"senha1234\"}", null)).longValue();
        postar("/api/pacientes/" + ids[0] + "/codigo-nova-senha", "{}", bearer(UsuarioAutenticado.CUIDADOR, outro))
                .andExpect(status().isBadRequest());
        postar("/api/pacientes/" + ids[0] + "/codigo-nova-senha", "{}", null).andExpect(status().isUnauthorized());
    }

    @Test
    void desfazerApagaORegistroEDevolveOEstoque() throws Exception {
        long paciente = idDe(postar("/api/pacientes",
                "{\"nome\":\"Paciente\",\"email\":\"" + email("desfazer") + "\",\"senha\":\"senha1234\"}", null)).longValue();
        String token = bearer(UsuarioAutenticado.PACIENTE, paciente);
        String hoje = FusoHorario.hoje().toString();
        long medicamento = idDe(postar("/api/medicamentos",
                "{\"pacienteId\":" + paciente + ",\"nome\":\"Remedio\",\"forma\":\"COMPRIMIDO\",\"frequencia\":\"UMA_VEZ_AO_DIA\","
                        + "\"dataInicio\":\"" + hoje + "\",\"horarios\":[\"08:00\"],\"quantidadeEstoque\":10,\"quantidadePorDose\":2}", token)
                .andExpect(status().isCreated())).longValue();
        String corpo = "{\"pacienteId\":" + paciente + ",\"medicamentoId\":" + medicamento + ",\"data\":\"" + hoje
                + "\",\"hora\":\"08:00\",\"status\":\"TOMADO\"}";
        long registro = idDe(postar("/api/historicos", corpo, token).andExpect(status().isCreated())).longValue();
        mvc.perform(get("/api/medicamentos/" + medicamento).header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(jsonPath("$.quantidadeEstoque").value(8));

        // Outro paciente não desfaz.
        long estranho = idDe(postar("/api/pacientes",
                "{\"nome\":\"Estranho\",\"email\":\"" + email("estranho") + "\",\"senha\":\"senha1234\"}", null)).longValue();
        mvc.perform(delete("/api/historicos/" + registro)
                        .header(HttpHeaders.AUTHORIZATION, bearer(UsuarioAutenticado.PACIENTE, estranho)))
                .andExpect(status().isForbidden());

        mvc.perform(delete("/api/historicos/" + registro).header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(status().isNoContent());
        mvc.perform(get("/api/medicamentos/" + medicamento).header(HttpHeaders.AUTHORIZATION, token))
                .andExpect(jsonPath("$.quantidadeEstoque").value(10));

        // A dose pode ser registrada de novo depois de desfazer.
        postar("/api/historicos", corpo, token).andExpect(status().isCreated());
    }

    @Test
    void desfazerUsaODiaDeBrasiliaComOServidorEmOutroFuso() throws Exception {
        long paciente = idDe(postar("/api/pacientes",
                "{\"nome\":\"Paciente\",\"email\":\"" + email("fuso") + "\",\"senha\":\"senha1234\"}", null)).longValue();
        String token = bearer(UsuarioAutenticado.PACIENTE, paciente);
        String hoje = FusoHorario.hoje().toString();
        long medicamento = idDe(postar("/api/medicamentos",
                "{\"pacienteId\":" + paciente + ",\"nome\":\"Remedio\",\"forma\":\"COMPRIMIDO\",\"frequencia\":\"UMA_VEZ_AO_DIA\","
                        + "\"dataInicio\":\"" + hoje + "\",\"horarios\":[\"08:00\"],\"quantidadeEstoque\":10,\"quantidadePorDose\":1}", token)
                .andExpect(status().isCreated())).longValue();
        long registro = idDe(postar("/api/historicos", "{\"pacienteId\":" + paciente + ",\"medicamentoId\":" + medicamento
                + ",\"data\":\"" + hoje + "\",\"hora\":\"08:00\",\"status\":\"TOMADO\"}", token)
                .andExpect(status().isCreated())).longValue();

        // A qualquer hora, um destes dois fusos já está em outro dia em relação a Brasília.
        TimeZone original = TimeZone.getDefault();
        boolean adiantadoMudaODia = !java.time.LocalDate.now(java.time.ZoneId.of("Pacific/Kiritimati")).toString().equals(hoje);
        TimeZone.setDefault(TimeZone.getTimeZone(adiantadoMudaODia ? "Pacific/Kiritimati" : "Etc/GMT+12"));
        try {
            mvc.perform(delete("/api/historicos/" + registro).header(HttpHeaders.AUTHORIZATION, token))
                    .andExpect(status().isNoContent());
        } finally {
            TimeZone.setDefault(original);
        }
    }
}
