import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/botao.dart';
import '../componentes/botao_whatsapp.dart';
import '../componentes/cabecalho.dart';
import '../componentes/cartao.dart';
import '../componentes/cartao_observacoes.dart';
import '../componentes/rotulo_status.dart';
import '../estado/app_estado.dart';
import '../servicos/api_cliente.dart';
import '../servicos/paciente_servico.dart';
import '../utilitarios/horarios.dart';
import '../componentes/data_hora_atual.dart';
import '../utilitarios/tema.dart';

class DetalhePaciente extends StatefulWidget {
  final int pacienteId;
  const DetalhePaciente({super.key, required this.pacienteId});

  @override
  State<DetalhePaciente> createState() => _DetalhePacienteState();
}

class _DetalhePacienteState extends State<DetalhePaciente> {
  final PacienteServico _pacienteServico = PacienteServico();
  bool _enviandoAlerta = false;

  Future<void> _lembrarAgora(AppEstado estado) async {
    setState(() => _enviandoAlerta = true);
    try {
      await _pacienteServico.enviarAlertaManual(widget.pacienteId, estado.usuario!.id, null);
      if (mounted) {
        final nome = estado.pacienteFoco?.paciente.nome ?? '';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lembrete enviado para $nome.')));
      }
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro is ApiExcecao ? erro.mensagem : 'Não foi possível enviar o lembrete.')));
      }
    } finally {
      if (mounted) setState(() => _enviandoAlerta = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    if (estado.pacienteFocoId != widget.pacienteId) {
      // Garante que o restante do app (Agenda, Histórico, WhatsApp...) veja
      // este paciente como o "em foco" ao navegar direto pra essa rota.
      WidgetsBinding.instance.addPostFrameCallback((_) => estado.selecionarPaciente(widget.pacienteId));
    }
    final dados = estado.pacienteFoco;

    if (dados == null) {
      return const AndaimeApp(appBar: Cabecalho(kicker: 'Detalhes', titulo: 'Carregando...'), body: Center(child: CircularProgressIndicator()));
    }

    final doses = construirDosesHoje(dados.medicamentosAtivos(), dados.historicoHoje())..sort((a, b) => a.horario.compareTo(b.horario));
    final adesao = calcularAdesao(dados.historico);

    return AndaimeApp(
      appBar: Cabecalho(kicker: 'Detalhes do paciente', titulo: dados.paciente.nome),
      body: RefreshIndicator(
        onRefresh: () => estado.recarregarPaciente(widget.pacienteId),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Cartao(
              child: Row(
                children: [
                  AvatarUsuario(nome: dados.paciente.nome, tamanho: 52, descricao: 'Paciente: ${dados.paciente.nome}'),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dados.paciente.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        Text('${dados.medicamentosAtivos().length} medicamentos', style: const TextStyle(color: CorApp.textoSuave)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$adesao%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: CorApp.azulTexto)),
                      const Text('adesão 30 dias', style: TextStyle(fontSize: 11, color: CorApp.textoSuave)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Cartao(
              titulo: 'Doses de hoje',
              child: doses.isEmpty
                  ? const Text('Nenhuma dose agendada para hoje.', style: TextStyle(color: CorApp.textoSuave))
                  : Column(
                      children: doses
                          .map((dose) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    SizedBox(width: 56, child: Text(dose.horario, style: const TextStyle(fontWeight: FontWeight.w800))),
                                    Expanded(child: Text(dose.nome, style: const TextStyle(fontWeight: FontWeight.w700))),
                                    RotuloStatus(status: dose.status),
                                    const SizedBox(width: 8),
                                    BotaoWhatsApp(
                                      nomePaciente: dados.paciente.nome,
                                      telefone: dados.paciente.telefone,
                                      medicamento: dose.nome,
                                      dosagem: dose.dosagem,
                                      forma: dose.forma,
                                      quantidadePorDose: dose.quantidadePorDose,
                                      dataFim: dose.dataFim,
                                      horario: dose.horario,
                                      status: dose.status,
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 20),
            Botao(texto: _enviandoAlerta ? 'Enviando...' : 'Lembrar agora 🔔', onPressed: () => _lembrarAgora(estado), carregando: _enviandoAlerta),
            const SizedBox(height: 12),
            Botao(
              texto: 'Ver histórico completo',
              variante: VarianteBotao.secundario,
              onPressed: () => context.push('/historico/${widget.pacienteId}'),
            ),
            const SizedBox(height: 12),
            Botao(texto: 'Acessar agenda', variante: VarianteBotao.secundario, onPressed: () => context.push('/agenda')),
            const SizedBox(height: 12),
            Botao(texto: 'Ver ciclos encerrados', variante: VarianteBotao.contorno, onPressed: () => context.push('/ciclos-encerrados')),
            const SizedBox(height: 12),
            Botao(
              texto: 'Painel do paciente ⚙️',
              variante: VarianteBotao.contorno,
              onPressed: () => context.push('/cuidador/paciente/${widget.pacienteId}/painel'),
            ),
            if (dados.paciente.codigoAtivacao != null) ...[
              const SizedBox(height: 20),
              // Paciente cadastrado pelo cuidador que ainda não criou a senha.
              Cartao(
                titulo: 'Acesso do paciente',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ainda não ativou o acesso ao app. Passe este código para usar em "Ativar meu acesso", junto com o e-mail cadastrado.',
                      style: TextStyle(color: CorApp.textoSuave, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: CorApp.fundoDestaque,
                        borderRadius: BorderRadius.circular(RaioApp.pequeno),
                        border: Border.all(color: CorApp.bordaDestaque, width: 1.5),
                      ),
                      child: SelectableText(
                        dados.paciente.codigoAtivacao!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 6, color: CorApp.azulTexto),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            CartaoObservacoes(paciente: dados.paciente),
          ],
        ),
      ),
    );
  }
}
