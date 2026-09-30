package com.cuidamed.cuidamed_backend.farmacias;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
record NominatimResultado(String lat, String lon, @JsonProperty("display_name") String enderecoFormatado) {
}
