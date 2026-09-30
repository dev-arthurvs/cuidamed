package com.cuidamed.cuidamed_backend.configuracao;

import java.util.List;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.client.RestTemplate;

@Configuration
// O CORS (quais sites podem chamar a API) fica em seguranca/ConfiguracaoSeguranca.
public class ConfiguracaoWeb {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public RestTemplate restTemplate() {
        SimpleClientHttpRequestFactory fabrica = new SimpleClientHttpRequestFactory();
        fabrica.setConnectTimeout(10_000);
        fabrica.setReadTimeout(15_000);

        RestTemplate restTemplate = new RestTemplate(fabrica);
        restTemplate.setInterceptors(List.of((requisicao, corpo, execucao) -> {
            requisicao.getHeaders().set(HttpHeaders.USER_AGENT, "CuidaMed-App/1.0");
            return execucao.execute(requisicao, corpo);
        }));
        return restTemplate;
    }
}
