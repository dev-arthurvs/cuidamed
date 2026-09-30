package com.cuidamed.cuidamed_backend.medicamento;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.cuidamed.cuidamed_backend.seguranca.Autorizacao;

@RestController
public class MedicamentoController {

    private final MedicamentoService medicamentoService;
    private final Autorizacao autorizacao;

    public MedicamentoController(MedicamentoService medicamentoService, Autorizacao autorizacao) {
        this.medicamentoService = medicamentoService;
        this.autorizacao = autorizacao;
    }

    @PostMapping("/api/medicamentos")
    @ResponseStatus(HttpStatus.CREATED)
    public MedicamentoRespostaDTO criar(@RequestBody MedicamentoCriacaoDTO dto) {
        autorizacao.exigirPodeAlterarMedicamentos(dto.pacienteId());
        return medicamentoService.criar(dto);
    }

    @GetMapping("/api/pacientes/{pacienteId}/medicamentos")
    public List<MedicamentoRespostaDTO> listarPorPaciente(@PathVariable Long pacienteId) {
        autorizacao.exigirAcessoAoPaciente(pacienteId);
        return medicamentoService.listarPorPaciente(pacienteId);
    }

    @GetMapping("/api/medicamentos/{id}")
    public MedicamentoRespostaDTO buscarPorId(@PathVariable Long id) {
        autorizacao.exigirAcessoAoPaciente(autorizacao.pacienteDoMedicamento(id));
        return medicamentoService.buscarPorId(id);
    }

    @PutMapping("/api/medicamentos/{id}")
    public MedicamentoRespostaDTO atualizar(@PathVariable Long id, @RequestBody MedicamentoAtualizacaoDTO dto) {
        autorizacao.exigirPodeAlterarMedicamentos(autorizacao.pacienteDoMedicamento(id));
        return medicamentoService.atualizar(id, dto);
    }

    @DeleteMapping("/api/medicamentos/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluir(@PathVariable Long id) {
        autorizacao.exigirPodeAlterarMedicamentos(autorizacao.pacienteDoMedicamento(id));
        medicamentoService.excluir(id);
    }
}
