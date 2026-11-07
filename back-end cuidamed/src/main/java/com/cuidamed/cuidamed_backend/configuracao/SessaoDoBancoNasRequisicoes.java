package com.cuidamed.cuidamed_backend.configuracao;

import org.springframework.context.annotation.Configuration;
import org.springframework.orm.jpa.support.OpenEntityManagerInViewInterceptor;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import jakarta.persistence.EntityManagerFactory;

/**
 * Mantém a sessão do banco aberta durante a requisição, como o padrão do Spring,
 * menos no chat: lá a resposta da IA leva segundos e seguraria uma conexão do banco
 * sem usar, deixando as outras telas lentas com vários chats ao mesmo tempo.
 */
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
        registro.addWebRequestInterceptor(sessao).excludePathPatterns("/api/chat/**");
    }
}
