package com.cuidamed.cuidamed_backend.chat;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
record AnthropicResposta(List<AnthropicConteudo> content) {
}
