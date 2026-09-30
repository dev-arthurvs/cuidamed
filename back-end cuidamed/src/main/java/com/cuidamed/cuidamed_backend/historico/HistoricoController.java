package com.cuidamed.cuidamed_backend.historico;

import java.time.LocalDate;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.cuidamed.cuidamed_backend.seguranca.Autorizacao;

@RestController
public class HistoricoController {

    private final HistoricoService historicoService;
    private final Autorizacao autorizacao;

    public HistoricoController(HistoricoService historicoService, Autorizacao autorizacao) {
        this.historicoService = historicoService;
        this.autorizacao = autorizacao;
    }

    @PostMapping("/api/historicos")
    @ResponseStatus(HttpStatus.CREATED)
    public HistoricoRespostaDTO criar(@RequestBody HistoricoCriacaoDTO dto) {
        autorizacao.exigirAcessoAoPaciente(dto.pacienteId());
        return historicoService.criar(dto);
    }

    @GetMapping("/api/pacientes/{pacienteId}/historicos")
    public List<HistoricoRespostaDTO> listarPorPaciente(
            @PathVariable Long pacienteId,
            @RequestParam(required = false) LocalDate data,
            @RequestParam(required = false) Long medicamentoId) {
        autorizacao.exigirAcessoAoPaciente(pacienteId);
        return historicoService.listarPorPaciente(pacienteId, data, medicamentoId);
    }

    @GetMapping("/api/historicos/{id}")
    public HistoricoRespostaDTO buscarPorId(@PathVariable Long id) {
        autorizacao.exigirAcessoAoPaciente(autorizacao.pacienteDoHistorico(id));
        return historicoService.buscarPorId(id);
    }
}
