package com.cuidamed.cuidamed_backend.chat;

import java.time.Duration;

import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.cuidamed.cuidamed_backend.seguranca.Autorizacao;
import com.cuidamed.cuidamed_backend.seguranca.LimitadorDeTentativas;

@RestController
public class ChatController {

    private final ChatService chatService;
    private final Autorizacao autorizacao;
    private final LimitadorDeTentativas limitador;

    // Cada pergunta é uma chamada paga à Anthropic: até 30 por hora e 100 por dia por paciente.
    static final int PERGUNTAS_POR_HORA = 30;
    static final int PERGUNTAS_POR_DIA = 100;
    private static final String LIMITE_HORA = "Você fez muitas perguntas em pouco tempo. Tente de novo daqui a pouco.";
    private static final String LIMITE_DIA = "Você chegou ao limite de perguntas de hoje. Tente de novo amanhã.";

    public ChatController(ChatService chatService, Autorizacao autorizacao, LimitadorDeTentativas limitador) {
        this.chatService = chatService;
        this.autorizacao = autorizacao;
        this.limitador = limitador;
    }

    @PostMapping("/api/chat/{pacienteId}")
    public ChatRespostaDTO perguntar(@PathVariable Long pacienteId, @RequestBody ChatMensagemDTO dto) {
        // O assistente responde só ao próprio paciente (e usa a chave paga da Anthropic).
        autorizacao.exigirOProprioPaciente(pacienteId);
        limitador.exigirDisponivel("chat-dia:" + pacienteId, PERGUNTAS_POR_DIA, Duration.ofDays(1), LIMITE_DIA);
        limitador.consumir("chat-hora:" + pacienteId, PERGUNTAS_POR_HORA, Duration.ofHours(1), LIMITE_HORA);
        limitador.registrar("chat-dia:" + pacienteId);
        return chatService.perguntar(pacienteId, dto);
    }
}
