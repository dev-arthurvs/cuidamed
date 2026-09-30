package com.cuidamed.cuidamed_backend.cuidador;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.cuidamed.cuidamed_backend.seguranca.Autorizacao;

@RestController
public class CuidadorController {

    private final CuidadorService cuidadorService;
    private final Autorizacao autorizacao;

    public CuidadorController(CuidadorService cuidadorService, Autorizacao autorizacao) {
        this.cuidadorService = cuidadorService;
        this.autorizacao = autorizacao;
    }

    @PostMapping("/api/cuidadores")
    @ResponseStatus(HttpStatus.CREATED)
    public CuidadorRespostaDTO criar(@RequestBody CuidadorCriacaoDTO dto) {
        return cuidadorService.criar(dto);
    }

    @GetMapping("/api/cuidadores/{id}")
    public CuidadorRespostaDTO buscarPorId(@PathVariable Long id) {
        autorizacao.exigirAcessoAoCuidador(id);
        return cuidadorService.buscarPorId(id);
    }

    @PutMapping("/api/cuidadores/{id}")
    public CuidadorRespostaDTO atualizar(@PathVariable Long id, @RequestBody CuidadorAtualizacaoDTO dto) {
        autorizacao.exigirOProprioCuidador(id);
        return cuidadorService.atualizar(id, dto);
    }

    @PutMapping("/api/cuidadores/{id}/senha")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void alterarSenha(@PathVariable Long id, @RequestBody AlterarSenhaDTO dto) {
        autorizacao.exigirOProprioCuidador(id);
        cuidadorService.alterarSenha(id, dto);
    }
}
