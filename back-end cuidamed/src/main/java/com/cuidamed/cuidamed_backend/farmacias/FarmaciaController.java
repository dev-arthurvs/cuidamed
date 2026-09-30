package com.cuidamed.cuidamed_backend.farmacias;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/farmacias")
public class FarmaciaController {

    private final FarmaciaService farmaciaService;

    public FarmaciaController(FarmaciaService farmaciaService) {
        this.farmaciaService = farmaciaService;
    }

    @GetMapping
    public RespostaFarmaciasDTO buscar(
            @RequestParam(required = false) String endereco,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lon,
            @RequestParam(defaultValue = "3000") int raio) {
        if (lat != null && lon != null) {
            return farmaciaService.buscarFarmaciasProximas(lat, lon, raio);
        }
        if (endereco != null && !endereco.isBlank()) {
            return farmaciaService.buscarFarmaciasProximas(endereco, raio);
        }
        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe um endereço ou uma coordenada (lat/lon).");
    }
}
