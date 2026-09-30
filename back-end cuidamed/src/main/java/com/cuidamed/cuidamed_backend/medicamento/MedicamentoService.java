package com.cuidamed.cuidamed_backend.medicamento;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.paciente.Paciente;
import com.cuidamed.cuidamed_backend.paciente.PacienteRepository;

@Service
public class MedicamentoService {

    private static final DateTimeFormatter FORMATO_HORA = DateTimeFormatter.ofPattern("HH:mm");

    private final MedicamentoRepository medicamentoRepository;
    private final PacienteRepository pacienteRepository;

    public MedicamentoService(MedicamentoRepository medicamentoRepository, PacienteRepository pacienteRepository) {
        this.medicamentoRepository = medicamentoRepository;
        this.pacienteRepository = pacienteRepository;
    }

    public MedicamentoRespostaDTO criar(MedicamentoCriacaoDTO dto) {
        if (dto.pacienteId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o paciente do medicamento.");
        }
        validarCamposObrigatorios(
                dto.nome(), dto.dosagem(), dto.forma(), dto.frequencia(), dto.dataInicio(), dto.horarios(),
                dto.quantidadeEstoque(), dto.quantidadePorDose());
        validarPeriodo(dto.dataInicio(), dto.dataFim());

        Paciente paciente = pacienteRepository.findById(dto.pacienteId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Paciente não encontrado."));

        Medicamento medicamento = new Medicamento();
        medicamento.setPaciente(paciente);
        medicamento.setNome(dto.nome());
        medicamento.setDosagem(dto.dosagem());
        medicamento.setForma(dto.forma());
        medicamento.setFrequencia(dto.frequencia());
        medicamento.setDataInicio(dto.dataInicio());
        medicamento.setDataFim(dto.dataFim());
        medicamento.setObservacoes(dto.observacoes());
        boolean ehPomada = dto.forma() == FormaMedicamento.POMADA;
        medicamento.setQuantidadeEstoque(ehPomada ? null : dto.quantidadeEstoque());
        medicamento.setQuantidadePorDose(ehPomada ? null : dto.quantidadePorDose());
        substituirHorarios(medicamento, dto.horarios());

        return MedicamentoRespostaDTO.paraDTO(medicamentoRepository.save(medicamento));
    }

    public List<MedicamentoRespostaDTO> listarPorPaciente(Long pacienteId) {
        return medicamentoRepository.findByPacienteId(pacienteId).stream().map(MedicamentoRespostaDTO::paraDTO).toList();
    }

    public MedicamentoRespostaDTO buscarPorId(Long id) {
        return MedicamentoRespostaDTO.paraDTO(buscarEntidadePorId(id));
    }

    public MedicamentoRespostaDTO atualizar(Long id, MedicamentoAtualizacaoDTO dto) {
        validarCamposObrigatorios(
                dto.nome(), dto.dosagem(), dto.forma(), dto.frequencia(), dto.dataInicio(), dto.horarios(),
                dto.quantidadeEstoque(), dto.quantidadePorDose());
        validarPeriodo(dto.dataInicio(), dto.dataFim());

        Medicamento medicamento = buscarEntidadePorId(id);
        medicamento.setNome(dto.nome());
        medicamento.setDosagem(dto.dosagem());
        medicamento.setForma(dto.forma());
        medicamento.setFrequencia(dto.frequencia());
        medicamento.setDataInicio(dto.dataInicio());
        medicamento.setDataFim(dto.dataFim());
        medicamento.setObservacoes(dto.observacoes());
        boolean ehPomada = dto.forma() == FormaMedicamento.POMADA;
        medicamento.setQuantidadeEstoque(ehPomada ? null : dto.quantidadeEstoque());
        medicamento.setQuantidadePorDose(ehPomada ? null : dto.quantidadePorDose());
        substituirHorarios(medicamento, dto.horarios());

        return MedicamentoRespostaDTO.paraDTO(medicamentoRepository.save(medicamento));
    }

    public void excluir(Long id) {
        if (!medicamentoRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Medicamento não encontrado.");
        }
        medicamentoRepository.deleteById(id);
    }

    private Medicamento buscarEntidadePorId(Long id) {
        return medicamentoRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Medicamento não encontrado."));
    }

    // Não faz clear()+recriar tudo: horários que continuam iguais entre a edição
    // anterior e a nova ficam intocados. Um clear()+add() com o mesmo horário fazia
    // o Hibernate tentar inserir a linha nova antes de apagar a antiga na mesma
    // flush, violando a constraint de unicidade (medicamento_id_hor, hora_hor).
    private void substituirHorarios(Medicamento medicamento, List<String> horariosTexto) {
        Set<LocalTime> novosHorarios = horariosTexto.stream()
                .map(this::interpretarHora)
                .collect(Collectors.toCollection(LinkedHashSet::new));

        medicamento.getHorarios().removeIf(horario -> !novosHorarios.contains(horario.getHora()));

        Set<LocalTime> horariosExistentes = medicamento.getHorarios().stream().map(Horario::getHora).collect(Collectors.toSet());

        for (LocalTime hora : novosHorarios) {
            if (!horariosExistentes.contains(hora)) {
                Horario horario = new Horario();
                horario.setMedicamento(medicamento);
                horario.setHora(hora);
                medicamento.getHorarios().add(horario);
            }
        }
    }

    private LocalTime interpretarHora(String horarioTexto) {
        try {
            return LocalTime.parse(horarioTexto, FORMATO_HORA);
        } catch (DateTimeParseException erro) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "Horário inválido: \"" + horarioTexto + "\". Use o formato HH:mm.", erro);
        }
    }

    private void validarPeriodo(LocalDate dataInicio, LocalDate dataFim) {
        if (dataInicio != null && dataFim != null && dataFim.isBefore(dataInicio)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST, "A data de fim não pode ser anterior à data de início.");
        }
    }

    // Pomada não tem controle de estoque: a "dosagem" ali é só a concentração da
    // substância (ex.: "1%"), informação visual pra comprar o produto certo — não
    // dá pra contar "unidades" de pomada do mesmo jeito que comprimido ou xarope.
    private void validarCamposObrigatorios(
            String nome, String dosagem, FormaMedicamento forma, FrequenciaMedicamento frequencia,
            LocalDate dataInicio, List<String> horarios, Integer quantidadeEstoque, Integer quantidadePorDose) {
        if (nome == null || nome.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe o nome do medicamento.");
        }
        if (dosagem == null || dosagem.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe a dosagem do medicamento.");
        }
        if (forma == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe a forma do medicamento.");
        }
        if (frequencia == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe a frequência do medicamento.");
        }
        if (dataInicio == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe a data de início do medicamento.");
        }
        if (horarios == null || horarios.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Adicione ao menos um horário de dose.");
        }
        if (forma == FormaMedicamento.POMADA) {
            return;
        }
        if (quantidadeEstoque == null || quantidadeEstoque < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe a quantidade em estoque.");
        }
        if (quantidadePorDose == null || quantidadePorDose <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Informe a quantidade usada por dose.");
        }
    }
}
