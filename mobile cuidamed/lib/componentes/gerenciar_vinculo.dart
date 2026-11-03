import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';
import '../modelos/paciente.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/tema.dart';
import 'botao.dart';
import 'cartao.dart';
import 'confirmacao.dart';

/// Parte final dos detalhes do paciente (só o cuidador vê), como em
/// GerenciarVinculo.jsx do web: permissão para o paciente alterar a própria
/// agenda e o desvínculo. Antes era uma tela à parte.
class GerenciarVinculo extends StatefulWidget {
  final Paciente paciente;
  const GerenciarVinculo({super.key, required this.paciente});

  @override
  State<GerenciarVinculo> createState() => _GerenciarVinculoState();
}

class _GerenciarVinculoState extends State<GerenciarVinculo> {
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
      await context.read<AppEstado>().atualizarPermissaoAlteracoes(widget.paciente.id, permite);
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
    final roteador = GoRouter.of(context);
    try {
      await context.read<AppEstado>().desvincularPaciente(widget.paciente.id);
      if (!mounted) return;
      _avisar('$nome foi desvinculado(a) da sua conta.');
      roteador.go('/painel');
    } catch (erro) {
      _avisar(erro is ApiExcecao ? erro.mensagem : 'Não foi possível desvincular o paciente.');
      if (mounted) setState(() => _desvinculando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paciente = widget.paciente;
    final primeiroNome = paciente.nome.split(' ').first;
    final semLoginProprio = paciente.email.trim().isEmpty && (paciente.telefone ?? '').trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Cartao(
          titulo: 'Permite alterações',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Quando ativado, $primeiroNome pode adicionar, editar e excluir medicamentos na própria agenda. '
                  'Quando desativado, apenas você pode fazer essas alterações.',
                  style: TextStyle(color: CorApp.textoSuave, height: 1.4),
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
                    style: TextStyle(color: CorApp.textoSuave, height: 1.4),
                    children: [
                      TextSpan(
                        text: 'Ao desvincular, você deixa de acompanhar ${paciente.nome} e ele(a) some da sua lista de '
                            'pacientes. Essa ação só pode ser feita por você, o cuidador.',
                      ),
                      if (semLoginProprio) ...[
                        TextSpan(text: ' Atenção: ', style: TextStyle(fontWeight: FontWeight.w700, color: CorApp.vermelhoTexto)),
                        const TextSpan(
                          text: 'esse paciente não tem e-mail, telefone ou senha próprios cadastrados — ao desvincular, ele(a) ficará '
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
    );
  }
}
