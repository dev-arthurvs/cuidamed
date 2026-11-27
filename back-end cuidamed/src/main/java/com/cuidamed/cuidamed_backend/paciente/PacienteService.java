package com.cuidamed.cuidamed_backend.paciente;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.conta.Contato;
import com.cuidamed.cuidamed_backend.conta.VerificadorDeContato;
import com.cuidamed.cuidamed_backend.cuidador.Cuidador;
import com.cuidamed.cuidamed_backend.cuidador.CuidadorRepository;
import com.cuidamed.cuidamed_backend.vinculo.SituacaoVinculo;
import com.cuidamed.cuidamed_backend.vinculo.Vinculo;
import com.cuidamed.cuidamed_backend.vinculo.VinculoRepository;

@Service
public class PacienteService {

    private final PacienteRepository pacienteRepository;
    private final CuidadorRepository cuidadorRepository;
    private final PasswordEncoder passwordEncoder;
    private final VinculoRepository vinculoRepository;
    private final VerificadorDeContato verificadorDeContato;

    private static final String ALFABETO_CODIGO = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private static final int TAMANHO_CODIGO = 6;
    private static final int HORAS_VALIDADE_NOVA_SENHA = 24;
    private static final SecureRandom ALEATORIO = new SecureRandom();
    private static final String ATIVACAO_INVALIDA = "E-mail, telefone ou código de ativação inválidos.";
    private static final String NAO_VINCULADO = "Esse paciente não está vinculado a esse cuidador.";

    public PacienteService(
            PacienteRepository pacienteRepository,
            CuidadorRepository cuidadorRepository,
            PasswordEncoder passwordEncoder,
            VinculoRepository vinculoRepository,
            VerificadorDeContato verificadorDeContato) {
        this.pacienteRepository = pacienteRepository;
        this.cuidadorRepository = cuidadorRepository;
        this.passwordEncoder = passwordEncoder;
        this.vinculoRepository = vinculoRepository;
        this.verificadorDeContato = verificadorDeContato;
    }

    @Transactional
    public PacienteRespostaDTO criar(PacienteCriacaoDTO dto) {
        if (dto.nome() == null || dto.nome().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o nome do paciente.");
        }

        boolean temSenha = dto.senha() != null && !dto.senha().isBlank();
        if (temSenha) {
            verificadorDeContato.exigirEmailOuTelefone(dto.email(), dto.telefone());
        }
        verificadorDeContato.exigirTelefoneLivre(dto.telefone(), null, null);

        Paciente paciente = new Paciente();
        paciente.setNome(dto.nome());
        paciente.setEmail(Contato.emailOuNulo(dto.email()));
        paciente.setSenha(temSenha ? passwordEncoder.encode(dto.senha()) : null);
        paciente.setCodigoAtivacao(temSenha ? null : gerarCodigoAtivacao());
        paciente.setDataNascimento(dto.dataNascimento());
        paciente.setSexo(dto.sexo());
        paciente.setEnfermidade(dto.enfermidade());
        paciente.setTelefone(dto.telefone());
        paciente.setEndereco(dto.endereco());
        paciente.setObservacoesClinicas(dto.observacoesClinicas());
        Cuidador cuidador = buscarCuidadorOuNulo(dto.cuidadorId());
        Paciente salvo = salvar(paciente);
        if (cuidador != null) {
            vinculoRepository.save(Vinculo.ativo(salvo, cuidador));
        }
        return paraDTO(salvo);
    }

    @Transactional(readOnly = true)
    public PacienteRespostaDTO buscarPorId(Long id) {
        return paraDTO(buscarEntidadePorId(id));
    }

    @Transactional(readOnly = true)
    public List<PacienteRespostaDTO> listarPorCuidador(Long cuidadorId) {
        List<Vinculo> ativos = vinculoRepository.findByCuidadorIdAndSituacaoOrderByIdAsc(cuidadorId, SituacaoVinculo.ATIVO);
        java.util.Map<Long, Vinculo> pendentes = vinculoRepository
                .findByPacienteIdInAndSituacao(ativos.stream().map(vinculo -> vinculo.getPaciente().getId()).toList(), SituacaoVinculo.PENDENTE)
                .stream()
                .collect(java.util.stream.Collectors.toMap(vinculo -> vinculo.getPaciente().getId(), vinculo -> vinculo, (primeiro, outro) -> primeiro));
        return ativos.stream()
                .map(vinculo -> PacienteRespostaDTO.paraDTO(vinculo.getPaciente(), vinculo, pendentes.get(vinculo.getPaciente().getId())))
                .toList();
    }

