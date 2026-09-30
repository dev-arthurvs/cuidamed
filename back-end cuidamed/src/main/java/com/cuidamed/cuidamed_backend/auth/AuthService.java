package com.cuidamed.cuidamed_backend.auth;

import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.cuidador.Cuidador;
import com.cuidamed.cuidamed_backend.cuidador.CuidadorRepository;
import com.cuidamed.cuidamed_backend.paciente.Paciente;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;
import com.cuidamed.cuidamed_backend.seguranca.ServicoToken;
import com.cuidamed.cuidamed_backend.seguranca.UsuarioAutenticado;

@Service
public class AuthService {

    private static final String CREDENCIAIS_INVALIDAS = "E-mail ou senha inválidos.";

    private final PacienteRepository pacienteRepository;
    private final CuidadorRepository cuidadorRepository;
    private final PasswordEncoder passwordEncoder;
    private final ServicoToken servicoToken;

    public AuthService(
            PacienteRepository pacienteRepository,
            CuidadorRepository cuidadorRepository,
            PasswordEncoder passwordEncoder,
            ServicoToken servicoToken) {
        this.pacienteRepository = pacienteRepository;
        this.cuidadorRepository = cuidadorRepository;
        this.passwordEncoder = passwordEncoder;
        this.servicoToken = servicoToken;
    }

    public LoginRespostaDTO login(LoginRequisicaoDTO dto) {
        if (dto.email() == null || dto.email().isBlank() || dto.senha() == null || dto.senha().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe e-mail e senha.");
        }

        Optional<Paciente> paciente = pacienteRepository.findByEmail(dto.email());
        if (paciente.isPresent() && paciente.get().getSenha() != null
                && passwordEncoder.matches(dto.senha(), paciente.get().getSenha())) {
            return resposta(UsuarioAutenticado.PACIENTE, paciente.get().getId());
        }

        Optional<Cuidador> cuidador = cuidadorRepository.findByEmail(dto.email());
        if (cuidador.isPresent() && passwordEncoder.matches(dto.senha(), cuidador.get().getSenha())) {
            return resposta(UsuarioAutenticado.CUIDADOR, cuidador.get().getId());
        }

        throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, CREDENCIAIS_INVALIDAS);
    }

    private LoginRespostaDTO resposta(String tipo, Long id) {
        return new LoginRespostaDTO(tipo, id, servicoToken.gerar(tipo, id));
    }
}
