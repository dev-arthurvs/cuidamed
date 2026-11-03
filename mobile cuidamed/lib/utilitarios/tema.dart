import 'package:flutter/material.dart';

import 'animacoes.dart';

/// Tons que mudam entre o modo claro e o escuro — os mesmos valores das
/// variáveis do web (front-end cuidamed/src/estilos/global.css, `:root` e
/// `:root[data-tema='escuro']`).
class PaletaCores {
  final Color azulClaro, azul, azulSolido, azulEscuro, azulTexto, azulFundo;
  final Color fundo, fundoDestaque, fundoCard, fundoSuave;
  final Color texto, textoSuave, textoLabel;
  final Color borda, bordaInput, bordaDestaque;
  final Color verdeFundo, verdeTexto, verde;
  final Color amareloFundo, amareloTexto, amarelo;
  final Color vermelhoFundo, vermelhoTexto, vermelho;

  const PaletaCores({
    required this.azulClaro,
    required this.azul,
    required this.azulSolido,
    required this.azulEscuro,
    required this.azulTexto,
    required this.azulFundo,
    required this.fundo,
    required this.fundoDestaque,
    required this.fundoCard,
    required this.fundoSuave,
    required this.texto,
    required this.textoSuave,
    required this.textoLabel,
    required this.borda,
    required this.bordaInput,
    required this.bordaDestaque,
    required this.verdeFundo,
    required this.verdeTexto,
    required this.verde,
    required this.amareloFundo,
    required this.amareloTexto,
    required this.amarelo,
    required this.vermelhoFundo,
    required this.vermelhoTexto,
    required this.vermelho,
  });
}

const paletaClara = PaletaCores(
  azulClaro: Color(0xFF4AA8F0),
  azul: Color(0xFF1560C4),
  azulSolido: Color(0xFF14509F),
  azulEscuro: Color(0xFF0F3F80),
  azulTexto: Color(0xFF0F4C9E),
  azulFundo: Color(0xFFEAF3FE),
  fundo: Color(0xFFEEF4FB),
  fundoDestaque: Color(0xFFF4F9FF),
  fundoCard: Color(0xFFFFFFFF),
  fundoSuave: Color(0xFFEEF3F9),
  texto: Color(0xFF12283F),
  textoSuave: Color(0xFF5A7392),
  textoLabel: Color(0xFF33506F),
  borda: Color(0xFFE3ECF7),
  bordaInput: Color(0xFFCFE0F3),
  bordaDestaque: Color(0xFFDFEAF9),
  verdeFundo: Color(0xFFEAF7F0),
  verdeTexto: Color(0xFF1B6F4E),
  verde: Color(0xFF1F8A5F),
  amareloFundo: Color(0xFFFFF7EC),
  amareloTexto: Color(0xFF8A6A33),
  amarelo: Color(0xFFD89B2A),
  vermelhoFundo: Color(0xFFFDF3F1),
  vermelhoTexto: Color(0xFFA9372A),
  vermelho: Color(0xFFC0392B),
);

const paletaEscura = PaletaCores(
  azulClaro: Color(0xFF5FB3F5),
  azul: Color(0xFF3D8EF0),
  azulSolido: Color(0xFF2F7DE0),
  azulEscuro: Color(0xFF2A72CF),
  azulTexto: Color(0xFF8CC4FF),
  azulFundo: Color(0xFF17304D),
  fundo: Color(0xFF0D1624),
  fundoDestaque: Color(0xFF18263A),
  fundoCard: Color(0xFF142033),
  fundoSuave: Color(0xFF1C2A3F),
  texto: Color(0xFFE6EDF6),
  textoSuave: Color(0xFF9FB2C8),
  textoLabel: Color(0xFFC3D3E6),
  borda: Color(0xFF24344B),
  bordaInput: Color(0xFF33465F),
  bordaDestaque: Color(0xFF2B3E58),
  verdeFundo: Color(0xFF12342A),
  verdeTexto: Color(0xFF7FD6A9),
  verde: Color(0xFF3FB37F),
  amareloFundo: Color(0xFF382C15),
  amareloTexto: Color(0xFFF0C87A),
  amarelo: Color(0xFFE8B04A),
  vermelhoFundo: Color(0xFF3A1C19),
  vermelhoTexto: Color(0xFFF19B90),
  vermelho: Color(0xFFE5574A),
);

