package com.cuidamed.cuidamed_backend.vinculo;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface VinculoRepository extends JpaRepository<Vinculo, Long> {

    /** O vínculo ativo (ou o pedido pendente) do paciente, se houver. */
    Optional<Vinculo> findFirstByPacienteIdAndSituacao(Long pacienteId, SituacaoVinculo situacao);

    /** Pacientes do cuidador numa situação (ATIVO = vinculados, PENDENTE = pedidos). */
    List<Vinculo> findByCuidadorIdAndSituacaoOrderByIdAsc(Long cuidadorId, SituacaoVinculo situacao);

    boolean existsByPacienteIdAndSituacao(Long pacienteId, SituacaoVinculo situacao);

    boolean existsByPacienteIdAndCuidadorIdAndSituacao(Long pacienteId, Long cuidadorId, SituacaoVinculo situacao);

    boolean existsByPacienteIdAndCuidadorIdAndSituacaoIn(
            Long pacienteId, Long cuidadorId, Collection<SituacaoVinculo> situacoes);
}
