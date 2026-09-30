package com.cuidamed.cuidamed_backend.seguranca;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

/**
 * Gera o token entregue no login. Ele vale por alguns dias (o app fica logado
 * no aparelho, pensando no público idoso) e carrega só o tipo e o id do
 * usuário — nada de dado pessoal, já que o conteúdo do JWT é legível.
 */
@Service
public class ServicoToken {

    public static final String EMISSOR = "cuidamed";
    public static final String CLAIM_TIPO = "tipo";
    public static final String CLAIM_ID = "uid";

    private final JwtEncoder codificador;
    private final long validadeDias;

    public ServicoToken(JwtEncoder codificador, @Value("${cuidamed.jwt.validade-dias}") long validadeDias) {
        this.codificador = codificador;
        this.validadeDias = validadeDias;
    }

    public String gerar(String tipo, Long id) {
        Instant agora = Instant.now();
        JwtClaimsSet dados = JwtClaimsSet.builder()
                .issuer(EMISSOR)
                .subject(tipo + ":" + id)
                .issuedAt(agora)
                .expiresAt(agora.plus(validadeDias, ChronoUnit.DAYS))
                .claim(CLAIM_TIPO, tipo)
                .claim(CLAIM_ID, id)
                .build();
        JwsHeader cabecalho = JwsHeader.with(MacAlgorithm.HS256).build();
        return codificador.encode(JwtEncoderParameters.from(cabecalho, dados)).getTokenValue();
    }
}
