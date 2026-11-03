package com.cuidamed.cuidamed_backend.cuidador;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CuidadorRepository extends JpaRepository<Cuidador, Long> {

    Optional<Cuidador> findByEmail(String email);

    /** Pelo telefone, comparando só os dígitos (o número fica salvo com máscara). */
    @Query(value = "SELECT * FROM cuidador WHERE regexp_replace(COALESCE(telefone_cui, ''), '[^0-9]', '', 'g') = :digitos",
            nativeQuery = true)
    List<Cuidador> findByTelefoneDigitos(@Param("digitos") String digitos);
}
