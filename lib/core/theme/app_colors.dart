import 'package:flutter/material.dart';

/// Design tokens.
///
/// Light mode is a calm "frosted sage" look: off-white canvas, soft green glow,
/// white cards and near-black pill buttons. Dark mode is a "plum night" look:
/// deep violet canvas with pink/lilac glows and pastel gradient cards.
abstract final class AppColors {
  static const fontFamily = 'PlusJakartaSans';

  // ── Light — frosted sage ──────────────────────────────────────────────────
  static const lightCanvas = Color(0xFFF4F5F2);
  static const lightCard = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B211D);
  static const inkSoft = Color(0xFF5D6761);
  static const sage = Color(0xFF5F8F72);
  static const sageTint = Color(0xFFDDEAE1);
  static const lightGlows = [
    Color(0xFFA9CDB5),
    Color(0xFFD5EADB),
    Color(0xFFE6E0F3),
  ];

  // ── Dark — plum night ─────────────────────────────────────────────────────
  static const darkCanvas = Color(0xFF150F1C);
  static const darkCard = Color(0xFF221A2D);
  static const mist = Color(0xFFF5F0FB);
  static const mistSoft = Color(0xFFB8ADC6);
  static const lilac = Color(0xFFCDB4F6);
  static const pink = Color(0xFFF4B6DD);
  static const darkGlows = [
    Color(0xFF8A5FD0),
    Color(0xFFC46FAE),
    Color(0xFF4B2E78),
  ];

  // ── Shared accents ────────────────────────────────────────────────────────
  /// The "AI" gradient used by the sparkle orb, send buttons and nav centre.
  static const aiGradientLight = [Color(0xFFA3CDB0), Color(0xFF557F66)];
  static const aiGradientDark = [Color(0xFFF4B6DD), Color(0xFFA98BF0)];

  /// Text drawn on pastel cards — the cards stay light in both modes.
  static const onPastel = Color(0xFF1C1626);

  static const success = Color(0xFF3F9A6B);
  static const warning = Color(0xFFD9932B);
  static const danger = Color(0xFFD0533F);

  static List<Color> aiGradient(Brightness b) =>
      b == Brightness.dark ? aiGradientDark : aiGradientLight;
}

/// Soft two-stop gradients for category ("folder") cards.
enum Pastel {
  rose([Color(0xFFFAD6DC), Color(0xFFEDB5C8)]),
  lilac([Color(0xFFE7D7FB), Color(0xFFCAB3F3)]),
  sage([Color(0xFFDAEDE0), Color(0xFFB2D5BE)]),
  periwinkle([Color(0xFFD7DFFF), Color(0xFFB3C0F6)]),
  butter([Color(0xFFFCEFC0), Color(0xFFF4D98C)]),
  sky([Color(0xFFD2EDF6), Color(0xFFA8D3E7)]),
  peach([Color(0xFFFDDFC9), Color(0xFFF5BF9C)]);

  const Pastel(this.colors);
  final List<Color> colors;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors,
  );

  /// Stable pastel for an arbitrary key (a category name or id).
  static Pastel of(Object key) {
    final h = key.toString().codeUnits.fold(7, (a, c) => (a * 31 + c) & 0xFFFF);
    return values[h % values.length];
  }
}
