package com.cuidamed.cuidamed_backend.seguranca;

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

/**
 * Regras de "quem pode acessar o quê", usadas nos controllers antes de cada
 * operação. Em resumo:
 * <ul>
 * <li>o paciente acessa só os próprios dados;</li>
 * <li>o cuidador acessa só os pacientes vinculados a ele;</li>
 * <li>remédios: o cuidador altera sempre; o paciente, só se o cuidador liberou.</li>
 * </ul>
 * Qualquer tentativa fora disso recebe 403, sem revelar se o registro existe.
 */
@Component
public class Autorizacao {

    private static final String SEM_ACESSO = "Você não tem acesso a esses dados.";

    private final PacienteRepository pacienteRepository;
    private final MedicamentoRepository medicamentoRepository;
    private final HistoricoRepository historicoRepository;

    public Autorizacao(
            PacienteRepository pacienteRepository,
            MedicamentoRepository medicamentoRepository,
            HistoricoRepository historicoRepository) {
        this.pacienteRepository = pacienteRepository;
        this.medicamentoRepository = medicamentoRepository;
        this.historicoRepository = historicoRepository;
    }

    /** Usuário do token da requisição, ou null se ela veio sem login (rotas públicas). */
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

    /** O paciente em pessoa ou o cuidador vinculado a ele. */
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

    /** Só o próprio paciente (ex.: trocar a senha dele, usar o chat). */
    public void exigirOProprioPaciente(Long pacienteId) {
        UsuarioAutenticado usuario = exigirLogin();
        if (!usuario.ehPaciente() || !usuario.id().equals(pacienteId)) {
            throw semAcesso();
        }
    }

    /**
     * Exige um cuidador logado e devolve o id dele. Os controllers usam esse id
     * no lugar do "cuidadorId" que o app manda no corpo — assim ninguém age em
     * nome de outro cuidador.
     */
    public Long exigirCuidador() {
        UsuarioAutenticado usuario = exigirLogin();
        if (!usuario.ehCuidador()) {
            throw semAcesso();
        }
        return usuario.id();
    }

    /** Só o próprio cuidador (dados e senha da conta dele). */
    public void exigirOProprioCuidador(Long cuidadorId) {
        UsuarioAutenticado usuario = exigirLogin();
        if (!usuario.ehCuidador() || !usuario.id().equals(cuidadorId)) {
            throw semAcesso();
        }
    }

    /**
     * Ver os dados de um cuidador: ele mesmo, ou um paciente vinculado a ele (ou
     * com pedido de vínculo pendente) — o perfil do paciente mostra o cuidador.
     */
    public void exigirAcessoAoCuidador(Long cuidadorId) {
        UsuarioAutenticado usuario = exigirLogin();
        if (usuario.ehCuidador() && usuario.id().equals(cuidadorId)) {
            return;
        }
        if (usuario.ehPaciente()) {
            Paciente paciente = pacienteRepository.findById(usuario.id()).orElseThrow(this::semAcesso);
            if (mesmoCuidador(paciente, cuidadorId)) {
                return;
            }
        }
        throw semAcesso();
    }

    /** Criar, editar ou excluir remédios: cuidador vinculado, ou o paciente se o cuidador liberou. */
    public void exigirPodeAlterarMedicamentos(Long pacienteId) {
        UsuarioAutenticado usuario = exigirLogin();
        exigirId(pacienteId, "Informe o paciente.");
        if (usuario.ehCuidador() && cuidadorDoPaciente(pacienteId, usuario.id())) {
            return;
        }
        if (usuario.ehPaciente() && usuario.id().equals(pacienteId)) {
            Paciente paciente = pacienteRepository.findById(pacienteId).orElseThrow(this::semAcesso);
            if (paciente.getCuidador() == null || paciente.isPermiteAlteracoes()) {
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
        return pacienteRepository.findById(pacienteId)
                .map(paciente -> paciente.getCuidador() != null && paciente.getCuidador().getId().equals(cuidadorId))
                .orElse(false);
    }

    private static boolean mesmoCuidador(Paciente paciente, Long cuidadorId) {
        return (paciente.getCuidador() != null && paciente.getCuidador().getId().equals(cuidadorId))
                || (paciente.getCuidadorSolicitado() != null && paciente.getCuidadorSolicitado().getId().equals(cuidadorId));
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
