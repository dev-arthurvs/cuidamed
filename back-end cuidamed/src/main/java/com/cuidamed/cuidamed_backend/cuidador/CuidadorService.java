package com.cuidamed.cuidamed_backend.cuidador;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.conta.Contato;
import com.cuidamed.cuidamed_backend.conta.VerificadorDeContato;

@Service
public class CuidadorService {

    private final CuidadorRepository cuidadorRepository;
    private final PasswordEncoder passwordEncoder;
    private final VerificadorDeContato verificadorDeContato;

    public CuidadorService(
            CuidadorRepository cuidadorRepository,
            PasswordEncoder passwordEncoder,
            VerificadorDeContato verificadorDeContato) {
        this.cuidadorRepository = cuidadorRepository;
        this.passwordEncoder = passwordEncoder;
        this.verificadorDeContato = verificadorDeContato;
    }

    public CuidadorRespostaDTO criar(CuidadorCriacaoDTO dto) {
        if (dto.nome() == null || dto.nome().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o nome do cuidador.");
        }
        // E-mail ou telefone: é com um deles que o cuidador entra no app.
        verificadorDeContato.exigirEmailOuTelefone(dto.email(), dto.telefone());
        if (dto.senha() == null || dto.senha().length() < 8) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A senha deve ter no mínimo 8 caracteres.");
        }
        verificadorDeContato.exigirTelefoneLivre(dto.telefone(), null, null);

        Cuidador cuidador = new Cuidador();
        cuidador.setNome(dto.nome());
        cuidador.setEmail(Contato.emailOuNulo(dto.email()));
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

        verificadorDeContato.exigirEmailOuTelefone(dto.email(), dto.telefone());
        // Só quando mudou: contas antigas podem ter telefone repetido ou incompleto
        // e não devem ficar sem conseguir salvar os outros dados.
        if (!Contato.digitos(dto.telefone()).equals(Contato.digitos(cuidador.getTelefone()))) {
            verificadorDeContato.exigirTelefoneLivre(dto.telefone(), null, id);
        }

        cuidador.setNome(dto.nome());
        cuidador.setEmail(Contato.emailOuNulo(dto.email()));
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
