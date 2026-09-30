package com.cuidamed.cuidamed_backend.configuracao;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.PropertiesPropertySource;

/**
 * Lê o arquivo .env na raiz do projeto (se existir) e injeta suas chaves como
 * propriedades do Spring, do mesmo jeito que variáveis de ambiente reais
 * seriam lidas. Evita depender de uma lib externa de dotenv.
 */
public class CarregadorDotenv implements EnvironmentPostProcessor {

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        File arquivo = new File(".env");
        if (!arquivo.exists()) {
            return;
        }

        Properties propriedades = new Properties();
        try (InputStream entrada = new FileInputStream(arquivo)) {
            for (String linha : new String(entrada.readAllBytes()).split("\\R")) {
                String linhaLimpa = linha.trim();
                if (linhaLimpa.isEmpty() || linhaLimpa.startsWith("#") || !linhaLimpa.contains("=")) {
                    continue;
                }
                int posicaoIgual = linhaLimpa.indexOf('=');
                String chave = linhaLimpa.substring(0, posicaoIgual).trim();
                String valor = linhaLimpa.substring(posicaoIgual + 1).trim();
                propriedades.setProperty(chave, valor);
            }
        } catch (IOException erro) {
            throw new IllegalStateException("Não foi possível ler o arquivo .env", erro);
        }

        environment.getPropertySources().addLast(new PropertiesPropertySource("dotenv", propriedades));
    }
}
