package com.cuidamed.cuidamed_backend.paciente;

import java.time.Duration;
import java.util.List;
import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.cuidamed.cuidamed_backend.seguranca.Autorizacao;
import com.cuidamed.cuidamed_backend.seguranca.LimitadorDeTentativas;
import com.cuidamed.cuidamed_backend.seguranca.UsuarioAutenticado;

@RestController
public class PacienteController {

    private final PacienteService pacienteService;
    private final Autorizacao autorizacao;
    private final LimitadorDeTentativas limitador;

    // "Ativar meu acesso": até 5 códigos errados por e-mail a cada 15 minutos.
    static final int MAXIMO_ERROS_ATIVACAO = 5;
    private static final Duration JANELA_ERROS_ATIVACAO = Duration.ofMinutes(15);
    private static final String MUITAS_TENTATIVAS_ATIVACAO =
            "Muitas tentativas com código errado. Aguarde 15 minutos e tente de novo.";

    public PacienteController(PacienteService pacienteService, Autorizacao autorizacao, LimitadorDeTentativas limitador) {
        this.pacienteService = pacienteService;
        this.autorizacao = autorizacao;
        this.limitador = limitador;
    }

    /**
     * Duas situações: o próprio paciente se cadastrando (sem login — precisa de
     * senha e nasce sem cuidador) ou um cuidador logado cadastrando um paciente
     * (fica vinculado a esse cuidador, qualquer que seja o cuidadorId enviado).
     */
    @PostMapping("/api/pacientes")
    @ResponseStatus(HttpStatus.CREATED)
    public PacienteRespostaDTO criar(@RequestBody PacienteCriacaoDTO dto) {
        UsuarioAutenticado usuario = autorizacao.usuarioAtual();
        Long cuidadorId = null;
        if (usuario == null) {
            if (dto.senha() == null || dto.senha().length() < 8) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A senha deve ter no mínimo 8 caracteres.");
            }
        } else if (usuario.ehCuidador()) {
            cuidadorId = usuario.id();
        } else {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Você já tem uma conta de paciente.");
        }
        return pacienteService.criar(new PacienteCriacaoDTO(
                dto.nome(), dto.email(), dto.senha(), dto.dataNascimento(), dto.sexo(), dto.enfermidade(),
                dto.telefone(), dto.endereco(), dto.observacoesClinicas(), cuidadorId));
    }

    @GetMapping("/api/pacientes/{id}")
    public PacienteRespostaDTO buscarPorId(@PathVariable Long id) {
        autorizacao.exigirAcessoAoPaciente(id);
        return pacienteService.buscarPorId(id);
    }

    @PutMapping("/api/pacientes/{id}")
    public PacienteRespostaDTO atualizar(@PathVariable Long id, @RequestBody PacienteAtualizacaoDTO dto) {
        autorizacao.exigirAcessoAoPaciente(id);
        return pacienteService.atualizar(id, dto);
    }

    @DeleteMapping("/api/pacientes/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void excluir(@PathVariable Long id) {
        // O cuidador vinculado ou o próprio paciente (direito de apagar os próprios dados).
        autorizacao.exigirAcessoAoPaciente(id);
        pacienteService.excluir(id);
    }

    @PutMapping("/api/pacientes/{id}/senha")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void alterarSenha(@PathVariable Long id, @RequestBody AlterarSenhaDTO dto) {
        autorizacao.exigirOProprioPaciente(id);
        pacienteService.alterarSenha(id, dto);
    }

    @PostMapping("/api/pacientes/definir-senha")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void definirSenha(@RequestBody DefinirSenhaDTO dto) {
        String chave = "ativacao:" + (dto.email() == null ? "" : dto.email().trim().toLowerCase(Locale.ROOT));
        limitador.exigirDisponivel(chave, MAXIMO_ERROS_ATIVACAO, JANELA_ERROS_ATIVACAO, MUITAS_TENTATIVAS_ATIVACAO);
        try {
            pacienteService.definirSenha(dto);
            limitador.limpar(chave);
        } catch (ResponseStatusException erro) {
            limitador.registrar(chave);
            throw erro;
        }
    }

    @GetMapping("/api/cuidadores/{cuidadorId}/pacientes")
    public List<PacienteRespostaDTO> listarPorCuidador(@PathVariable Long cuidadorId) {
        autorizacao.exigirOProprioCuidador(cuidadorId);
        return pacienteService.listarPorCuidador(cuidadorId);
    }

    @PostMapping("/api/pacientes/{id}/solicitar-vinculo")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void solicitarVinculo(@PathVariable Long id, @RequestBody SolicitarVinculoDTO dto) {
        autorizacao.exigirOProprioPaciente(id);
        pacienteService.solicitarVinculo(id, dto);
    }

    @GetMapping("/api/cuidadores/{cuidadorId}/solicitacoes")
    public List<PacienteRespostaDTO> listarSolicitacoes(@PathVariable Long cuidadorId) {
        autorizacao.exigirOProprioCuidador(cuidadorId);
        return pacienteService.listarSolicitacoes(cuidadorId);
    }

    // Nas ações abaixo, o cuidador é sempre o do token (o "cuidadorId" do corpo
    // é ignorado); o serviço confere se ele é mesmo o vinculado/solicitado.

    @PostMapping("/api/pacientes/{id}/aceitar-vinculo")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void aceitarVinculo(@PathVariable Long id) {
        pacienteService.aceitarVinculo(id, new AcaoVinculoDTO(autorizacao.exigirCuidador()));
    }

    @PostMapping("/api/pacientes/{id}/recusar-vinculo")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void recusarVinculo(@PathVariable Long id) {
        pacienteService.recusarVinculo(id, new AcaoVinculoDTO(autorizacao.exigirCuidador()));
    }

    @PostMapping("/api/pacientes/{id}/alerta-manual")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void enviarAlertaManual(@PathVariable Long id, @RequestBody EnviarAlertaManualDTO dto) {
        pacienteService.enviarAlertaManual(id, new EnviarAlertaManualDTO(autorizacao.exigirCuidador(), dto.mensagem()));
    }

    @PostMapping("/api/pacientes/{id}/alerta-manual/confirmar")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void confirmarAlertaManual(@PathVariable Long id) {
        autorizacao.exigirOProprioPaciente(id);
        pacienteService.confirmarAlertaManual(id);
    }

    @PostMapping("/api/pacientes/{id}/desvincular-cuidador")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void desvincularCuidador(@PathVariable Long id) {
        pacienteService.desvincularCuidador(id, new AcaoVinculoDTO(autorizacao.exigirCuidador()));
    }

    @PutMapping("/api/pacientes/{id}/permissao-alteracoes")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void atualizarPermissaoAlteracoes(@PathVariable Long id, @RequestBody AtualizarPermissaoDTO dto) {
        pacienteService.atualizarPermissaoAlteracoes(
                id, new AtualizarPermissaoDTO(autorizacao.exigirCuidador(), dto.permiteAlteracoes()));
    }
}
