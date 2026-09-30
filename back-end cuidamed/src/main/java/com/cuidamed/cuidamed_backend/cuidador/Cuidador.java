package com.cuidamed.cuidamed_backend.cuidador;

import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "cuidador")
public class Cuidador {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cui")
    private Long id;

    @Column(name = "nome_cui", nullable = false, length = 150)
    private String nome;

    @Column(name = "email_cui", nullable = false, length = 150, unique = true)
    private String email;

    @Column(name = "senha_cui", nullable = false, length = 255)
    private String senha;

    @Column(name = "profissao_cui", length = 100)
    private String profissao;

    @Column(name = "telefone_cui", length = 20)
    private String telefone;

    @CreationTimestamp
    @Column(name = "criadoem_cui", nullable = false, updatable = false)
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

    public String getProfissao() {
        return profissao;
    }

    public void setProfissao(String profissao) {
        this.profissao = profissao;
    }

    public String getTelefone() {
        return telefone;
    }

    public void setTelefone(String telefone) {
        this.telefone = telefone;
    }

    public LocalDateTime getCriadoEm() {
        return criadoEm;
    }
}
