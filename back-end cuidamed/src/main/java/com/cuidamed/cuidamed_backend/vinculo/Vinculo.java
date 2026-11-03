package com.cuidamed.cuidamed_backend.vinculo;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import com.cuidamed.cuidamed_backend.cuidador.Cuidador;
import com.cuidamed.cuidamed_backend.paciente.Paciente;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/**
 * Vínculo entre um paciente e um cuidador (tabela pacientecuidador), com o
 * histórico do pedido, do início e do fim. Um paciente tem no máximo um
 * vínculo ATIVO por vez.
 */
@Entity
@Table(name = "pacientecuidador")
public class Vinculo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_pcu")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "paciente_id_pcu", nullable = false)
    private Paciente paciente;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "cuidador_id_pcu", nullable = false)
    private Cuidador cuidador;

    @Enumerated(EnumType.STRING)
    @Column(name = "situacao_pcu", nullable = false, length = 20)
    private SituacaoVinculo situacao;

    @Column(name = "solicitadoem_pcu")
    private LocalDateTime solicitadoEm;

    @Column(name = "iniciadoem_pcu")
    private LocalDateTime iniciadoEm;

    @Column(name = "encerradoem_pcu")
    private LocalDateTime encerradoEm;

    @CreationTimestamp
    @Column(name = "criadoem_pcu", nullable = false, updatable = false)
    private LocalDateTime criadoEm;

    protected Vinculo() {
    }

    /** Pedido do paciente, aguardando o cuidador aceitar ou recusar. */
    public static Vinculo pedido(Paciente paciente, Cuidador cuidador) {
        Vinculo vinculo = new Vinculo();
        vinculo.paciente = paciente;
        vinculo.cuidador = cuidador;
        vinculo.situacao = SituacaoVinculo.PENDENTE;
        vinculo.solicitadoEm = LocalDateTime.now();
        return vinculo;
    }

    /** Vínculo já em vigor (ex.: cuidador cadastrou o paciente). */
    public static Vinculo ativo(Paciente paciente, Cuidador cuidador) {
        Vinculo vinculo = new Vinculo();
        vinculo.paciente = paciente;
        vinculo.cuidador = cuidador;
        vinculo.situacao = SituacaoVinculo.ATIVO;
        vinculo.iniciadoEm = LocalDateTime.now();
        return vinculo;
    }

    public void aceitar() {
        situacao = SituacaoVinculo.ATIVO;
        iniciadoEm = LocalDateTime.now();
    }

    /** Fecha o vínculo/pedido com a situação final (RECUSADO, CANCELADO ou ENCERRADO). */
    public void encerrar(SituacaoVinculo situacaoFinal) {
        situacao = situacaoFinal;
        encerradoEm = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Paciente getPaciente() {
        return paciente;
    }

    public Cuidador getCuidador() {
        return cuidador;
    }

    public SituacaoVinculo getSituacao() {
        return situacao;
    }

    public LocalDateTime getSolicitadoEm() {
        return solicitadoEm;
    }

    public LocalDateTime getIniciadoEm() {
        return iniciadoEm;
    }

    public LocalDateTime getEncerradoEm() {
        return encerradoEm;
    }

    public LocalDateTime getCriadoEm() {
        return criadoEm;
    }
}
