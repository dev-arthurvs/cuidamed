package com.cuidamed.cuidamed_backend.seguranca;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Regras de acesso da API. Usa ids que não existem no banco (Long.MAX_VALUE),
 * então nenhum teste lê ou altera dados reais.
 */
@SpringBootTest
@AutoConfigureMockMvc
class SegurancaTest {

    private static final long ID_INEXISTENTE = Long.MAX_VALUE;

    @Autowired
    private MockMvc mvc;

    @Autowired
    private ServicoToken servicoToken;

    private String bearer(String tipo, long id) {
        return "Bearer " + servicoToken.gerar(tipo, id);
    }

    @Test
    void semTokenRecebe401ComMensagem() throws Exception {
        mvc.perform(get("/api/pacientes/1"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Sua sessão expirou. Entre novamente."));
    }

    @Test
    void tokenFalsoRecebe401() throws Exception {
        mvc.perform(get("/api/pacientes/1").header(HttpHeaders.AUTHORIZATION, "Bearer abc.def.ghi"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void chatSemTokenNaoGastaAChaveDaAnthropic() throws Exception {
        mvc.perform(post("/api/chat/1").contentType(MediaType.APPLICATION_JSON).content("{\"mensagem\":\"oi\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void pacienteNaoVeOutroPaciente() throws Exception {
        mvc.perform(get("/api/pacientes/1").header(HttpHeaders.AUTHORIZATION, bearer(UsuarioAutenticado.PACIENTE, ID_INEXISTENTE)))
                .andExpect(status().isForbidden());
    }

    @Test
    void cuidadorNaoVePacienteQueNaoEDele() throws Exception {
        mvc.perform(get("/api/pacientes/1").header(HttpHeaders.AUTHORIZATION, bearer(UsuarioAutenticado.CUIDADOR, ID_INEXISTENTE)))
                .andExpect(status().isForbidden());
    }

    @Test
    void cuidadorNaoUsaOChatDoPaciente() throws Exception {
        mvc.perform(post("/api/chat/1")
                        .header(HttpHeaders.AUTHORIZATION, bearer(UsuarioAutenticado.CUIDADOR, ID_INEXISTENTE))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"mensagem\":\"oi\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void pacienteNaoListaPacientesDeUmCuidador() throws Exception {
        mvc.perform(get("/api/cuidadores/1/pacientes")
                        .header(HttpHeaders.AUTHORIZATION, bearer(UsuarioAutenticado.PACIENTE, ID_INEXISTENTE)))
                .andExpect(status().isForbidden());
    }

    @Test
    void loginBloqueiaDepoisDe5SenhasErradasNoMesmoEmail() throws Exception {
        String corpo = "{\"email\":\"ninguem." + System.nanoTime() + "@teste.com\",\"senha\":\"errada123\"}";
        for (int i = 0; i < 5; i++) {
            mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(corpo))
                    .andExpect(status().isUnauthorized());
        }
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(corpo))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.message").value("Muitas tentativas de login. Aguarde 15 minutos e tente de novo."));
    }

    @Test
    void chatLimitaPerguntasPorHora() throws Exception {
        // Paciente inexistente: cada pergunta para no "não encontrado" (sem chamar a IA),
        // mas conta no limite, que é conferido antes.
        String token = bearer(UsuarioAutenticado.PACIENTE, ID_INEXISTENTE - 1);
        for (int i = 0; i < 30; i++) {
            mvc.perform(post("/api/chat/" + (ID_INEXISTENTE - 1)).header(HttpHeaders.AUTHORIZATION, token)
                            .contentType(MediaType.APPLICATION_JSON).content("{\"mensagem\":\"oi\"}"))
                    .andExpect(status().isNotFound());
        }
        mvc.perform(post("/api/chat/" + (ID_INEXISTENTE - 1)).header(HttpHeaders.AUTHORIZATION, token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"mensagem\":\"oi\"}"))
                .andExpect(status().isTooManyRequests());
    }

    @Test
    void ativacaoBloqueiaDepoisDe5CodigosErrados() throws Exception {
        String corpo = "{\"email\":\"ninguem." + System.nanoTime() + "@teste.com\",\"codigo\":\"XXXXXX\",\"novaSenha\":\"senha1234\"}";
        for (int i = 0; i < 5; i++) {
            mvc.perform(post("/api/pacientes/definir-senha").contentType(MediaType.APPLICATION_JSON).content(corpo))
                    .andExpect(status().isBadRequest());
        }
        mvc.perform(post("/api/pacientes/definir-senha").contentType(MediaType.APPLICATION_JSON).content(corpo))
                .andExpect(status().isTooManyRequests());
    }

    @Test
    void autocadastroDePacienteExigeSenhaDe8Caracteres() throws Exception {
        mvc.perform(post("/api/pacientes").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"nome\":\"Teste\",\"email\":\"x" + System.nanoTime() + "@teste.com\",\"senha\":\"123\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("A senha deve ter no mínimo 8 caracteres."));
    }

    @Test
    void healthCheckEPublicoParaORailway() throws Exception {
        mvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void enderecoInexistenteResponde404SemErroInterno() throws Exception {
        mvc.perform(get("/api/nao-existe").header(HttpHeaders.AUTHORIZATION, bearer(UsuarioAutenticado.CUIDADOR, ID_INEXISTENTE)))
                .andExpect(status().isNotFound());
    }

    @Test
    void corsLiberaOSiteDoApp() throws Exception {
        mvc.perform(options("/api/pacientes/1")
                        .header(HttpHeaders.ORIGIN, "http://localhost:5173")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "authorization"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:5173"));
    }

    @Test
    void corsBloqueiaOutrosSites() throws Exception {
        mvc.perform(options("/api/pacientes/1")
                        .header(HttpHeaders.ORIGIN, "https://site-malicioso.com")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET"))
                .andExpect(status().isForbidden());
    }
}
