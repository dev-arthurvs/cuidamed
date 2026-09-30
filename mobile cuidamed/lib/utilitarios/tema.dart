import 'package:flutter/material.dart';

import 'animacoes.dart';

/// Paleta idêntica à do front-end web (front-end cuidamed/src/estilos/global.css),
/// pra manter a mesma identidade visual entre as duas plataformas.
class CorApp {
  static const azulClaro = Color(0xFF4AA8F0);
  static const azul = Color(0xFF1560C4);
  static const azulEscuro = Color(0xFF0F3F80);
  static const azulTexto = Color(0xFF0F4C9E);
  static const gradienteAzul = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [azulClaro, azul],
  );

  /// Mesmo --gradiente-hero do web (150deg, três tons de azul) — usado no
  /// painel das telas de autenticação.
  static const gradienteHero = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [azulClaro, azul, azulEscuro],
    stops: [0, 0.6, 1],
  );

  static const fundo = Color(0xFFEEF4FB);
  static const fundoDestaque = Color(0xFFF4F9FF);
  static const fundoCard = Color(0xFFFFFFFF);

  static const texto = Color(0xFF12283F);
  static const textoSuave = Color(0xFF5A7392);
  static const textoLabel = Color(0xFF33506F);

  static const borda = Color(0xFFE3ECF7);
  static const bordaInput = Color(0xFFCFE0F3);
  static const bordaDestaque = Color(0xFFDFEAF9);

  static const verdeFundo = Color(0xFFEAF7F0);
  static const verdeTexto = Color(0xFF1B6F4E);
  static const verde = Color(0xFF1F8A5F);

  static const azulFundo = Color(0xFFEAF3FE);

  static const amareloFundo = Color(0xFFFFF7EC);
  static const amareloTexto = Color(0xFF8A6A33);
  static const amarelo = Color(0xFFD89B2A);

  static const vermelhoFundo = Color(0xFFFDF3F1);
  static const vermelhoTexto = Color(0xFFA9372A);
  static const vermelho = Color(0xFFC0392B);
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
    fontFamily: 'Nunito', // mesma fonte do web (assets/fonts, declarada no pubspec.yaml)
    scaffoldBackgroundColor: CorApp.fundo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CorApp.azul,
      primary: CorApp.azul,
      secondary: CorApp.azulTexto,
      surface: CorApp.fundoCard,
    ),
  );

  return base.copyWith(
    // TextTheme.apply(fontSizeFactor:) quebra se algum estilo do tema base
    // tiver fontSize nulo — troco por um copyWith manual, multiplicando só
    // quando o fontSize existe, pra aumentar o texto (público idoso) sem
    // depender dessa API frágil.
    textTheme: _escalarTextTheme(base.textTheme, 1.05, CorApp.texto),
    appBarTheme: const AppBarTheme(
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
        side: const BorderSide(color: CorApp.borda),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CorApp.fundoDestaque,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        borderSide: const BorderSide(color: CorApp.bordaInput, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        borderSide: const BorderSide(color: CorApp.bordaInput, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RaioApp.pequeno),
        borderSide: const BorderSide(color: CorApp.azul, width: 2),
      ),
      labelStyle: const TextStyle(color: CorApp.textoLabel, fontWeight: FontWeight.w700),
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
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: CorApp.fundoCard,
      selectedItemColor: CorApp.azulTexto,
      unselectedItemColor: CorApp.textoSuave,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
