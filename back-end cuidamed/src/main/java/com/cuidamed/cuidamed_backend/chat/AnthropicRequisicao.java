package com.cuidamed.cuidamed_backend.chat;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;

record AnthropicRequisicao(
        String model,
        @JsonProperty("max_tokens") int maxTokens,
        String system,
        List<AnthropicMensagem> messages) {
}