/// Cores do app. Os tons vêm da paleta ativa ([usarModoEscuro]): por isso são
/// getters, não `const` — ao trocar o tema, o app reconstrói as telas e cada
/// widget lê o tom novo. Os gradientes das telas de login/cadastro e dos
/// cartões azuis não mudam com o tema.
class CorApp {
  static PaletaCores _paleta = paletaClara;

  static bool get escuro => identical(_paleta, paletaEscura);

  /// Chamado pelo app quando o tema efetivo muda. O modo escuro só vale dentro
  /// do sistema: login, cadastro e ativação ficam sempre no claro (como no web).
  static void usarModoEscuro(bool escuro) => _paleta = escuro ? paletaEscura : paletaClara;

  static Color get azulClaro => _paleta.azulClaro;
  static Color get azul => _paleta.azul;

  /// Mesmo --azul-solido do web: botão principal das telas de login/cadastro.
  static Color get azulSolido => _paleta.azulSolido;
  static Color get azulEscuro => _paleta.azulEscuro;
  static Color get azulTexto => _paleta.azulTexto;
  static Color get azulFundo => _paleta.azulFundo;

  static LinearGradient get gradienteAzul => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [azulClaro, azul],
      );

  /// Mesmo --gradiente-hero do web (150deg, três tons de azul).
  static const gradienteHero = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFF4AA8F0), Color(0xFF1560C4), Color(0xFF0F3F80)],
    stops: [0, 0.6, 1],
  );

  /// Tela inicial do paciente (como no web): o card da dose fica com a cor
  /// oposta ao fundo da tela, para chamar a atenção; o Cartão do paciente, com
  /// a outra. Modo claro: dose escura e cartão claro; modo escuro: o inverso.
  static const gradienteCartaoEscuro = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B2F63), Color(0xFF11458F), Color(0xFF1B62C0)],
    stops: [0, 0.55, 1],
  );
  static const gradienteCartaoClaro = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4AA8F0), Color(0xFF2A85DF), Color(0xFF1560C4)],
    stops: [0, 0.55, 1],
  );
  static LinearGradient get fundoCardDose => escuro ? gradienteCartaoClaro : gradienteCartaoEscuro;
  static LinearGradient get fundoCartaoPaciente => escuro ? gradienteCartaoEscuro : gradienteCartaoClaro;

  /// Mesmo --gradiente-autenticacao do web: fundo das telas de login, cadastro
  /// e ativação (mais escuro que o hero).
  static const gradienteAutenticacao = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0xFF1B62C0), Color(0xFF0F4594), Color(0xFF0A2A5C)],
    stops: [0, 0.48, 1],
  );

  static Color get fundo => _paleta.fundo;
  static Color get fundoDestaque => _paleta.fundoDestaque;
  static Color get fundoCard => _paleta.fundoCard;
  static Color get fundoSuave => _paleta.fundoSuave;

  static Color get texto => _paleta.texto;
  static Color get textoSuave => _paleta.textoSuave;
  static Color get textoLabel => _paleta.textoLabel;

  static Color get borda => _paleta.borda;
  static Color get bordaInput => _paleta.bordaInput;
  static Color get bordaDestaque => _paleta.bordaDestaque;

  static Color get verdeFundo => _paleta.verdeFundo;
  static Color get verdeTexto => _paleta.verdeTexto;
  static Color get verde => _paleta.verde;

  static Color get amareloFundo => _paleta.amareloFundo;
  static Color get amareloTexto => _paleta.amareloTexto;
  static Color get amarelo => _paleta.amarelo;

  /// Mesmo --amarelo-borda do web (card "Precisam de atenção").
  static Color get amareloBorda => escuro ? const Color(0xFF5A4622) : const Color(0xFFF2E0C2);

  static Color get vermelhoFundo => _paleta.vermelhoFundo;
  static Color get vermelhoTexto => _paleta.vermelhoTexto;
  static Color get vermelho => _paleta.vermelho;
}

