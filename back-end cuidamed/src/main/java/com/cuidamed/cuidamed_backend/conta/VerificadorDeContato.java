package com.cuidamed.cuidamed_backend.conta;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.cuidador.CuidadorRepository;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;

@Component
public class VerificadorDeContato {

    private final PacienteRepository pacienteRepository;
    private final CuidadorRepository cuidadorRepository;

    public VerificadorDeContato(PacienteRepository pacienteRepository, CuidadorRepository cuidadorRepository) {
        this.pacienteRepository = pacienteRepository;
        this.cuidadorRepository = cuidadorRepository;
    }

    public void exigirTelefoneLivre(String telefone, Long pacienteId, Long cuidadorId) {
        if (!Contato.temTexto(telefone)) {
            return;
        }
        if (!Contato.telefoneValido(telefone)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o telefone com DDD.");
        }
        String digitos = Contato.digitos(telefone);
        boolean emPaciente = pacienteRepository.findByTelefoneDigitos(digitos).stream()
                .anyMatch(paciente -> !paciente.getId().equals(pacienteId));
        boolean emCuidador = cuidadorRepository.findByTelefoneDigitos(digitos).stream()
                .anyMatch(cuidador -> !cuidador.getId().equals(cuidadorId));
        if (emPaciente || emCuidador) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Esse telefone já está cadastrado em outra conta.");
        }
    }

    public void exigirEmailOuTelefone(String email, String telefone) {
        if (!Contato.temTexto(email) && !Contato.temTexto(telefone)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Informe um e-mail ou um telefone — é com ele que você entra no app.");
        }
    }
}
