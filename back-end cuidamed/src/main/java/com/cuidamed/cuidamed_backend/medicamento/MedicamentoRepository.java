package com.cuidamed.cuidamed_backend.medicamento;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MedicamentoRepository extends JpaRepository<Medicamento, Long> {

    // Traz os horários junto: sem isso, cada remédio faz mais uma consulta.
    @EntityGraph(attributePaths = "horarios")
    List<Medicamento> findByPacienteId(Long pacienteId);
}
