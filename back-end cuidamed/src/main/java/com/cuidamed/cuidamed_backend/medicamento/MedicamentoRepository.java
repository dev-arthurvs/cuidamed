package com.cuidamed.cuidamed_backend.medicamento;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface MedicamentoRepository extends JpaRepository<Medicamento, Long> {

    List<Medicamento> findByPacienteId(Long pacienteId);
}
