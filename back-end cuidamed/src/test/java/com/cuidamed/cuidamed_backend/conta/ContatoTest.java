package com.cuidamed.cuidamed_backend.conta;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.annotation.Transactional;

/**
 * Login por e-mail ou telefone e cadastro sem e-mail. Cada teste roda numa
 * transação desfeita no fim: as contas criadas aqui não ficam no banco.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class ContatoTest {

    @Autowired
    private MockMvc mvc;

    /** Celular que não existe no banco: (11) 9xxxx-xxxx a partir do relógio. */
    private static String telefoneNovo() {
        String n = String.valueOf(System.nanoTime());
        String oito = n.substring(n.length() - 8);
        return "(11) 9" + oito.substring(0, 4) + "-" + oito.substring(4);
    }

    private ResultActions postar(String url, String json) throws Exception {
        return mvc.perform(post(url).contentType(MediaType.APPLICATION_JSON).content(json));
    }

    @Test
    void pacienteSemEmailCadastraComTelefoneEEntraPeloTelefone() throws Exception {
        String telefone = telefoneNovo();
        postar("/api/pacientes", "{\"nome\":\"Idosa Sem Email\",\"senha\":\"senha1234\",\"telefone\":\"" + telefone + "\"}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email").doesNotExist());

        // Com máscara, só os dígitos ou com o 55 do Brasil: mesmo telefone.
        String digitos = Contato.digitos(telefone);
        for (String login : new String[] {telefone, digitos, "+55 " + digitos}) {
            postar("/api/auth/login", "{\"login\":\"" + login + "\",\"senha\":\"senha1234\"}")
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.tipo").value("PACIENTE"));
        }
        postar("/api/auth/login", "{\"login\":\"" + telefone + "\",\"senha\":\"errada123\"}")
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("E-mail, telefone ou senha inválidos."));
    }

    @Test
    void cadastroSemEmailENemTelefoneEhRecusado() throws Exception {
        postar("/api/pacientes", "{\"nome\":\"Sem Contato\",\"senha\":\"senha1234\"}")
                .andExpect(status().isBadRequest());
        postar("/api/cuidadores", "{\"nome\":\"Sem Contato\",\"senha\":\"senha1234\"}")
                .andExpect(status().isBadRequest());
    }

    @Test
    void telefoneRepetidoEmOutraContaEhRecusado() throws Exception {
        String telefone = telefoneNovo();
        postar("/api/pacientes", "{\"nome\":\"Primeira\",\"senha\":\"senha1234\",\"telefone\":\"" + telefone + "\"}")
                .andExpect(status().isCreated());
        postar("/api/cuidadores", "{\"nome\":\"Segundo\",\"senha\":\"senha1234\",\"telefone\":\"" + Contato.digitos(telefone) + "\"}")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Esse telefone já está cadastrado em outra conta."));
    }

    @Test
    void cuidadorSemEmailEntraPeloTelefoneEContinuaEntrandoPorEmailQuandoTem() throws Exception {
        String telefone = telefoneNovo();
        postar("/api/cuidadores", "{\"nome\":\"Cuidador Sem Email\",\"senha\":\"senha1234\",\"telefone\":\"" + telefone + "\"}")
                .andExpect(status().isCreated());
        postar("/api/auth/login", "{\"login\":\"" + telefone + "\",\"senha\":\"senha1234\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tipo").value("CUIDADOR"));

        String email = "com.email." + System.nanoTime() + "@teste.com";
        postar("/api/pacientes", "{\"nome\":\"Com Email\",\"email\":\"" + email + "\",\"senha\":\"senha1234\"}")
                .andExpect(status().isCreated());
        // Campo antigo "email" (versões anteriores do app) continua funcionando.
        postar("/api/auth/login", "{\"email\":\"" + email + "\",\"senha\":\"senha1234\"}").andExpect(status().isOk());
    }

    @Test
    void telefoneIncompletoEhRecusado() throws Exception {
        postar("/api/pacientes", "{\"nome\":\"Fone Curto\",\"senha\":\"senha1234\",\"telefone\":\"9999-0000\"}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Informe o telefone com DDD."));
    }

    @Test
    void normalizacaoDoTelefone() {
        assertThat(Contato.digitos("(79) 99999-0000")).isEqualTo("79999990000");
        assertThat(Contato.digitos("+55 79 99999-0000")).isEqualTo("79999990000");
        assertThat(Contato.ehEmail("maria@email.com")).isTrue();
        assertThat(Contato.ehEmail("79999990000")).isFalse();
        assertThat(Contato.chaveLimite("(79) 99999-0000")).isEqualTo(Contato.chaveLimite("79999990000"));
    }
}
