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
  static const double _fonteLinks = 14;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Voltou para cá porque o token venceu: explica o motivo.
    _erro = context.read<AppEstado>().consumirAvisoSessao();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AppEstado>().entrar(_emailController.text.trim(), _senhaController.text);
      if (mounted) context.go('/painel');
    } catch (erro) {
      setState(() => _erro = erro is ApiExcecao ? erro.mensagem : 'Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _esqueciSenha() {
    // Mesmo comportamento do web: recuperação de senha ainda é simulada.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Enviamos as instruções de recuperação para o seu e-mail (simulação).')));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutAutenticacao(
      soLogoNoCelular: true,
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
              rotulo: 'E-mail',
              rotuloExterno: true,
              placeholder: 'seu@email.com',
              controller: _emailController,
              tipoTeclado: TextInputType.emailAddress,
              validador: (valor) => (valor == null || valor.trim().isEmpty) ? 'Informe o e-mail.' : null,
            ),
            const SizedBox(height: 18),
            CampoTexto(
              rotulo: 'Senha',
              rotuloExterno: true,
              placeholder: '••••••••',
              controller: _senhaController,
              senha: true,
              onSubmitted: (_) => _entrar(),
              validador: (valor) => (valor == null || valor.isEmpty) ? 'Informe a senha.' : null,
            ),
            if (_erro != null) ...[
              const SizedBox(height: 14),
              Text(_erro!, style: const TextStyle(color: CorApp.vermelho, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 22),
            Botao(texto: 'Entrar', onPressed: _entrar, carregando: _carregando),
            const SizedBox(height: 18),
            // Links centralizados, um abaixo do outro, com texto um pouco menor.
            Column(
              children: [
                LinkAutenticacao(
                  texto: 'Esqueci minha senha',
                  destaque: false,
                  tamanhoFonte: _fonteLinks,
                  onTap: _esqueciSenha,
                ),
                LinkAutenticacao(texto: 'Cadastre-se', tamanhoFonte: _fonteLinks, onTap: () => context.push('/cadastro')),
                LinhaConvite(
                  pergunta: 'Cadastrado pelo seu cuidador?',
                  link: 'Ativar meu acesso',
                  tamanhoFonte: _fonteLinks,
                  alinhamento: WrapAlignment.center,
                  onTap: () => context.push('/definir-senha'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
