package com.cuidamed.cuidamed_backend.auth;

import java.util.List;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.conta.Contato;
import com.cuidamed.cuidamed_backend.cuidador.Cuidador;
import com.cuidamed.cuidamed_backend.cuidador.CuidadorRepository;
import com.cuidamed.cuidamed_backend.paciente.Paciente;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;
import com.cuidamed.cuidamed_backend.seguranca.ServicoToken;
import com.cuidamed.cuidamed_backend.seguranca.UsuarioAutenticado;

@Service
public class AuthService {

    private static final String CREDENCIAIS_INVALIDAS = "E-mail, telefone ou senha inválidos.";

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
        String identificador = dto.identificador();
        if (!Contato.temTexto(identificador) || !Contato.temTexto(dto.senha())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe e-mail ou telefone e a senha.");
        }

        // E-mail ("@") ou telefone (só os dígitos contam: com ou sem máscara).
        List<Paciente> pacientes;
        List<Cuidador> cuidadores;
        if (Contato.ehEmail(identificador)) {
            String email = identificador.trim();
            pacientes = pacienteRepository.findByEmail(email).stream().toList();
            cuidadores = cuidadorRepository.findByEmail(email).stream().toList();
        } else {
            String digitos = Contato.digitos(identificador);
            if (digitos.length() < 10) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, CREDENCIAIS_INVALIDAS);
            }
            pacientes = pacienteRepository.findByTelefoneDigitos(digitos);
            cuidadores = cuidadorRepository.findByTelefoneDigitos(digitos);
        }

        Optional<Paciente> paciente = pacientes.stream()
                .filter(p -> p.getSenha() != null && passwordEncoder.matches(dto.senha(), p.getSenha()))
                .findFirst();
        if (paciente.isPresent()) {
            return resposta(UsuarioAutenticado.PACIENTE, paciente.get().getId());
        }

        Optional<Cuidador> cuidador = cuidadores.stream()
                .filter(c -> passwordEncoder.matches(dto.senha(), c.getSenha()))
                .findFirst();
        if (cuidador.isPresent()) {
            return resposta(UsuarioAutenticado.CUIDADOR, cuidador.get().getId());
        }

        throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, CREDENCIAIS_INVALIDAS);
    }

    private LoginRespostaDTO resposta(String tipo, Long id) {
        return new LoginRespostaDTO(tipo, id, servicoToken.gerar(tipo, id));
    }
}
