package com.cuidamed.cuidamed_backend.seguranca;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import com.nimbusds.jose.jwk.source.ImmutableSecret;

import jakarta.servlet.http.HttpServletResponse;

/**
 * Segurança da API: toda rota exige o token do login (Authorization: Bearer
 * ...), exceto as que existem justamente para quem ainda não tem conta ou não
 * entrou (login, cadastro e ativação de acesso). O que cada usuário pode ver
 * ou alterar é conferido nos controllers, pela {@link Autorizacao}.
 */
@Configuration
public class ConfiguracaoSeguranca {

    private static final Logger LOG = LoggerFactory.getLogger(ConfiguracaoSeguranca.class);
    private static final int TAMANHO_MINIMO_SEGREDO = 32;

    @Bean
    public SecurityFilterChain cadeiaDeSeguranca(HttpSecurity http) throws Exception {
        AuthenticationEntryPoint semLogin = (requisicao, resposta, erro) -> escreverErro(
                resposta, HttpStatus.UNAUTHORIZED, "Sua sessão expirou. Entre novamente.");
        AccessDeniedHandler semPermissao = (requisicao, resposta, erro) -> escreverErro(
                resposta, HttpStatus.FORBIDDEN, "Você não tem permissão para essa ação.");

        http
                // Sem cookies de sessão: o token vai no cabeçalho, então não há CSRF a proteger.
                .csrf(csrf -> csrf.disable())
                .cors(Customizer.withDefaults())
                .sessionManagement(sessao -> sessao.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(rotas -> rotas
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        .requestMatchers(HttpMethod.POST,
                                "/api/auth/login",
                                "/api/cuidadores",              // cadastro de cuidador
                                "/api/pacientes",               // cadastro de paciente (ou cuidador cadastrando, com token)
                                "/api/pacientes/definir-senha") // "Ativar meu acesso"
                        .permitAll()
                        .requestMatchers("/error").permitAll()
                        .requestMatchers(HttpMethod.GET, "/actuator/health").permitAll()
                        .anyRequest().authenticated())
                .oauth2ResourceServer(servidor -> servidor
                        .jwt(Customizer.withDefaults())
                        .authenticationEntryPoint(semLogin)
                        .accessDeniedHandler(semPermissao))
                .exceptionHandling(erros -> erros
                        .authenticationEntryPoint(semLogin)
                        .accessDeniedHandler(semPermissao));
        return http.build();
    }

    /**
     * Chave que assina os tokens. Sem JWT_SECRET, gera uma temporária: funciona,
     * mas a cada reinício do servidor todos precisam entrar de novo.
     */
    @Bean
    public SecretKey chaveDosTokens(@Value("${cuidamed.jwt.segredo}") String segredo) {
        byte[] bytes;
        if (segredo == null || segredo.isBlank()) {
            LOG.warn("JWT_SECRET não definido: usando um segredo temporário. Os logins deixam de valer a cada reinício.");
            bytes = new byte[TAMANHO_MINIMO_SEGREDO];
            new SecureRandom().nextBytes(bytes);
        } else {
            bytes = segredo.getBytes(StandardCharsets.UTF_8);
            if (bytes.length < TAMANHO_MINIMO_SEGREDO) {
                throw new IllegalStateException("JWT_SECRET precisa ter pelo menos " + TAMANHO_MINIMO_SEGREDO + " caracteres.");
            }
        }
        return new SecretKeySpec(bytes, "HmacSHA256");
    }

    @Bean
    public JwtEncoder codificadorJwt(SecretKey chave) {
        return new NimbusJwtEncoder(new ImmutableSecret<>(chave));
    }

    @Bean
    public JwtDecoder decodificadorJwt(SecretKey chave) {
        NimbusJwtDecoder decodificador = NimbusJwtDecoder.withSecretKey(chave).macAlgorithm(MacAlgorithm.HS256).build();
        // Além da assinatura e da validade, só aceita tokens emitidos por este servidor.
        decodificador.setJwtValidator(JwtValidators.createDefaultWithIssuer(ServicoToken.EMISSOR));
        return decodificador;
    }

    /**
     * Quais sites podem chamar a API pelo navegador (CORS_ORIGENS, separados por
     * vírgula). O nome do método importa: o Spring Security procura o bean
     * "corsConfigurationSource" — com outro nome, nenhuma regra era aplicada.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource(@Value("${cuidamed.cors.origens}") String origens) {
        CorsConfiguration configuracao = new CorsConfiguration();
        configuracao.setAllowedOrigins(Arrays.stream(origens.split(","))
                .map(String::trim)
                .filter(origem -> !origem.isEmpty())
                .toList());
        configuracao.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuracao.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        configuracao.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource fonte = new UrlBasedCorsConfigurationSource();
        fonte.registerCorsConfiguration("/api/**", configuracao);
        return fonte;
    }

    /** Mesmo formato de erro do TratadorDeErros, para o app mostrar a mensagem. */
    private static void escreverErro(HttpServletResponse resposta, HttpStatus status, String mensagem) throws IOException {
        resposta.setStatus(status.value());
        resposta.setContentType("application/json");
        resposta.setCharacterEncoding(StandardCharsets.UTF_8.name());
        resposta.getWriter().write("{\"timestamp\":\"" + Instant.now() + "\",\"status\":" + status.value()
                + ",\"error\":\"" + status.getReasonPhrase() + "\",\"message\":\"" + mensagem + "\"}");
    }
}
