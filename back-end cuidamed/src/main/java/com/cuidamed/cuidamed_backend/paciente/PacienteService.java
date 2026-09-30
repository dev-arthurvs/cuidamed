package com.cuidamed.cuidamed_backend.paciente;

import java.security.SecureRandom;
import java.util.List;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.cuidador.Cuidador;
import com.cuidamed.cuidamed_backend.cuidador.CuidadorRepository;

@Service
public class PacienteService {

    private final PacienteRepository pacienteRepository;
    private final CuidadorRepository cuidadorRepository;
    private final PasswordEncoder passwordEncoder;

    // Sem letras e números que se confundem (0/O, 1/I/L) — o código é lido e digitado por idosos.
    private static final String ALFABETO_CODIGO = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private static final int TAMANHO_CODIGO = 6;
    private static final SecureRandom ALEATORIO = new SecureRandom();
    private static final String ATIVACAO_INVALIDA = "E-mail ou código de ativação inválidos.";

    public PacienteService(
            PacienteRepository pacienteRepository, CuidadorRepository cuidadorRepository, PasswordEncoder passwordEncoder) {
        this.pacienteRepository = pacienteRepository;
        this.cuidadorRepository = cuidadorRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public PacienteRespostaDTO criar(PacienteCriacaoDTO dto) {
        if (dto.nome() == null || dto.nome().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o nome do paciente.");
        }

        Paciente paciente = new Paciente();
        paciente.setNome(dto.nome());
        paciente.setEmail(dto.email());
        boolean temSenha = dto.senha() != null && !dto.senha().isBlank();
        paciente.setSenha(temSenha ? passwordEncoder.encode(dto.senha()) : null);
        // Cadastrado pelo cuidador, sem senha: precisa do código para ativar o acesso.
        paciente.setCodigoAtivacao(temSenha ? null : gerarCodigoAtivacao());
        paciente.setDataNascimento(dto.dataNascimento());
        paciente.setSexo(dto.sexo());
        paciente.setEnfermidade(dto.enfermidade());
        paciente.setTelefone(dto.telefone());
        paciente.setEndereco(dto.endereco());
        paciente.setObservacoesClinicas(dto.observacoesClinicas());
        paciente.setCuidador(buscarCuidadorOuNulo(dto.cuidadorId()));

        return PacienteRespostaDTO.paraDTO(salvar(paciente));
    }

    public PacienteRespostaDTO buscarPorId(Long id) {
        return PacienteRespostaDTO.paraDTO(buscarEntidadePorId(id));
    }

    public List<PacienteRespostaDTO> listarPorCuidador(Long cuidadorId) {
        return pacienteRepository.findByCuidadorId(cuidadorId).stream().map(PacienteRespostaDTO::paraDTO).toList();
    }

    public PacienteRespostaDTO atualizar(Long id, PacienteAtualizacaoDTO dto) {
        Paciente paciente = buscarEntidadePorId(id);

        if (dto.nome() == null || dto.nome().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o nome do paciente.");
        }

        paciente.setNome(dto.nome());
        paciente.setEmail(dto.email());
        paciente.setDataNascimento(dto.dataNascimento());
        paciente.setSexo(dto.sexo());
        paciente.setEnfermidade(dto.enfermidade());
        paciente.setTelefone(dto.telefone());
        paciente.setEndereco(dto.endereco());
        paciente.setObservacoesClinicas(dto.observacoesClinicas());
        // O vínculo com o cuidador não muda aqui (dto.cuidadorId é ignorado): só
        // pelos fluxos de solicitar/aceitar/desvincular. Antes, editar o perfil
        // permitia ao paciente se ligar a qualquer cuidador sem aprovação.

        return PacienteRespostaDTO.paraDTO(salvar(paciente));
    }

    public void alterarSenha(Long id, AlterarSenhaDTO dto) {
        Paciente paciente = buscarEntidadePorId(id);

        if (paciente.getSenha() == null || !passwordEncoder.matches(dto.senhaAtual(), paciente.getSenha())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Senha atual incorreta.");
        }
        if (dto.novaSenha() == null || dto.novaSenha().length() < 8) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A nova senha deve ter no mínimo 8 caracteres.");
        }

        paciente.setSenha(passwordEncoder.encode(dto.novaSenha()));
        pacienteRepository.save(paciente);
    }

    public void definirSenha(DefinirSenhaDTO dto) {
        if (dto.email() == null || dto.email().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o e-mail do paciente.");
        }
        if (dto.novaSenha() == null || dto.novaSenha().length() < 8) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A senha deve ter no mínimo 8 caracteres.");
        }

