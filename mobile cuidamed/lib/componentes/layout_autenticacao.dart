import 'package:flutter/material.dart';

import '../utilitarios/animacoes.dart';
import '../utilitarios/tema.dart';
import 'cabecalho.dart';

/// Moldura das telas de Login, Cadastro e Ativar acesso — equivalente ao
/// `.autenticacao` do web (estilos/autenticacao.css):
/// - tela larga: painel com gradiente azul à esquerda (logo, frase de impacto,
///   rodapé) e o card do formulário centralizado à direita;
/// - celular: o painel azul vira um cabeçalho no topo (só logo + frase, sem o
///   subtítulo, pra não pesar a tela) e o card branco sobe por cima dele.
class LayoutAutenticacao extends StatelessWidget {
  final String heroTitulo;
  final String heroSubtitulo;
  final String rodape;
  final Widget cartao;

  /// No celular, mostra só a logo (maior e centralizada) no painel azul, sem a
  /// frase — deixa a tela inicial mais limpa. Na tela larga nada muda.
  final bool soLogoNoCelular;

  /// Largura a partir da qual o painel azul fica ao lado do formulário.
  static const larguraDividida = 900.0;

  const LayoutAutenticacao({
    super.key,
    required this.heroTitulo,
    required this.heroSubtitulo,
    required this.cartao,
    this.rodape = '© 2026 CuidaMed',
    this.soLogoNoCelular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CorApp.fundo,
      body: LayoutBuilder(
        builder: (context, restricoes) =>
            restricoes.maxWidth >= larguraDividida ? _telaLarga(context, restricoes) : _telaEstreita(context),
      ),
    );
  }

  Widget _textoHero({required double tamanhoTitulo, required double tamanhoSubtitulo, bool comSubtitulo = true}) {
    // Troca com fade quando a frase muda (ex.: Paciente ↔ Cuidador no cadastro).
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: transicaoTrocaSuave(),
      layoutBuilder: (atual, anteriores) => Stack(alignment: Alignment.topLeft, children: [...anteriores, ?atual]),
      child: Column(
        key: ValueKey(heroTitulo),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            heroTitulo,
            style: TextStyle(
              color: Colors.white,
              fontSize: tamanhoTitulo,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.6,
            ),
          ),
          if (comSubtitulo) ...[
            SizedBox(height: tamanhoSubtitulo * 0.8),
            Text(
              heroSubtitulo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: tamanhoSubtitulo,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cartaoDecorado({required EdgeInsets padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: CorApp.fundoCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: CorApp.borda),
        boxShadow: const [BoxShadow(color: Color(0x14133A6E), blurRadius: 40, offset: Offset(0, 18))],
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

  Widget _telaLarga(BuildContext context, BoxConstraints restricoes) {
    final larguraHero = (restricoes.maxWidth * 0.42).clamp(420.0, 620.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: larguraHero,
          decoration: const BoxDecoration(gradient: CorApp.gradienteHero),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 56),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const LogoCuidaMed(tamanho: 68, tamanhoTexto: 38, claro: true),
                _textoHero(tamanhoTitulo: 42, tamanhoSubtitulo: 20),
                Text(
                  rodape,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _cartaoDecorado(padding: const EdgeInsets.all(40)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _telaEstreita(BuildContext context) {
    final topoSeguro = MediaQuery.of(context).padding.top;
    const sobreposicao = 44.0; // quanto o card sobe por cima do painel azul
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: CorApp.gradienteHero,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: EdgeInsets.fromLTRB(24, topoSeguro + 28, 24, 28 + sobreposicao),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: soLogoNoCelular
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        // Encolhe proporcionalmente em telas muito estreitas, sem cortar.
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: LogoCuidaMed(tamanho: 64, tamanhoTexto: 38, claro: true),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LogoCuidaMed(tamanho: 46, tamanhoTexto: 28, claro: true),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            child: _textoHero(tamanhoTitulo: 27, tamanhoSubtitulo: 16, comSubtitulo: false),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -sobreposicao),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _cartaoDecorado(padding: const EdgeInsets.fromLTRB(22, 26, 22, 26)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              rodape,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CorApp.textoSuave, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título + subtítulo do card ("Entrar na minha conta" / "Use o e-mail...").
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
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: CorApp.texto),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitulo!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CorApp.textoSuave),
          ),
        ],
      ],
    );
  }
}

/// Link em negrito sublinhado ("Cadastre-se", "Ativar meu acesso"), como no web.
class LinkAutenticacao extends StatelessWidget {
  final String texto;
  final VoidCallback onTap;
  final bool destaque;
  final double tamanhoFonte;
  const LinkAutenticacao({
    super.key,
    required this.texto,
    required this.onTap,
    this.destaque = true,
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
          child: Text(
            texto,
            style: TextStyle(
              color: CorApp.azul,
              fontSize: tamanhoFonte,
              fontWeight: destaque ? FontWeight.w800 : FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: CorApp.azul,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Pergunta? Link" numa linha que quebra se faltar espaço.
class LinhaConvite extends StatelessWidget {
  final String pergunta;
  final String link;
  final VoidCallback onTap;
  final double tamanhoFonte;
  final WrapAlignment alinhamento;
  const LinhaConvite({
    super.key,
    required this.pergunta,
    required this.link,
    required this.onTap,
    this.tamanhoFonte = 16,
    this.alinhamento = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alinhamento,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          pergunta,
          style: TextStyle(color: CorApp.textoSuave, fontSize: tamanhoFonte, fontWeight: FontWeight.w600),
        ),
        LinkAutenticacao(texto: link, onTap: onTap, tamanhoFonte: tamanhoFonte),
      ],
    );
  }
}
