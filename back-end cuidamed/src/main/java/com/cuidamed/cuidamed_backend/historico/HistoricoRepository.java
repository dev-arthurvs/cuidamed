package com.cuidamed.cuidamed_backend.historico;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface HistoricoRepository extends JpaRepository<Historico, Long> {

    List<Historico> findByPacienteIdOrderByDataDescHoraDesc(Long pacienteId);

    List<Historico> findByPacienteIdAndDataOrderByHoraDesc(Long pacienteId, LocalDate data);

    List<Historico> findByPacienteIdAndMedicamentoIdOrderByDataDescHoraDesc(Long pacienteId, Long medicamentoId);

    List<Historico> findByPacienteIdAndDataAndMedicamentoIdOrderByHoraDesc(Long pacienteId, LocalDate data, Long medicamentoId);

    boolean existsByMedicamentoIdAndDataAndHora(Long medicamentoId, LocalDate data, LocalTime hora);
}
