import 'package:flutter/material.dart';

/// Paleta fixa de referência. Valores são `static const` para que possam ser
/// usados em expressões `const` e em valores padrão de parâmetros (exigência
/// da linguagem Dart). A troca de "skin" é feita em tempo de execução por um
/// [ColorFilter] aplicado na raiz do app (ver [themeColorMatrixFor]).
class AppColors {
  AppColors._();
  static const bgMain = Color(0xFF0A0A12);
  static const bgCard = Color(0xFF0E1628);
  static const azulNeon = Color(0xFF00AFFF);
  static const ciano = Color(0xFF00F0FF);
  static const azulClaro = Color(0xFF19D9FF);
  static const roxo = Color(0xFFB400FF);
  static const roxoNeon = Color(0xFFB400FF);
  static const magenta = Color(0xFFD500FF);
  static const texto = Color(0xFFE8F0FF);
  static const textoClaro = Color(0xFFA0A0B0);
  static const branco = Color(0xFFFFFFFF);
  static const dourado = Color(0xFFFFD700);
  static const verde = Color(0xFF00FFAA);
}

/// Nomess das skins disponíveis (usadas no seletor de tema).
class Themes {
  Themes._();
  static const names = [
    'Neon',
    'Dark',
    'Light',
    'American',
    'Brazilian',
    'Violet',
    'Sunset',
    'Ocean',
  ];

  /// Índice da skin ativa. Alterado pelo seletor em ConfigScreen.
  static int index = 0;

  /// Obtém o nome da skin ativa.
  static String get name => names[index % names.length];
}

/// Retorna uma matriz 5x4 de [ColorFilter] (RGBA) que recolore dinamicamente
/// todo o app conforme a skin selecionada. Aplicada via [ColorFiltered] na raiz.
ColorFilter themeColorFilterFor(int index) {
  switch (index % Themes.names.length) {
    case 0: // Neon: realce de saturação/brilho
      return const ColorFilter.matrix(<double>[
        1.15, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.15, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.15, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]);
    case 1: // Dark: leve escurecimento e dessaturação
      return const ColorFilter.matrix(<double>[
        0.65, 0.0, 0.0, 0.0, -10.0,
        0.0, 0.65, 0.0, 0.0, -10.0,
        0.0, 0.0, 0.70, 0.0, -10.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]);
    case 2: // Light: clareia bastante (fundo quase branco)
      return const ColorFilter.matrix(<double>[
        1.9, 0.0, 0.0, 0.0, 40.0,
        0.0, 1.9, 0.0, 0.0, 40.0,
        0.0, 0.0, 1.9, 0.0, 40.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]);
    case 3: // American: desloca para azul/vermelho (matiz)
      return const ColorFilter.matrix(<double>[
        1.0, 0.1, 0.0, 0.0, -10.0,
        0.0, 1.0, 0.0, 0.0, 20.0,
        0.0, 0.0, 1.3, 0.0, 30.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]);
    case 4: // Brazilian: verde/amarelo
      return const ColorFilter.matrix(<double>[
        0.9, 0.15, 0.0, 0.0, 0.0,
        0.0, 1.3, 0.0, 0.0, 10.0,
        0.0, 0.0, 0.8, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]);
    case 5: // Violet: matiz roxo
      return const ColorFilter.matrix(<double>[
        1.2, 0.0, 0.2, 0.0, -5.0,
        0.0, 0.8, 0.2, 0.0, 15.0,
        0.1, 0.0, 1.2, 0.0, 25.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]);
    case 6: // Sunset: quente avermelhado
      return const ColorFilter.matrix(<double>[
        1.3, 0.1, 0.0, 0.0, 15.0,
        0.2, 1.0, 0.0, 0.0, 5.0,
        0.0, 0.0, 0.85, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]);
    case 7: // Ocean: azul frio esverdeado
      return const ColorFilter.matrix(<double>[
        0.85, 0.0, 0.15, 0.0, 0.0,
        0.0, 1.1, 0.1, 0.0, 5.0,
        0.0, 0.0, 1.3, 0.0, 15.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]);
    default:
      return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
  }
}
