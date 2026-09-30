package com.cuidamed.cuidamed_backend.farmacias;

import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@Service
public class FarmaciaService {

    private static final Logger LOG = LoggerFactory.getLogger(FarmaciaService.class);
    private static final String URL_NOMINATIM = "https://nominatim.openstreetmap.org/search?q={endereco}&format=json&limit=1";
    // Vários espelhos públicos do Overpass, não só um — e QUAL deles está de pé
    // muda de um teste pro outro (em uma rodada o overpass-api.de estava 100% fora,
    // minutos depois era o único de pé e os outros dois é que caíram). Uma ordem
    // fixa de prioridade não funciona porque castiga o caso em que o mirror "de
    // reserva" é justamente o único disponível. Por isso todos são chamados em
    // paralelo (ver buscarFarmaciasNoOverpass) e fica valendo o primeiro que responder.
    private static final List<String> URLS_OVERPASS = List.of(
            "https://overpass.kumi.systems/api/interpreter",
            "https://overpass.private.coffee/api/interpreter",
            "https://overpass-api.de/api/interpreter");
    private static final double RAIO_TERRA_METROS = 6_371_000;

    private final RestTemplate restTemplate;
    private final RestTemplate restTemplateOverpass;

    public FarmaciaService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
        // Timeout dedicado pro Overpass: conecta rápido (se o host estiver fora do
        // ar, desiste logo e tenta o próximo) mas dá bastante margem de leitura,
        // já que consultas em área densa (ex.: São Paulo) podem legitimamente
        // demorar mais que o timeout padrão compartilhado com as outras chamadas.
        SimpleClientHttpRequestFactory fabricaOverpass = new SimpleClientHttpRequestFactory();
        fabricaOverpass.setConnectTimeout(5_000);
        fabricaOverpass.setReadTimeout(20_000);
        this.restTemplateOverpass = new RestTemplate(fabricaOverpass);
    }

    public RespostaFarmaciasDTO buscarFarmaciasProximas(String endereco, int raioMetros) {
        PontoOrigemDTO origem = geocodificarEndereco(endereco);
        List<FarmaciaDTO> farmacias = buscarFarmaciasNoOverpass(origem, raioMetros);
        return new RespostaFarmaciasDTO(origem, farmacias);
    }

    public RespostaFarmaciasDTO buscarFarmaciasProximas(double latitude, double longitude, int raioMetros) {
        PontoOrigemDTO origem = new PontoOrigemDTO(latitude, longitude, null);
        List<FarmaciaDTO> farmacias = buscarFarmaciasNoOverpass(origem, raioMetros);
        return new RespostaFarmaciasDTO(origem, farmacias);
    }

    private PontoOrigemDTO geocodificarEndereco(String endereco) {
        ResponseEntity<NominatimResultado[]> resposta;
        try {
            resposta = restTemplate.exchange(
                    URL_NOMINATIM, HttpMethod.GET, HttpEntity.EMPTY, NominatimResultado[].class, endereco);
        } catch (RestClientException erro) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Não foi possível consultar o serviço de geocodificação.", erro);
        }

        NominatimResultado[] resultados = resposta.getBody();
        if (resultados == null || resultados.length == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Endereço não encontrado: " + endereco);
        }

        NominatimResultado primeiro = resultados[0];
        return new PontoOrigemDTO(Double.parseDouble(primeiro.lat()), Double.parseDouble(primeiro.lon()), primeiro.enderecoFormatado());
    }

    private static final long TIMEOUT_TOTAL_SEGUNDOS = 22;

    private List<FarmaciaDTO> buscarFarmaciasNoOverpass(PontoOrigemDTO origem, int raioMetros) {
        String query = String.format(Locale.US,
                "[out:json][timeout:25];node[\"amenity\"=\"pharmacy\"](around:%d,%f,%f);out body;",
                raioMetros, origem.latitude(), origem.longitude());

        HttpHeaders cabecalhos = new HttpHeaders();
        cabecalhos.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        MultiValueMap<String, String> corpo = new LinkedMultiValueMap<>();
        corpo.add("data", query);
        HttpEntity<MultiValueMap<String, String>> requisicao = new HttpEntity<>(corpo, cabecalhos);

        OverpassResposta resposta = chamarPrimeiroMirrorQueResponder(requisicao, raioMetros);

        if (resposta == null || resposta.elements() == null) {
            return List.of();
        }

        return resposta.elements().stream()
                .filter(elemento -> elemento.lat() != null && elemento.lon() != null)
                .map(elemento -> paraFarmaciaDTO(elemento, origem))
                .sorted(Comparator.comparingDouble(FarmaciaDTO::distanciaMetros))
                .toList();
    }

    // Chama todos os espelhos ao mesmo tempo e usa o primeiro que responder com
    // sucesso — só desiste se todos falharem. Isso evita punir o usuário quando o
    // mirror "prioritário" está fora do ar e o de reserva é o único funcionando.
    private OverpassResposta chamarPrimeiroMirrorQueResponder(
            HttpEntity<MultiValueMap<String, String>> requisicao, int raioMetros) {
        ExecutorService executor = Executors.newFixedThreadPool(URLS_OVERPASS.size());
        CompletableFuture<OverpassResposta> resultado = new CompletableFuture<>();
        AtomicInteger falhasRestantes = new AtomicInteger(URLS_OVERPASS.size());

        try {
            for (String urlOverpass : URLS_OVERPASS) {
                CompletableFuture
                        .supplyAsync(
                                () -> restTemplateOverpass.postForObject(urlOverpass, requisicao, OverpassResposta.class), executor)
                        .whenComplete((resposta, erro) -> {
                            if (erro != null) {
                                LOG.warn("Overpass em {} falhou (raio={}m): {}", urlOverpass, raioMetros, erro.toString());
                                if (falhasRestantes.decrementAndGet() == 0) {
                                    resultado.completeExceptionally(erro);
                                }
                            } else {
                                resultado.complete(resposta);
                            }
                        });
            }

            return resultado.get(TIMEOUT_TOTAL_SEGUNDOS, TimeUnit.SECONDS);
        } catch (TimeoutException | InterruptedException | ExecutionException erro) {
            if (erro instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "O serviço de mapas está instável no momento. Tente novamente em instantes.",
                    erro);
        } finally {
            executor.shutdown();
        }
    }

    private FarmaciaDTO paraFarmaciaDTO(OverpassElemento elemento, PontoOrigemDTO origem) {
        Map<String, String> tags = elemento.tags();
        String nome = tags != null && tags.get("name") != null ? tags.get("name") : "Farmácia sem nome cadastrado";
        String endereco = montarEndereco(tags);
        double distancia = calcularDistanciaMetros(origem.latitude(), origem.longitude(), elemento.lat(), elemento.lon());
        return new FarmaciaDTO(nome, endereco, elemento.lat(), elemento.lon(), Math.round(distancia * 10) / 10.0);
    }

    private static String montarEndereco(Map<String, String> tags) {
        if (tags == null) {
            return "Endereço não informado";
        }
        String rua = tags.getOrDefault("addr:street", "");
        String numero = tags.getOrDefault("addr:housenumber", "");
        String bairro = tags.getOrDefault("addr:suburb", "");
        String cidade = tags.getOrDefault("addr:city", "");

        String enderecoMontado = Stream.of((rua + " " + numero).trim(), bairro, cidade)
                .filter(parte -> !parte.isBlank())
                .collect(Collectors.joining(", "));

        return enderecoMontado.isBlank() ? "Endereço não informado" : enderecoMontado;
    }

    private static double calcularDistanciaMetros(double lat1, double lon1, double lat2, double lon2) {
        double deltaLat = Math.toRadians(lat2 - lat1);
        double deltaLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return RAIO_TERRA_METROS * c;
    }
}
