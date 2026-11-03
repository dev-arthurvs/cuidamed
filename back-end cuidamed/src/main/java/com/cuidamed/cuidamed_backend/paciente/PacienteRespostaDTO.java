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
        // Id do vínculo ativo: o "nº do cartão" (null sem cuidador vinculado).
        Long codigoVinculo,
        boolean alertaManualPendente,
        String alertaManualMensagem,
        boolean permiteAlteracoes,
        // Enquanto o paciente não ativou o acesso, ou depois que o cuidador gerou um
        // código de nova senha (o cuidador repassa a ele).
        String codigoAtivacao,
        // true quando o código é de nova senha (a conta já tem senha).
        boolean codigoNovaSenha,
        LocalDateTime criadoEm) {

    /** `vinculoAtivo` e `pedidoPendente` podem ser null. */
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
