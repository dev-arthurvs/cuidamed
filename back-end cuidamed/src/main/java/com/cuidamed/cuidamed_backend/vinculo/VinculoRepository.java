package com.cuidamed.cuidamed_backend.vinculo;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VinculoRepository extends JpaRepository<Vinculo, Long> {

    Optional<Vinculo> findFirstByPacienteIdAndSituacao(Long pacienteId, SituacaoVinculo situacao);

    @EntityGraph(attributePaths = {"paciente", "cuidador"})
    List<Vinculo> findByCuidadorIdAndSituacaoOrderByIdAsc(Long cuidadorId, SituacaoVinculo situacao);

    @EntityGraph(attributePaths = "cuidador")
    List<Vinculo> findByPacienteIdInAndSituacao(Collection<Long> pacienteIds, SituacaoVinculo situacao);

    boolean existsByPacienteIdAndSituacao(Long pacienteId, SituacaoVinculo situacao);

    boolean existsByPacienteIdAndCuidadorIdAndSituacao(Long pacienteId, Long cuidadorId, SituacaoVinculo situacao);

    boolean existsByPacienteIdAndCuidadorIdAndSituacaoIn(
            Long pacienteId, Long cuidadorId, Collection<SituacaoVinculo> situacoes);
}
