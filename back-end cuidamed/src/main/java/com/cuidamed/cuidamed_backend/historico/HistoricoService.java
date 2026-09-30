package com.cuidamed.cuidamed_backend.historico;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.medicamento.FrequenciaMedicamento;
import com.cuidamed.cuidamed_backend.medicamento.Medicamento;
import com.cuidamed.cuidamed_backend.medicamento.MedicamentoRepository;
import com.cuidamed.cuidamed_backend.paciente.Paciente;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;

@Service
public class HistoricoService {

    private static final DateTimeFormatter DATA_BR = DateTimeFormatter.ofPattern("dd/MM/yyyy");


    private static final DateTimeFormatter FORMATO_HORA = DateTimeFormatter.ofPattern("HH:mm");

    private final HistoricoRepository historicoRepository;
    private final PacienteRepository pacienteRepository;
    private final MedicamentoRepository medicamentoRepository;

    public HistoricoService(
            HistoricoRepository historicoRepository,
            PacienteRepository pacienteRepository,
            MedicamentoRepository medicamentoRepository) {
        this.historicoRepository = historicoRepository;
        this.pacienteRepository = pacienteRepository;
        this.medicamentoRepository = medicamentoRepository;
    }

    public HistoricoRespostaDTO criar(HistoricoCriacaoDTO dto) {
        if (dto.pacienteId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o paciente do registro.");
        }
        if (dto.medicamentoId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o medicamento do registro.");
        }
        if (dto.data() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe a data da dose.");
        }

        StatusHistorico status = interpretarStatus(dto.status());
        LocalTime hora = interpretarHora(dto.hora());

        Paciente paciente = pacienteRepository.findById(dto.pacienteId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Paciente não encontrado."));

        Medicamento medicamento = medicamentoRepository.findById(dto.medicamentoId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Medicamento não encontrado."));

        if (!medicamento.getPaciente().getId().equals(paciente.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Esse medicamento não pertence ao paciente informado.");
        }

        if (medicamento.getDataInicio() != null && dto.data().isBefore(medicamento.getDataInicio())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Esse tratamento só começa em " + medicamento.getDataInicio().format(DATA_BR) + ".");
        }
        if (medicamento.getDataFim() != null && dto.data().isAfter(medicamento.getDataFim())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Esse tratamento terminou em " + medicamento.getDataFim().format(DATA_BR) + ".");
        }

        if (!medicamento.temDoseEm(dto.data())) {
            String frequencia = medicamento.getFrequencia() == FrequenciaMedicamento.SEMANAL
                    ? "uma vez por semana" : "em dias alternados";
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Esse medicamento não tem dose em " + dto.data().format(DATA_BR) + " (é tomado " + frequencia + ").");
        }

        if (historicoRepository.existsByMedicamentoIdAndDataAndHora(medicamento.getId(), dto.data(), hora)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Já existe um registro de histórico para essa dose.");
        }

        Historico historico = new Historico();
        historico.setPaciente(paciente);
        historico.setMedicamento(medicamento);
        historico.setData(dto.data());
        historico.setHora(hora);
        historico.setNomeMedicamento(medicamento.getNome());
        historico.setDosagem(medicamento.getDosagem());
        historico.setStatus(status);

        if (status == StatusHistorico.TOMADO && medicamento.getQuantidadeEstoque() != null) {
            int consumoPorDose = medicamento.getQuantidadePorDose() != null ? medicamento.getQuantidadePorDose() : 1;
            medicamento.setQuantidadeEstoque(Math.max(0, medicamento.getQuantidadeEstoque() - consumoPorDose));
            medicamentoRepository.save(medicamento);
        }

        return HistoricoRespostaDTO.paraDTO(historicoRepository.save(historico));
    }

    public List<HistoricoRespostaDTO> listarPorPaciente(Long pacienteId, LocalDate data, Long medicamentoId) {
        List<Historico> resultado;
        if (data != null && medicamentoId != null) {
            resultado = historicoRepository.findByPacienteIdAndDataAndMedicamentoIdOrderByHoraDesc(pacienteId, data, medicamentoId);
        } else if (data != null) {
            resultado = historicoRepository.findByPacienteIdAndDataOrderByHoraDesc(pacienteId, data);
        } else if (medicamentoId != null) {
            resultado = historicoRepository.findByPacienteIdAndMedicamentoIdOrderByDataDescHoraDesc(pacienteId, medicamentoId);
        } else {
            resultado = historicoRepository.findByPacienteIdOrderByDataDescHoraDesc(pacienteId);
        }
        return resultado.stream().map(HistoricoRespostaDTO::paraDTO).toList();
    }

    public HistoricoRespostaDTO buscarPorId(Long id) {
        return HistoricoRespostaDTO.paraDTO(
                historicoRepository.findById(id)
                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Registro de histórico não encontrado.")));
    }

    private StatusHistorico interpretarStatus(String statusTexto) {
        if (statusTexto == null || statusTexto.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o status do registro.");
        }
        try {
            return StatusHistorico.valueOf(statusTexto.trim().toUpperCase());
        } catch (IllegalArgumentException erro) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Status inválido: \"" + statusTexto + "\". Use TOMADO, ATRASADO ou PERDIDO.",
                    erro);
        }
    }

    private LocalTime interpretarHora(String horaTexto) {
        if (horaTexto == null || horaTexto.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o horário da dose.");
        }
        try {
            return LocalTime.parse(horaTexto, FORMATO_HORA);
        } catch (DateTimeParseException erro) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Horário inválido: \"" + horaTexto + "\". Use o formato HH:mm.", erro);
        }
    }
}
