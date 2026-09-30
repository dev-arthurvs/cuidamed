package com.cuidamed.cuidamed_backend.cuidador;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CuidadorRepository extends JpaRepository<Cuidador, Long> {

    Optional<Cuidador> findByEmail(String email);
}
