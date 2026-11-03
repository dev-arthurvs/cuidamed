package com.cuidamed.cuidamed_backend.paciente;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PacienteRepository extends JpaRepository<Paciente, Long> {

    Optional<Paciente> findByEmail(String email);

    /** Pelo telefone, comparando só os dígitos (o número fica salvo com máscara). */
    @Query(value = "SELECT * FROM paciente WHERE regexp_replace(COALESCE(telefone_pac, ''), '[^0-9]', '', 'g') = :digitos",
            nativeQuery = true)
    List<Paciente> findByTelefoneDigitos(@Param("digitos") String digitos);
}
