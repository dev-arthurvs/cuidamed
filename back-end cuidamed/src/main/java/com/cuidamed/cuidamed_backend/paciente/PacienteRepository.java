package com.cuidamed.cuidamed_backend.paciente;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface PacienteRepository extends JpaRepository<Paciente, Long> {

    List<Paciente> findByCuidadorId(Long cuidadorId);

    List<Paciente> findByCuidadorSolicitadoId(Long cuidadorId);

    Optional<Paciente> findByEmail(String email);
}
