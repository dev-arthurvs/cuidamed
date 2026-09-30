package com.cuidamed.cuidamed_backend.paciente;

import java.time.LocalDate;
import java.time.LocalDateTime;

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
        boolean alertaManualPendente,
        String alertaManualMensagem,
        boolean permiteAlteracoes,
        // Preenchido só enquanto o paciente não ativou o acesso (o cuidador repassa a ele).
        String codigoAtivacao,
        LocalDateTime criadoEm) {

    public static PacienteRespostaDTO paraDTO(Paciente paciente) {
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
                paciente.getCuidador() != null ? paciente.getCuidador().getId() : null,
                paciente.getCuidadorSolicitado() != null ? paciente.getCuidadorSolicitado().getId() : null,
                paciente.isAlertaManualPendente(),
                paciente.getAlertaManualMensagem(),
                paciente.isPermiteAlteracoes(),
                paciente.getCodigoAtivacao(),
                paciente.getCriadoEm());
    }
}
