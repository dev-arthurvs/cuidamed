import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estado/app_estado.dart';
import '../modelos/paciente.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/tema.dart';
import 'botao.dart';
import 'cartao.dart';

/// Detalhes do paciente, como em AcessoPaciente.jsx do web: código para ativar
/// o acesso ou, se ele esqueceu a senha, botão para o cuidador gerar um código
/// de nova senha (vale 24 horas).
class AcessoPaciente extends StatefulWidget {
  final Paciente paciente;
  const AcessoPaciente({super.key, required this.paciente});

  @override
  State<AcessoPaciente> createState() => _AcessoPacienteState();
}

class _AcessoPacienteState extends State<AcessoPaciente> {
  bool _gerando = false;

  Future<void> _gerar() async {
    setState(() => _gerando = true);
    try {
      await context.read<AppEstado>().gerarCodigoNovaSenha(widget.paciente.id);
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro is ApiExcecao ? erro.mensagem : 'Não foi possível gerar o código.')),
        );
      }
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codigo = widget.paciente.codigoAtivacao;
    final texto = codigo == null
        ? 'O paciente esqueceu a senha? Gere um código para ele criar uma nova.'
        : widget.paciente.codigoNovaSenha
            ? 'Passe este código ao paciente. Ele toca em "Esqueci minha senha", informa o e-mail ou telefone e cria a senha nova. Vale por 24 horas.'
            : 'Ainda não ativou o acesso ao app. Passe este código para usar em "Ativar meu acesso", junto com o e-mail ou telefone cadastrado.';
    return Cartao(
      titulo: 'Acesso do paciente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(texto, style: TextStyle(color: CorApp.textoSuave, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (codigo == null)
            Botao(
              texto: 'Gerar código de nova senha',
              variante: VarianteBotao.secundario,
              carregando: _gerando,
              onPressed: _gerar,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: CorApp.fundoDestaque,
                borderRadius: BorderRadius.circular(RaioApp.pequeno),
                border: Border.all(color: CorApp.bordaDestaque, width: 1.5),
              ),
              child: SelectableText(
                codigo,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 6, color: CorApp.azulTexto),
              ),
            ),
        ],
      ),
    );
  }
}