        // Mesma mensagem para e-mail inexistente, código errado ou acesso já
        // ativado: não revela quais e-mails estão cadastrados.
        String codigo = dto.codigo() != null ? dto.codigo().trim() : "";
        Paciente paciente = pacienteRepository.findByEmail(dto.email().trim())
                .filter(encontrado -> encontrado.getSenha() == null
                        && encontrado.getCodigoAtivacao() != null
                        && encontrado.getCodigoAtivacao().equalsIgnoreCase(codigo))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, ATIVACAO_INVALIDA));

        paciente.setSenha(passwordEncoder.encode(dto.novaSenha()));
        paciente.setCodigoAtivacao(null);
        pacienteRepository.save(paciente);
    }

    public void solicitarVinculo(Long pacienteId, SolicitarVinculoDTO dto) {
        if (dto.cuidadorEmail() == null || dto.cuidadorEmail().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o e-mail do cuidador.");
        }

        Paciente paciente = buscarEntidadePorId(pacienteId);
        if (paciente.getCuidador() != null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Você já tem um cuidador vinculado.");
        }

        Cuidador cuidador = cuidadorRepository.findByEmail(dto.cuidadorEmail())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Nenhum cuidador cadastrado com esse e-mail."));

        paciente.setCuidadorSolicitado(cuidador);
        pacienteRepository.save(paciente);
    }

    public List<PacienteRespostaDTO> listarSolicitacoes(Long cuidadorId) {
        return pacienteRepository.findByCuidadorSolicitadoId(cuidadorId).stream().map(PacienteRespostaDTO::paraDTO).toList();
    }

    public void aceitarVinculo(Long pacienteId, AcaoVinculoDTO dto) {
        Paciente paciente = validarSolicitacaoPendente(pacienteId, dto);
        paciente.setCuidador(paciente.getCuidadorSolicitado());
        paciente.setCuidadorSolicitado(null);
        pacienteRepository.save(paciente);
    }

    public void recusarVinculo(Long pacienteId, AcaoVinculoDTO dto) {
        Paciente paciente = validarSolicitacaoPendente(pacienteId, dto);
        paciente.setCuidadorSolicitado(null);
        pacienteRepository.save(paciente);
    }

    private Paciente validarSolicitacaoPendente(Long pacienteId, AcaoVinculoDTO dto) {
        Paciente paciente = buscarEntidadePorId(pacienteId);
        if (dto.cuidadorId() == null
                || paciente.getCuidadorSolicitado() == null
                || !paciente.getCuidadorSolicitado().getId().equals(dto.cuidadorId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Não há solicitação pendente desse cuidador para esse paciente.");
        }
        return paciente;
    }

    public void enviarAlertaManual(Long pacienteId, EnviarAlertaManualDTO dto) {
        Paciente paciente = buscarEntidadePorId(pacienteId);
        if (dto.cuidadorId() == null
                || paciente.getCuidador() == null
                || !paciente.getCuidador().getId().equals(dto.cuidadorId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Esse paciente não está vinculado a esse cuidador.");
        }

        String mensagem = dto.mensagem() != null && !dto.mensagem().isBlank()
                ? dto.mensagem()
                : "Seu cuidador pediu para lembrá-lo de tomar sua medicação.";

        paciente.setAlertaManualPendente(true);
        paciente.setAlertaManualMensagem(mensagem);
        pacienteRepository.save(paciente);
    }

    public void confirmarAlertaManual(Long pacienteId) {
        Paciente paciente = buscarEntidadePorId(pacienteId);
        paciente.setAlertaManualPendente(false);
        paciente.setAlertaManualMensagem(null);
        pacienteRepository.save(paciente);
    }

    public void desvincularCuidador(Long pacienteId, AcaoVinculoDTO dto) {
        Paciente paciente = buscarEntidadePorId(pacienteId);
        if (dto.cuidadorId() == null
                || paciente.getCuidador() == null
                || !paciente.getCuidador().getId().equals(dto.cuidadorId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Esse paciente não está vinculado a esse cuidador.");
        }

        paciente.setCuidador(null);
        paciente.setPermiteAlteracoes(false);
        pacienteRepository.save(paciente);
    }

    public void atualizarPermissaoAlteracoes(Long pacienteId, AtualizarPermissaoDTO dto) {
        Paciente paciente = buscarEntidadePorId(pacienteId);
        if (dto.cuidadorId() == null
                || paciente.getCuidador() == null
                || !paciente.getCuidador().getId().equals(dto.cuidadorId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Esse paciente não está vinculado a esse cuidador.");
        }

        paciente.setPermiteAlteracoes(dto.permiteAlteracoes());
        pacienteRepository.save(paciente);
    }

    public void excluir(Long id) {
        if (!pacienteRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Paciente não encontrado.");
        }
        pacienteRepository.deleteById(id);
    }

    private static String gerarCodigoAtivacao() {
        StringBuilder codigo = new StringBuilder(TAMANHO_CODIGO);
        for (int i = 0; i < TAMANHO_CODIGO; i++) {
            codigo.append(ALFABETO_CODIGO.charAt(ALEATORIO.nextInt(ALFABETO_CODIGO.length())));
        }
        return codigo.toString();
    }

    private Paciente salvar(Paciente paciente) {
        try {
            return pacienteRepository.save(paciente);
        } catch (DataIntegrityViolationException erro) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Já existe um paciente cadastrado com esse e-mail.", erro);
        }
    }

    private Paciente buscarEntidadePorId(Long id) {
        return pacienteRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Paciente não encontrado."));
    }

    private Cuidador buscarCuidadorOuNulo(Long cuidadorId) {
        if (cuidadorId == null) {
            return null;
        }
        return cuidadorRepository.findById(cuidadorId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Cuidador não encontrado."));
    }
}