class RaioApp {
  static const pequeno = 12.0;
  static const medio = 16.0;
  static const grande = 24.0;
  static const pilula = 999.0;
}

TextTheme _escalarTextTheme(TextTheme tema, double fator, Color cor) {
  TextStyle? escalar(TextStyle? estilo) {
    if (estilo == null) return null;
    return estilo.copyWith(
      fontSize: estilo.fontSize != null ? estilo.fontSize! * fator : null,
      color: cor,
    );
  }

  return TextTheme(
    displayLarge: escalar(tema.displayLarge),
    displayMedium: escalar(tema.displayMedium),
    displaySmall: escalar(tema.displaySmall),
    headlineLarge: escalar(tema.headlineLarge),
    headlineMedium: escalar(tema.headlineMedium),
    headlineSmall: escalar(tema.headlineSmall),
    titleLarge: escalar(tema.titleLarge),
    titleMedium: escalar(tema.titleMedium),
    titleSmall: escalar(tema.titleSmall),
    bodyLarge: escalar(tema.bodyLarge),
    bodyMedium: escalar(tema.bodyMedium),
    bodySmall: escalar(tema.bodySmall),
    labelLarge: escalar(tema.labelLarge),
    labelMedium: escalar(tema.labelMedium),
    labelSmall: escalar(tema.labelSmall),
  );
}

ThemeData construirTema() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: CorApp.escuro ? Brightness.dark : Brightness.light,
    // Mesma fonte do web: Source Sans 3 (sem serifa, formal, feita para leitura
    // longa). Arquivos em assets/fonts, declarados no pubspec.yaml.
    fontFamily: 'Source Sans 3',
    scaffoldBackgroundColor: CorApp.fundo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CorApp.azul,
      brightness: CorApp.escuro ? Brightness.dark : Brightness.light,
      primary: CorApp.azul,
      secondary: CorApp.azulTexto,
      surface: CorApp.fundoCard,
      onSurface: CorApp.texto,
    ),
  );

  return base.copyWith(
    // TextTheme.apply(fontSizeFactor:) quebra se algum estilo do tema base
    // tiver fontSize nulo — troco por um copyWith manual, multiplicando só
    // quando o fontSize existe, pra aumentar o texto (público idoso) sem
    // depender dessa API frágil.
    textTheme: _escalarTextTheme(base.textTheme, 1.05, CorApp.texto),
    appBarTheme: AppBarTheme(
      backgroundColor: CorApp.fundoCard,
      foregroundColor: CorApp.texto,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: CorApp.fundoCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RaioApp.medio),
        side: BorderSide(color: CorApp.borda),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CorApp.fundoDestaque,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        borderSide: BorderSide(color: CorApp.bordaInput, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        borderSide: BorderSide(color: CorApp.bordaInput, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        borderSide: BorderSide(color: CorApp.azul, width: 2),
      ),
      labelStyle: TextStyle(color: CorApp.textoLabel, fontWeight: FontWeight.w700),
    ),
    // Troca de tela igual ao web: fade subindo 10 px em 0,22 s.
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: TransicaoPaginaCuidaMed(),
      TargetPlatform.iOS: TransicaoPaginaCuidaMed(),
      TargetPlatform.windows: TransicaoPaginaCuidaMed(),
      TargetPlatform.macOS: TransicaoPaginaCuidaMed(),
      TargetPlatform.linux: TransicaoPaginaCuidaMed(),
      TargetPlatform.fuchsia: TransicaoPaginaCuidaMed(),
    }),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: CorApp.fundoCard,
      selectedItemColor: CorApp.azulTexto,
      unselectedItemColor: CorApp.textoSuave,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
