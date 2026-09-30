package com.cuidamed.cuidamed_backend.farmacias;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
record OverpassResposta(List<OverpassElemento> elements) {
}
