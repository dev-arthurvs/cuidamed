package com.cuidamed.cuidamed_backend.seguranca;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.historico.HistoricoRepository;
import com.cuidamed.cuidamed_backend.medicamento.MedicamentoRepository;
import com.cuidamed.cuidamed_backend.paciente.Paciente;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;
import com.cuidamed.cuidamed_backend.vinculo.SituacaoVinculo;
import com.cuidamed.cuidamed_backend.vinculo.VinculoRepository;

@Component
public class Autorizacao {

    private static final String SEM_ACESSO = "Você não tem acesso a esses dados.";

    private final PacienteRepository pacienteRepository;
    private final MedicamentoRepository medicamentoRepository;
    private final HistoricoRepository historicoRepository;
    private final VinculoRepository vinculoRepository;

    public Autorizacao(
            PacienteRepository pacienteRepository,
            MedicamentoRepository medicamentoRepository,
            HistoricoRepository historicoRepository,
            VinculoRepository vinculoRepository) {
        this.pacienteRepository = pacienteRepository;
        this.medicamentoRepository = medicamentoRepository;
        this.historicoRepository = historicoRepository;
        this.vinculoRepository = vinculoRepository;
    }

    public UsuarioAutenticado usuarioAtual() {
        Authentication autenticacao = SecurityContextHolder.getContext().getAuthentication();
        if (autenticacao == null || !(autenticacao.getPrincipal() instanceof Jwt token)) {
            return null;
        }
        Object id = token.getClaim(ServicoToken.CLAIM_ID);
        String tipo = token.getClaimAsString(ServicoToken.CLAIM_TIPO);
        if (!(id instanceof Number numero) || tipo == null) {
            return null;
        }
        return new UsuarioAutenticado(tipo, numero.longValue());
    }

    public void exigirAcessoAoPaciente(Long pacienteId) {
        UsuarioAutenticado usuario = exigirLogin();
        exigirId(pacienteId, "Informe o paciente.");
        if (usuario.ehPaciente() && usuario.id().equals(pacienteId)) {
            return;
        }
        if (usuario.ehCuidador() && cuidadorDoPaciente(pacienteId, usuario.id())) {
            return;
        }
        throw semAcesso();
    }

    public void exigirOProprioPaciente(Long pacienteId) {
        UsuarioAutenticado usuario = exigirLogin();
        if (!usuario.ehPaciente() || !usuario.id().equals(pacienteId)) {
            throw semAcesso();
        }
    }

    public Long exigirCuidador() {
        UsuarioAutenticado usuario = exigirLogin();
        if (!usuario.ehCuidador()) {
            throw semAcesso();
        }
        return usuario.id();
    }

    public void exigirOProprioCuidador(Long cuidadorId) {
        UsuarioAutenticado usuario = exigirLogin();
        if (!usuario.ehCuidador() || !usuario.id().equals(cuidadorId)) {
            throw semAcesso();
        }
    }

    public void exigirAcessoAoCuidador(Long cuidadorId) {
        UsuarioAutenticado usuario = exigirLogin();
        if (usuario.ehCuidador() && usuario.id().equals(cuidadorId)) {
            return;
        }
        if (usuario.ehPaciente() && vinculoRepository.existsByPacienteIdAndCuidadorIdAndSituacaoIn(
                usuario.id(), cuidadorId, List.of(SituacaoVinculo.ATIVO, SituacaoVinculo.PENDENTE))) {
            return;
        }
        throw semAcesso();
    }

    public void exigirPodeAlterarMedicamentos(Long pacienteId) {
        UsuarioAutenticado usuario = exigirLogin();
        exigirId(pacienteId, "Informe o paciente.");
        if (usuario.ehCuidador() && cuidadorDoPaciente(pacienteId, usuario.id())) {
            return;
        }
        if (usuario.ehPaciente() && usuario.id().equals(pacienteId)) {
            Paciente paciente = pacienteRepository.findById(pacienteId).orElseThrow(this::semAcesso);
            if (!vinculoRepository.existsByPacienteIdAndSituacao(pacienteId, SituacaoVinculo.ATIVO)
                    || paciente.isPermiteAlteracoes()) {
                return;
            }
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Seu cuidador ainda não liberou alterações nessa agenda.");
        }
        throw semAcesso();
    }

    public Long pacienteDoMedicamento(Long medicamentoId) {
        exigirLogin();
        return medicamentoRepository.findById(medicamentoId)
                .map(medicamento -> medicamento.getPaciente().getId())
                .orElseThrow(this::semAcesso);
    }

    public Long pacienteDoHistorico(Long historicoId) {
        exigirLogin();
        return historicoRepository.findById(historicoId)
                .map(historico -> historico.getPaciente().getId())
                .orElseThrow(this::semAcesso);
    }

    private UsuarioAutenticado exigirLogin() {
        UsuarioAutenticado usuario = usuarioAtual();
        if (usuario == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Sua sessão expirou. Entre novamente.");
        }
        return usuario;
    }

    private boolean cuidadorDoPaciente(Long pacienteId, Long cuidadorId) {
        return vinculoRepository.existsByPacienteIdAndCuidadorIdAndSituacao(pacienteId, cuidadorId, SituacaoVinculo.ATIVO);
    }

    private static void exigirId(Long id, String mensagem) {
        if (id == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, mensagem);
        }
    }

    private ResponseStatusException semAcesso() {
        return new ResponseStatusException(HttpStatus.FORBIDDEN, SEM_ACESSO);
    }
}
