import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../componentes/botao.dart';
import '../componentes/campo_texto.dart';
import '../componentes/layout_autenticacao.dart';
import '../servicos/api_cliente.dart';
import '../utilitarios/tema.dart';

/// "Ativar meu acesso" — pro paciente que já foi cadastrado pelo cuidador e
/// precisa criar a própria senha pela primeira vez (não é reset de senha
/// tradicional). Espelha front-end cuidamed/src/paginas/DefinirSenha.jsx.
class DefinirSenha extends StatefulWidget {
  const DefinirSenha({super.key});

  @override
  State<DefinirSenha> createState() => _DefinirSenhaState();
}

class _DefinirSenhaState extends State<DefinirSenha> {
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _ativarAcesso() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o e-mail cadastrado pelo seu cuidador.');
      return;
    }
    if (_codigoController.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o código de ativação que seu cuidador passou.');
      return;
    }
    if (_novaSenhaController.text.length < 8) {
      setState(() => _erro = 'A senha deve ter no mínimo 8 caracteres.');
      return;
    }
    if (_novaSenhaController.text != _confirmarController.text) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await ApiCliente.instancia.post('/api/pacientes/definir-senha', {
        'email': _emailController.text.trim(),
        'codigo': _codigoController.text.trim().toUpperCase(),
        'novaSenha': _novaSenhaController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Acesso ativado! Faça login com sua nova senha.')));
        context.go('/login');
      }
    } catch (erro) {
      setState(() => _erro = erro is ApiExcecao ? erro.mensagem : 'Não foi possível ativar o acesso.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutAutenticacao(
      soLogoNoCelular: true, // igual ao login: no celular, só a logo no painel azul
      heroTitulo: 'Seu cuidador já cadastrou você.',
      heroSubtitulo: 'Agora é só criar uma senha para acessar sua própria agenda de medicamentos.',
      cartao: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: LinkAutenticacao(
              texto: '‹ Voltar para entrar',
              destaque: false,
              tamanhoFonte: 14,
              onTap: () => context.go('/login'),
            ),
          ),
          const SizedBox(height: 10),
          const TituloAutenticacao(titulo: 'Ativar meu acesso'),
          const SizedBox(height: 22),
          CampoTexto(
            rotulo: 'E-mail cadastrado',
            rotuloExterno: true,
            placeholder: 'seu@email.com',
            controller: _emailController,
            tipoTeclado: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          CampoTexto(
            rotulo: 'Código de ativação',
            rotuloExterno: true,
            placeholder: 'Código que seu cuidador passou',
            controller: _codigoController,
          ),
          const SizedBox(height: 18),
          CampoTexto(
            rotulo: 'Criar senha',
            rotuloExterno: true,
            controller: _novaSenhaController,
            senha: true,
            placeholder: 'Mínimo 8 caracteres',
          ),
          const SizedBox(height: 18),
          CampoTexto(
            rotulo: 'Confirmar senha',
            rotuloExterno: true,
            controller: _confirmarController,
            senha: true,
            placeholder: 'Repita a senha',
            onSubmitted: (_) => _ativarAcesso(),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 14),
            Text(_erro!, style: const TextStyle(color: CorApp.vermelho, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 22),
          Botao(texto: 'Ativar acesso', onPressed: _ativarAcesso, carregando: _carregando),
          const SizedBox(height: 16),
          // Como no login: só "Cadastre-se", centralizado e com fonte menor.
          Center(
            child: LinkAutenticacao(texto: 'Cadastre-se', tamanhoFonte: 14, onTap: () => context.go('/cadastro')),
          ),
        ],
      ),
    );
  }
}
