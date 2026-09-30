import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../componentes/andaime_app.dart';
import '../componentes/botao.dart';
import '../componentes/cabecalho.dart';
import '../componentes/confirmacao.dart';
import '../componentes/cartao.dart';
import '../componentes/voltar_detalhes_paciente.dart';
import '../estado/app_estado.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/tema.dart';

/// Equivalente a paginas/PainelPaciente.jsx: configurações do vínculo que só
/// o cuidador controla — permissão de o paciente alterar a própria agenda e
/// desvincular o paciente.
class PainelPaciente extends StatefulWidget {
  final int pacienteId;
  const PainelPaciente({super.key, required this.pacienteId});

  @override
  State<PainelPaciente> createState() => _PainelPacienteState();
}

class _PainelPacienteState extends State<PainelPaciente> {
  bool _alterandoPermissao = false;
  bool _desvinculando = false;

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _alternarPermissao(bool permite) async {
    setState(() => _alterandoPermissao = true);
    try {
      await context.read<AppEstado>().atualizarPermissaoAlteracoes(widget.pacienteId, permite);
      _avisar(permite ? 'Paciente agora pode alterar a própria agenda.' : 'Alterações da agenda bloqueadas para o paciente.');
    } catch (erro) {
      _avisar(erro is ApiExcecao ? erro.mensagem : 'Não foi possível atualizar a permissão.');
    } finally {
      if (mounted) setState(() => _alterandoPermissao = false);
    }
  }

  Future<void> _confirmarDesvinculo(String nome, bool semLoginProprio) async {
    final confirmado = await confirmarAcao(
      context,
      titulo: 'Desvincular paciente?',
      mensagem: 'Tem certeza que deseja desvincular $nome da sua conta?'
          '${semLoginProprio ? ' Esse paciente ficará sem nenhum cuidador responsável.' : ''}',
      textoConfirmar: 'Sim, desvincular',
    );
    if (confirmado != true || !mounted) return;

    setState(() => _desvinculando = true);
    try {
      await context.read<AppEstado>().desvincularPaciente(widget.pacienteId);
      if (!mounted) return;
      _avisar('$nome foi desvinculado(a) da sua conta.');
      context.go('/painel');
    } catch (erro) {
      _avisar(erro is ApiExcecao ? erro.mensagem : 'Não foi possível desvincular o paciente.');
      if (mounted) setState(() => _desvinculando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppEstado>();
    final encontrados = estado.pacientes.where((p) => p.paciente.id == widget.pacienteId);
    if (encontrados.isEmpty) {
      return const AndaimeApp(
        appBar: Cabecalho(kicker: 'Painel do paciente', titulo: 'Paciente não encontrado'),
        body: Padding(padding: EdgeInsets.all(20), child: Text('Esse paciente não está mais vinculado à sua conta.')),
      );
    }
    final paciente = encontrados.first.paciente;
    final primeiroNome = paciente.nome.split(' ').first;
    final semLoginProprio = paciente.email.trim().isEmpty;

    return AndaimeApp(
      appBar: Cabecalho(kicker: 'Painel do paciente', titulo: paciente.nome),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          VoltarDetalhesPaciente(pacienteId: widget.pacienteId),
          Cartao(
            titulo: 'Permite alterações',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Quando ativado, $primeiroNome pode adicionar, editar e excluir medicamentos na própria agenda. '
                    'Quando desativado, apenas você pode fazer essas alterações.',
                    style: const TextStyle(color: CorApp.textoSuave, height: 1.4),
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: paciente.permiteAlteracoes,
                  activeTrackColor: CorApp.azul,
                  onChanged: _alterandoPermissao ? null : _alternarPermissao,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RaioApp.medio),
              border: Border.all(color: CorApp.vermelho.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Cartao(
              titulo: 'Desvincular paciente',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(color: CorApp.textoSuave, height: 1.4),
                      children: [
                        TextSpan(
                          text: 'Ao desvincular, você deixa de acompanhar ${paciente.nome} e ele(a) some da sua lista de '
                              'pacientes. Essa ação só pode ser feita por você, o cuidador.',
                        ),
                        if (semLoginProprio) ...[
                          const TextSpan(text: ' Atenção: ', style: TextStyle(fontWeight: FontWeight.w800, color: CorApp.vermelhoTexto)),
                          const TextSpan(
                            text: 'esse paciente não tem e-mail/senha próprios cadastrados — ao desvincular, ele(a) ficará '
                                'sem nenhum cuidador responsável e sem forma de acessar o sistema, até que outro cuidador o '
                                'cadastre novamente.',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Botao(
                    texto: 'Desvincular paciente',
                    variante: VarianteBotao.perigo,
                    carregando: _desvinculando,
                    onPressed: () => _confirmarDesvinculo(paciente.nome, semLoginProprio),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
