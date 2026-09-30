package com.cuidamed.cuidamed_backend.chat;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
record AnthropicConteudo(String type, String text) {
}
