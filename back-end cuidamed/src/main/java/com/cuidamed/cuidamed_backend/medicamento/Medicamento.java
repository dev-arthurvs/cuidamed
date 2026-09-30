package com.cuidamed.cuidamed_backend.medicamento;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.hibernate.annotations.CreationTimestamp;

import com.cuidamed.cuidamed_backend.paciente.Paciente;

import jakarta.persistence.CascadeType;
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
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

@Entity
@Table(name = "medicamento")
public class Medicamento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_med")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "paciente_id_med", nullable = false)
    private Paciente paciente;

    @Column(name = "nome_med", nullable = false, length = 150)
    private String nome;

    @Column(name = "dosagem_med", nullable = false, length = 50)
    private String dosagem;

    @Enumerated(EnumType.STRING)
    @Column(name = "forma_med", nullable = false, length = 20)
    private FormaMedicamento forma;

    @Enumerated(EnumType.STRING)
    @Column(name = "frequencia_med", nullable = false, length = 30)
    private FrequenciaMedicamento frequencia;

    @Column(name = "datainicio_med", nullable = false)
    private LocalDate dataInicio;

    @Column(name = "datafim_med")
    private LocalDate dataFim;

    @Column(name = "observacoes_med", columnDefinition = "TEXT")
    private String observacoes;

    @Column(name = "quantidadeestoque_med")
    private Integer quantidadeEstoque;

    @Column(name = "quantidadepordose_med")
    private Integer quantidadePorDose;

    @OneToMany(mappedBy = "medicamento", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Horario> horarios = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "criadoem_med", nullable = false, updatable = false)
    private LocalDateTime criadoEm;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Paciente getPaciente() {
        return paciente;
    }

    public void setPaciente(Paciente paciente) {
        this.paciente = paciente;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getDosagem() {
        return dosagem;
    }

    public void setDosagem(String dosagem) {
        this.dosagem = dosagem;
    }

    public FormaMedicamento getForma() {
        return forma;
    }

    public void setForma(FormaMedicamento forma) {
        this.forma = forma;
    }

    public FrequenciaMedicamento getFrequencia() {
        return frequencia;
    }

    public void setFrequencia(FrequenciaMedicamento frequencia) {
        this.frequencia = frequencia;
    }

    public LocalDate getDataInicio() {
        return dataInicio;
    }

    public void setDataInicio(LocalDate dataInicio) {
        this.dataInicio = dataInicio;
    }

    public LocalDate getDataFim() {
        return dataFim;
    }

    public void setDataFim(LocalDate dataFim) {
        this.dataFim = dataFim;
    }

    public String getObservacoes() {
        return observacoes;
    }

    public void setObservacoes(String observacoes) {
        this.observacoes = observacoes;
    }

    public Integer getQuantidadeEstoque() {
        return quantidadeEstoque;
    }

    public void setQuantidadeEstoque(Integer quantidadeEstoque) {
        this.quantidadeEstoque = quantidadeEstoque;
    }

    public Integer getQuantidadePorDose() {
        return quantidadePorDose;
    }

    public void setQuantidadePorDose(Integer quantidadePorDose) {
        this.quantidadePorDose = quantidadePorDose;
    }

    public List<Horario> getHorarios() {
        return horarios;
    }

    public LocalDateTime getCriadoEm() {
        return criadoEm;
    }

    /**
     * Tem dose nesse dia? Considera início, fim e a frequência: "Dias alternados" = a
     * cada 2 dias e "Semanal" = a cada 7, contando da data de início; as demais, todo dia.
     * Mesma regra do web (utilitarios/horarios.js) e do mobile (utilitarios/horarios.dart).
     */
    public boolean temDoseEm(LocalDate dia) {
        if (dataInicio != null && dia.isBefore(dataInicio)) {
            return false;
        }
        if (dataFim != null && dia.isAfter(dataFim)) {
            return false;
        }
        int intervalo = frequencia == FrequenciaMedicamento.DIAS_ALTERNADOS ? 2
                : frequencia == FrequenciaMedicamento.SEMANAL ? 7 : 1;
        if (intervalo == 1 || dataInicio == null) {
            return true;
        }
        return java.time.temporal.ChronoUnit.DAYS.between(dataInicio, dia) % intervalo == 0;
    }

}