    @Transactional
    public PacienteRespostaDTO atualizar(Long id, PacienteAtualizacaoDTO dto) {
        Paciente paciente = buscarEntidadePorId(id);

        if (dto.nome() == null || dto.nome().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o nome do paciente.");
        }

        if (paciente.getSenha() != null) {
            verificadorDeContato.exigirEmailOuTelefone(dto.email(), dto.telefone());
        }
        if (!Contato.digitos(dto.telefone()).equals(Contato.digitos(paciente.getTelefone()))) {
            verificadorDeContato.exigirTelefoneLivre(dto.telefone(), id, null);
        }

        paciente.setNome(dto.nome());
        paciente.setEmail(Contato.emailOuNulo(dto.email()));
        paciente.setDataNascimento(dto.dataNascimento());
        paciente.setSexo(dto.sexo());
        paciente.setEnfermidade(dto.enfermidade());
        paciente.setTelefone(dto.telefone());
        paciente.setEndereco(dto.endereco());
        paciente.setObservacoesClinicas(dto.observacoesClinicas());

        return paraDTO(salvar(paciente));
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
        String identificador = dto.identificador();
        if (!Contato.temTexto(identificador)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o e-mail ou o telefone do paciente.");
        }
        if (dto.novaSenha() == null || dto.novaSenha().length() < 8) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A senha deve ter no mínimo 8 caracteres.");
        }

