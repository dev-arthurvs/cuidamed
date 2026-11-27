package com.cuidamed.cuidamed_backend.paciente;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.cuidamed.cuidamed_backend.vinculo.Vinculo;

public record PacienteRespostaDTO(
        Long id,
        String nome,
        String email,
        LocalDate dataNascimento,
        Sexo sexo,
        String enfermidade,
        String telefone,
        String endereco,
        String observacoesClinicas,
        Long cuidadorId,
        Long cuidadorSolicitadoId,
        Long codigoVinculo,
        boolean alertaManualPendente,
        String alertaManualMensagem,
        boolean permiteAlteracoes,
        String codigoAtivacao,
        boolean codigoNovaSenha,
        LocalDateTime criadoEm) {

    public static PacienteRespostaDTO paraDTO(Paciente paciente, Vinculo vinculoAtivo, Vinculo pedidoPendente) {
        return new PacienteRespostaDTO(
                paciente.getId(),
                paciente.getNome(),
                paciente.getEmail(),
                paciente.getDataNascimento(),
                paciente.getSexo(),
                paciente.getEnfermidade(),
                paciente.getTelefone(),
                paciente.getEndereco(),
                paciente.getObservacoesClinicas(),
                vinculoAtivo != null ? vinculoAtivo.getCuidador().getId() : null,
                pedidoPendente != null ? pedidoPendente.getCuidador().getId() : null,
                vinculoAtivo != null ? vinculoAtivo.getId() : null,
                paciente.isAlertaManualPendente(),
                paciente.getAlertaManualMensagem(),
                paciente.isPermiteAlteracoes(),
                paciente.getCodigoValido(),
                paciente.getCodigoValido() != null && paciente.getSenha() != null,
                paciente.getCriadoEm());
    }
}
