import 'package:flutter/material.dart';

import '../estado/monitor_alertas.dart';
import '../servicos/notificacao_servico.dart';
import '../utilitarios/tema.dart';
import 'botao.dart';

/// ScaffoldMessenger do app inteiro: o alerta aparece em qualquer tela em que
/// o paciente esteja (equivalente ao toast global do web).
final chaveMensageiroGlobal = GlobalKey<ScaffoldMessengerState>();

/// Aviso na tela + som + notificação do sistema — o mesmo trio do web.
void dispararAlerta(AlertaPaciente alerta, {NotificacaoServico? servico}) {
  final notificacoes = servico ?? NotificacaoServico.instancia;
  mostrarAlertaNaTela(alerta);
  notificacoes.tocarAlerta();
  notificacoes.notificar(alerta.titulo, alerta.mensagem);
}

void mostrarAlertaNaTela(AlertaPaciente alerta) {
  final mensageiro = chaveMensageiroGlobal.currentState;
  if (mensageiro == null) return;
  mensageiro
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 12),
        backgroundColor: CorApp.azulEscuro,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RaioApp.medio)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(alerta.titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(alerta.mensagem, style: const TextStyle(fontSize: 15, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
}

/// Faixa "Ative os lembretes sonoros e notificações" do painel do paciente
/// (igual à do web). Some depois que o usuário responde ao pedido.
class FaixaAtivarNotificacoes extends StatefulWidget {
  final NotificacaoServico? servico;
  const FaixaAtivarNotificacoes({super.key, this.servico});

  @override
  State<FaixaAtivarNotificacoes> createState() => _FaixaAtivarNotificacoesState();
}

class _FaixaAtivarNotificacoesState extends State<FaixaAtivarNotificacoes> {
  late final NotificacaoServico _servico = widget.servico ?? NotificacaoServico.instancia;
  PermissaoNotificacao? _permissao;

  @override
  void initState() {
    super.initState();
    _servico.permissao().then((p) {
      if (mounted) setState(() => _permissao = p);
    });
  }

  Future<void> _ativar() async {
    final resultado = await _servico.pedirPermissao();
    if (mounted) setState(() => _permissao = resultado);
  }

  @override
  Widget build(BuildContext context) {
    if (_permissao != PermissaoNotificacao.naoPerguntada) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: CorApp.azulFundo,
        borderRadius: BorderRadius.circular(RaioApp.grande),
        border: Border.all(color: CorApp.bordaDestaque, width: 1.5),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        spacing: 16,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ative os lembretes sonoros e notificações',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: CorApp.texto)),
                SizedBox(height: 4),
                Text(
                  'Receba um aviso no dispositivo e um som quando for a hora de tomar um remédio.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: CorApp.textoSuave),
                ),
              ],
            ),
          ),
          Botao(texto: 'Ativar', compacto: true, larguraTotal: false, onPressed: _ativar),
        ],
      ),
    );
  }
}