        String codigo = dto.codigo() != null ? dto.codigo().trim() : "";
        List<Paciente> candidatos = Contato.ehEmail(identificador)
                ? pacienteRepository.findByEmail(identificador.trim()).stream().toList()
                : pacienteRepository.findByTelefoneDigitos(Contato.digitos(identificador));
        Paciente paciente = candidatos.stream()
                .filter(encontrado -> encontrado.getCodigoValido() != null
                        && encontrado.getCodigoValido().equalsIgnoreCase(codigo))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, ATIVACAO_INVALIDA));

        paciente.setSenha(passwordEncoder.encode(dto.novaSenha()));
        paciente.setCodigoAtivacao(null);
        paciente.setCodigoExpiraEm(null);
        pacienteRepository.save(paciente);
    }

    @Transactional
    public PacienteRespostaDTO gerarCodigoNovaSenha(Long pacienteId, Long cuidadorId) {
        Paciente paciente = buscarEntidadePorId(pacienteId);
        vinculoAtivoDoCuidador(pacienteId, cuidadorId);
        if (paciente.getSenha() != null) {
            paciente.setCodigoAtivacao(gerarCodigoAtivacao());
            paciente.setCodigoExpiraEm(LocalDateTime.now().plusHours(HORAS_VALIDADE_NOVA_SENHA));
            pacienteRepository.save(paciente);
        }
        return paraDTO(paciente);
    }

    @Transactional
    public void solicitarVinculo(Long pacienteId, SolicitarVinculoDTO dto) {
        String contatoCuidador = dto.cuidadorEmail();
        if (!Contato.temTexto(contatoCuidador)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o e-mail ou o telefone do cuidador.");
        }

        Paciente paciente = buscarEntidadePorId(pacienteId);
        if (vinculoRepository.existsByPacienteIdAndSituacao(pacienteId, SituacaoVinculo.ATIVO)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Você já tem um cuidador vinculado.");
        }

        Optional<Cuidador> encontrado = Contato.ehEmail(contatoCuidador)
                ? cuidadorRepository.findByEmail(contatoCuidador.trim())
                : cuidadorRepository.findByTelefoneDigitos(Contato.digitos(contatoCuidador)).stream().findFirst();
        Cuidador cuidador = encontrado.orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_FOUND, "Nenhum cuidador cadastrado com esse e-mail ou telefone."));

        vinculoRepository.findFirstByPacienteIdAndSituacao(pacienteId, SituacaoVinculo.PENDENTE).ifPresent(anterior -> {
            anterior.encerrar(SituacaoVinculo.CANCELADO);
            vinculoRepository.saveAndFlush(anterior);
        });
        vinculoRepository.save(Vinculo.pedido(paciente, cuidador));
    }

    @Transactional(readOnly = true)
    public List<PacienteRespostaDTO> listarSolicitacoes(Long cuidadorId) {
        return vinculoRepository.findByCuidadorIdAndSituacaoOrderByIdAsc(cuidadorId, SituacaoVinculo.PENDENTE).stream()
                .map(vinculo -> paraDTO(vinculo.getPaciente()))
                .toList();
    }

    @Transactional
    public void aceitarVinculo(Long pacienteId, AcaoVinculoDTO dto) {
        Vinculo pedido = pedidoPendenteDoCuidador(pacienteId, dto.cuidadorId());
        if (vinculoRepository.existsByPacienteIdAndSituacao(pacienteId, SituacaoVinculo.ATIVO)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Esse paciente já tem um cuidador vinculado.");
        }
        pedido.aceitar();
        vinculoRepository.save(pedido);
    }

    @Transactional
    public void recusarVinculo(Long pacienteId, AcaoVinculoDTO dto) {
        Vinculo pedido = pedidoPendenteDoCuidador(pacienteId, dto.cuidadorId());
        pedido.encerrar(SituacaoVinculo.RECUSADO);
        vinculoRepository.save(pedido);
    }

    private Vinculo pedidoPendenteDoCuidador(Long pacienteId, Long cuidadorId) {
        return vinculoRepository.findFirstByPacienteIdAndSituacao(pacienteId, SituacaoVinculo.PENDENTE)
                .filter(pedido -> cuidadorId != null && pedido.getCuidador().getId().equals(cuidadorId))
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Não há solicitação pendente desse cuidador para esse paciente."));
    }

    private Vinculo vinculoAtivoDoCuidador(Long pacienteId, Long cuidadorId) {
        return vinculoRepository.findFirstByPacienteIdAndSituacao(pacienteId, SituacaoVinculo.ATIVO)
                .filter(vinculo -> cuidadorId != null && vinculo.getCuidador().getId().equals(cuidadorId))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, NAO_VINCULADO));
    }

    @Transactional
    public void enviarAlertaManual(Long pacienteId, EnviarAlertaManualDTO dto) {
        Paciente paciente = buscarEntidadePorId(pacienteId);
        vinculoAtivoDoCuidador(pacienteId, dto.cuidadorId());

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

    @Transactional
    public void desvincularCuidador(Long pacienteId, AcaoVinculoDTO dto) {
        Paciente paciente = buscarEntidadePorId(pacienteId);
        Vinculo vinculo = vinculoAtivoDoCuidador(pacienteId, dto.cuidadorId());
        vinculo.encerrar(SituacaoVinculo.ENCERRADO);
        vinculoRepository.save(vinculo);

        paciente.setPermiteAlteracoes(false);
        pacienteRepository.save(paciente);
    }

    @Transactional
    public void atualizarPermissaoAlteracoes(Long pacienteId, AtualizarPermissaoDTO dto) {
        Paciente paciente = buscarEntidadePorId(pacienteId);
        vinculoAtivoDoCuidador(pacienteId, dto.cuidadorId());

        paciente.setPermiteAlteracoes(dto.permiteAlteracoes());
        pacienteRepository.save(paciente);
    }

    public void excluir(Long id) {
        if (!pacienteRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Paciente não encontrado.");
        }
        pacienteRepository.deleteById(id);
    }

    private PacienteRespostaDTO paraDTO(Paciente paciente) {
        Optional<Vinculo> ativo = vinculoRepository.findFirstByPacienteIdAndSituacao(paciente.getId(), SituacaoVinculo.ATIVO);
        Optional<Vinculo> pendente =
                vinculoRepository.findFirstByPacienteIdAndSituacao(paciente.getId(), SituacaoVinculo.PENDENTE);
        return PacienteRespostaDTO.paraDTO(paciente, ativo.orElse(null), pendente.orElse(null));
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
