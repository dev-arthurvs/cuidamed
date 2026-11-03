package com.cuidamed.cuidamed_backend.vinculo;

/** Situação de um vínculo paciente–cuidador (ver V3__vinculo_paciente_cuidador.sql). */
public enum SituacaoVinculo {
    /** Pedido do paciente aguardando o cuidador. */
    PENDENTE,
    /** Vínculo em vigor; o id dele é o "nº do cartão" do paciente. */
    ATIVO,
    /** Pedido recusado pelo cuidador. */
    RECUSADO,
    /** Pedido substituído por outro antes da resposta. */
    CANCELADO,
    /** Vínculo desfeito pelo cuidador. */
    ENCERRADO
}
