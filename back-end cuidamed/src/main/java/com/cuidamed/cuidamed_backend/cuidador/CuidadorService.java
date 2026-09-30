package com.cuidamed.cuidamed_backend.cuidador;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class CuidadorService {

    private final CuidadorRepository cuidadorRepository;
    private final PasswordEncoder passwordEncoder;

    public CuidadorService(CuidadorRepository cuidadorRepository, PasswordEncoder passwordEncoder) {
        this.cuidadorRepository = cuidadorRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public CuidadorRespostaDTO criar(CuidadorCriacaoDTO dto) {
        if (dto.nome() == null || dto.nome().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o nome do cuidador.");
        }
        if (dto.email() == null || dto.email().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o e-mail do cuidador.");
        }
        if (dto.senha() == null || dto.senha().length() < 8) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A senha deve ter no mínimo 8 caracteres.");
        }

        Cuidador cuidador = new Cuidador();
        cuidador.setNome(dto.nome());
        cuidador.setEmail(dto.email());
        cuidador.setSenha(passwordEncoder.encode(dto.senha()));
        cuidador.setProfissao(dto.profissao());
        cuidador.setTelefone(dto.telefone());

        return CuidadorRespostaDTO.paraDTO(salvar(cuidador));
    }

    public CuidadorRespostaDTO buscarPorId(Long id) {
        return CuidadorRespostaDTO.paraDTO(buscarEntidadePorId(id));
    }

    public CuidadorRespostaDTO atualizar(Long id, CuidadorAtualizacaoDTO dto) {
        Cuidador cuidador = buscarEntidadePorId(id);

        if (dto.nome() == null || dto.nome().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o nome do cuidador.");
        }

        cuidador.setNome(dto.nome());
        cuidador.setEmail(dto.email());
        cuidador.setProfissao(dto.profissao());
        cuidador.setTelefone(dto.telefone());

        return CuidadorRespostaDTO.paraDTO(salvar(cuidador));
    }

    public void alterarSenha(Long id, AlterarSenhaDTO dto) {
        Cuidador cuidador = buscarEntidadePorId(id);

        if (!passwordEncoder.matches(dto.senhaAtual(), cuidador.getSenha())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Senha atual incorreta.");
        }
        if (dto.novaSenha() == null || dto.novaSenha().length() < 8) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A nova senha deve ter no mínimo 8 caracteres.");
        }

        cuidador.setSenha(passwordEncoder.encode(dto.novaSenha()));
        cuidadorRepository.save(cuidador);
    }

    private Cuidador salvar(Cuidador cuidador) {
        try {
            return cuidadorRepository.save(cuidador);
        } catch (DataIntegrityViolationException erro) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Já existe um cuidador cadastrado com esse e-mail.", erro);
        }
    }

    private Cuidador buscarEntidadePorId(Long id) {
        return cuidadorRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Cuidador não encontrado."));
    }
}
