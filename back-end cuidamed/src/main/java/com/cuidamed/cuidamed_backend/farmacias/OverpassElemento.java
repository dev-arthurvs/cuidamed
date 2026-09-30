package com.cuidamed.cuidamed_backend.farmacias;

import java.util.Map;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
record OverpassElemento(Long id, Double lat, Double lon, Map<String, String> tags) {
}
