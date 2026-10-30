import 'package:flutter/material.dart';

import '../utilitarios/animacoes.dart';
import '../utilitarios/tema.dart';
import 'cabecalho.dart';

/// Moldura das telas de Login, Cadastro e Ativar acesso — equivalente ao
/// `.autenticacao` do web (estilos/autenticacao.css):
/// - o gradiente azul escuro ocupa a tela inteira;
/// - tela larga: marca (logo, frase, rodapé) à esquerda e o card branco do
///   formulário "flutuando" à direita; só o formulário rola;
/// - celular: logo grande centralizada no topo e o card logo abaixo.
class LayoutAutenticacao extends StatelessWidget {
  final String heroTitulo;
  final String heroSubtitulo;
  final String rodape;
  final Widget cartao;

  /// Largura a partir da qual a marca fica ao lado do formulário (igual ao web).
  static const larguraDividida = 900.0;

  const LayoutAutenticacao({
    super.key,
    required this.heroTitulo,
    required this.heroSubtitulo,
    required this.cartao,
    this.rodape = '© 2026 CuidaMed',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CorApp.azulEscuro,
      // expand: o fundo cobre a tela toda, mesmo quando o conteúdo é mais baixo.
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _FundoAutenticacao()),
          LayoutBuilder(
            builder: (context, restricoes) =>
                restricoes.maxWidth >= larguraDividida ? _telaLarga(restricoes) : _telaEstreita(context),
          ),
        ],
      ),
    );
  }

  Widget _textoHero() {
    // Troca com fade quando a frase muda (ex.: Paciente ↔ Cuidador no cadastro).
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: transicaoTrocaSuave(),
      layoutBuilder: (atual, anteriores) => Stack(alignment: Alignment.topLeft, children: [...anteriores, ?atual]),
      child: ConstrainedBox(
        key: ValueKey(heroTitulo),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              heroTitulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              heroSubtitulo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 17,
                fontWeight: FontWeight.w400,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoFlutuante({required EdgeInsets padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: CorApp.fundoCard,
        borderRadius: BorderRadius.circular(22),
        // Sombra longa e escura: o card parece sair do fundo azul.
        boxShadow: const [
          BoxShadow(color: Color(0x7303102A), blurRadius: 70, offset: Offset(0, 32)),
          BoxShadow(color: Color(0x2E03102A), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      // Entrada da tela igual ao web (opacity 0 → 1, subindo 10 px em 0,25 s).
      child: EntradaSuave(
        deslocamento: 10,
        escalaInicial: 1,
        duracao: const Duration(milliseconds: 250),
        child: cartao,
      ),
    );
  }

  Widget _textoRodape() => Text(
        rodape,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
      );

  Widget _telaLarga(BoxConstraints restricoes) {
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LogoCuidaMed(tamanho: 84, tamanhoTexto: 48, claro: true),
                  _textoHero(),
                  _textoRodape(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _cartaoFlutuante(padding: const EdgeInsets.fromLTRB(40, 40, 40, 32)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _telaEstreita(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 36, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encolhe proporcionalmente em telas muito estreitas, sem cortar.
                const Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: LogoCuidaMed(tamanho: 72, tamanhoTexto: 42, claro: true),
                  ),
                ),
                const SizedBox(height: 28),
                _cartaoFlutuante(padding: const EdgeInsets.fromLTRB(22, 28, 22, 24)),
                const SizedBox(height: 24),
                Center(child: _textoRodape()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradiente azul escuro da tela inteira, com duas luzes suaves que dão
/// profundidade (mesmos radial-gradients do web).
class _FundoAutenticacao extends StatelessWidget {
  const _FundoAutenticacao();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: CorApp.gradienteAutenticacao),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.76, -0.64),
                radius: 0.85,
                colors: [Color(0x524AA8F0), Color(0x004AA8F0)],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.76, 0.84),
                radius: 0.95,
                colors: [Color(0x8C041634), Color(0x00041634)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título do card ("Entrar na minha conta", "Criar cadastro"...).
class TituloAutenticacao extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  const TituloAutenticacao({super.key, required this.titulo, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: CorApp.texto),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitulo!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: CorApp.textoSuave),
          ),
        ],
      ],
    );
  }
}

/// Link em azul e negrito ("Cadastre-se", "Ativar meu acesso", "Entrar").
class LinkAutenticacao extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  final FontWeight peso;
  final double tamanhoFonte;
  const LinkAutenticacao({
    super.key,
    required this.texto,
    required this.onTap,
    this.peso = FontWeight.w700,
    this.tamanhoFonte = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Text(texto, style: TextStyle(color: CorApp.azul, fontSize: tamanhoFonte, fontWeight: peso)),
        ),
      ),
    );
  }
}

/// "Esqueci minha senha": discreto, alinhado à direita logo abaixo da senha.
class LinkEsqueciSenha extends StatelessWidget {
  final VoidCallback onTap;
  const LinkEsqueciSenha({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: LinkAutenticacao(texto: 'Esqueci minha senha', peso: FontWeight.w600, onTap: onTap),
    );
  }
}

/// "Pergunta? Link" numa linha centralizada que quebra se faltar espaço.
class LinhaConvite extends StatelessWidget {
  final String pergunta;
  final String link;
  final VoidCallback onTap;
  const LinhaConvite({super.key, required this.pergunta, required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(pergunta, style: const TextStyle(color: CorApp.textoSuave, fontSize: 16, fontWeight: FontWeight.w500)),
        LinkAutenticacao(texto: link, onTap: onTap),
      ],
    );
  }
}

/// Rodapé do card: linha divisória e os outros caminhos (cadastro, ativação,
/// voltar ao login), um por linha e centralizados — como no web.
class RodapeLinksAutenticacao extends StatelessWidget {
  final List<LinhaConvite> linhas;
  const RodapeLinksAutenticacao({super.key, required this.linhas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: CorApp.borda),
        const SizedBox(height: 14),
        for (final linha in linhas) Center(child: linha),
      ],
    );
  }
}
