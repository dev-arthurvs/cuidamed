package com.cuidamed.cuidamed_backend.paciente;

import java.time.LocalDate;
import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "paciente")
public class Paciente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_pac")
    private Long id;

    // O cuidador (e o pedido de vínculo) fica na tabela pacientecuidador — ver vinculo/Vinculo.

    @Column(name = "nome_pac", nullable = false, length = 150)
    private String nome;

    @Column(name = "email_pac", length = 150, unique = true)
    private String email;

    @Column(name = "senha_pac", length = 255)
    private String senha;

    @Column(name = "datanascimento_pac")
    private LocalDate dataNascimento;

    @Enumerated(EnumType.STRING)
    @Column(name = "sexo_pac", length = 20)
    private Sexo sexo;

    @Column(name = "enfermidade_pac", length = 255)
    private String enfermidade;

    @Column(name = "telefone_pac", length = 20)
    private String telefone;

    @Column(name = "endereco_pac", length = 255)
    private String endereco;

    @Column(name = "observacoesclinicas_pac", columnDefinition = "TEXT")
    private String observacoesClinicas;

    @Column(name = "alertamanualpendente_pac", nullable = false)
    private boolean alertaManualPendente = false;

    @Column(name = "alertamanualmensagem_pac", length = 255)
    private String alertaManualMensagem;

    @Column(name = "permitealteracoes_pac", nullable = false)
    private boolean permiteAlteracoes = false;

    // Existe enquanto o paciente cadastrado pelo cuidador não ativou o acesso, ou
    // quando o cuidador gerou um código para ele criar uma senha nova.
    @Column(name = "codigoativacao_pac", length = 12)
    private String codigoAtivacao;

    // Só no código de nova senha (a conta já tem senha); nulo = não expira.
    @Column(name = "codigoexpiraem_pac")
    private LocalDateTime codigoExpiraEm;

    @CreationTimestamp
    @Column(name = "criadoem_pac", nullable = false, updatable = false)
    private LocalDateTime criadoEm;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getSenha() {
        return senha;
    }

    public void setSenha(String senha) {
        this.senha = senha;
    }

    public LocalDate getDataNascimento() {
        return dataNascimento;
    }

    public void setDataNascimento(LocalDate dataNascimento) {
        this.dataNascimento = dataNascimento;
    }

    public Sexo getSexo() {
        return sexo;
    }

    public void setSexo(Sexo sexo) {
        this.sexo = sexo;
    }

    public String getEnfermidade() {
        return enfermidade;
    }

    public void setEnfermidade(String enfermidade) {
        this.enfermidade = enfermidade;
    }

    public String getTelefone() {
        return telefone;
    }

    public void setTelefone(String telefone) {
        this.telefone = telefone;
    }

    public String getEndereco() {
        return endereco;
    }

    public void setEndereco(String endereco) {
        this.endereco = endereco;
    }

    public String getObservacoesClinicas() {
        return observacoesClinicas;
    }

    public void setObservacoesClinicas(String observacoesClinicas) {
        this.observacoesClinicas = observacoesClinicas;
    }

    public boolean isAlertaManualPendente() {
        return alertaManualPendente;
    }

    public void setAlertaManualPendente(boolean alertaManualPendente) {
        this.alertaManualPendente = alertaManualPendente;
    }

    public String getAlertaManualMensagem() {
        return alertaManualMensagem;
    }

    public void setAlertaManualMensagem(String alertaManualMensagem) {
        this.alertaManualMensagem = alertaManualMensagem;
    }

    public boolean isPermiteAlteracoes() {
        return permiteAlteracoes;
    }

    public void setPermiteAlteracoes(boolean permiteAlteracoes) {
        this.permiteAlteracoes = permiteAlteracoes;
    }

    public String getCodigoAtivacao() {
        return codigoAtivacao;
    }

    public void setCodigoAtivacao(String codigoAtivacao) {
        this.codigoAtivacao = codigoAtivacao;
    }

    public void setCodigoExpiraEm(LocalDateTime codigoExpiraEm) {
        this.codigoExpiraEm = codigoExpiraEm;
    }

    /** O código que ainda pode ser usado; null se não há ou se já venceu. */
    public String getCodigoValido() {
        boolean vencido = codigoExpiraEm != null && !codigoExpiraEm.isAfter(LocalDateTime.now());
        return vencido ? null : codigoAtivacao;
    }

    public LocalDateTime getCriadoEm() {
        return criadoEm;
    }
}
