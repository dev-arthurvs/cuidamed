import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../componentes/botao.dart';
import '../componentes/campo_texto.dart';
import '../componentes/layout_autenticacao.dart';
import '../estado/app_estado.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/tema.dart';

/// Equivalente a paginas/Login.jsx do web.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  bool _lembrar = false;
  String? _erro;

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final estado = context.read<AppEstado>();
    // Voltou para cá porque o token venceu: explica o motivo.
    _erro = estado.consumirAvisoSessao();
    // "Lembrar de mim" da última vez: e-mail ou telefone preenchido e caixa já marcada.
    estado.loginLembrado().then((login) {
      if (!mounted || login == null || login.isEmpty || _loginController.text.isNotEmpty) return;
      setState(() {
        _loginController.text = login;
        _lembrar = true;
      });
    });
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AppEstado>().entrar(_loginController.text.trim(), _senhaController.text, lembrar: _lembrar);
      if (mounted) context.go('/painel');
    } catch (erro) {
      setState(() => _erro = erro is ApiExcecao ? erro.mensagem : 'Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Mesmo formulário de "Ativar meu acesso", com o código de nova senha.
  void _esqueciSenha() => context.push('/definir-senha?novaSenha=1');

  @override
  Widget build(BuildContext context) {
    return LayoutAutenticacao(
      heroTitulo: 'O remédio certo, na hora certa, todos os dias.',
      heroSubtitulo: 'Agenda de medicamentos, com acompanhamento em tempo real por médicos e cuidadores.',
      cartao: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TituloAutenticacao(titulo: 'Entrar na minha conta'),
            const SizedBox(height: 22),
            CampoTexto(
              rotulo: 'E-mail ou telefone',
              icone: Icons.person_outline,
              fundoBranco: true,
              rotuloExterno: true,
              placeholder: 'seu@email.com ou (79) 99999-9999',
              controller: _loginController,
              // Teclado de e-mail (tem letras, números e @). O de telefone aplicaria a
              // máscara, e aqui a pessoa pode digitar qualquer um dos dois.
              tipoTeclado: TextInputType.emailAddress,
              validador: (valor) => (valor == null || valor.trim().isEmpty) ? 'Informe o e-mail ou telefone.' : null,
            ),
            const SizedBox(height: 18),
            CampoTexto(
              rotulo: 'Senha',
              icone: Icons.lock_outline,
              fundoBranco: true,
              alternarSenha: true,
              rotuloExterno: true,
              placeholder: '••••••••',
              controller: _senhaController,
              senha: true,
              onSubmitted: (_) => _entrar(),
              validador: (valor) => (valor == null || valor.isEmpty) ? 'Informe a senha.' : null,
            ),
            const SizedBox(height: 4),
            // "Lembrar de mim" à esquerda e "Esqueci minha senha" à direita, como
            // no web; em tela muito estreita um fica embaixo do outro.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _lembrar = !_lembrar),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _lembrar,
                        onChanged: (valor) => setState(() => _lembrar = valor ?? false),
                        activeColor: CorApp.azulSolido,
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        'Lembrar de mim',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CorApp.textoLabel),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
                // Direto o link (o LinkEsqueciSenha se estica na linha toda).
                LinkAutenticacao(texto: 'Esqueci minha senha', peso: FontWeight.w600, onTap: _esqueciSenha),
              ],
            ),
            if (_erro != null) ...[
              const SizedBox(height: 14),
              Text(_erro!, style: TextStyle(color: CorApp.vermelho, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 16),
            Botao(texto: 'Entrar', variante: VarianteBotao.solido, onPressed: _entrar, carregando: _carregando),
            const SizedBox(height: 22),
            BotoesAlternativosAutenticacao(
              opcoes: [
                (texto: 'Criar conta', onTap: () => context.push('/cadastro')),
                (texto: 'Ativar acesso', onTap: () => context.push('/definir-senha')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
