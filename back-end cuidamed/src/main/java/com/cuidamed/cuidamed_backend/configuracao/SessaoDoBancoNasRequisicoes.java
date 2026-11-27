package com.cuidamed.cuidamed_backend.configuracao;

import org.springframework.context.annotation.Configuration;
import org.springframework.orm.jpa.support.OpenEntityManagerInViewInterceptor;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import jakarta.persistence.EntityManagerFactory;

@Configuration
public class SessaoDoBancoNasRequisicoes implements WebMvcConfigurer {

    private final EntityManagerFactory fabrica;

    public SessaoDoBancoNasRequisicoes(EntityManagerFactory fabrica) {
        this.fabrica = fabrica;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registro) {
        OpenEntityManagerInViewInterceptor sessao = new OpenEntityManagerInViewInterceptor();
        sessao.setEntityManagerFactory(fabrica);
        // No chat a resposta da IA demora e seguraria uma conexão do banco.
        registro.addWebRequestInterceptor(sessao).excludePathPatterns("/api/chat/**");
    }
}
