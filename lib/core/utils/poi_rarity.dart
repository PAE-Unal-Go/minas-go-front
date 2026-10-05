import 'package:flutter/material.dart';

abstract final class PoiRarity {
  static const String singular = 'singular';
  static const String epic = 'epic';
  static const String legendary = 'legendary';

  static String? normalize(String? rarity) {
    if (rarity == null) return null;
    final r = rarity.toLowerCase().replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u').trim();
    if (r == singular || r.startsWith('singul')) return singular;
    if (r == epic || r.startsWith('epic')) return epic;
    if (r == legendary || r.startsWith('legend')) return legendary;
    if (r.startsWith('basic') || r.startsWith('básic')) return singular;
    if (r.startsWith('import')) return epic;
    return r;
  }

  static Color primaryColor(String? rarity) {
    return switch (normalize(rarity)) {
      singular => const Color(0xFF2DD4BF),
      epic => const Color(0xFFF59E0B),
      legendary => const Color(0xFFE879F9),
      _ => const Color(0xFF9CA3AF),
    };
  }

  static String label(String? rarity) {
    return switch (normalize(rarity)) {
      singular => 'Singular',
      epic => 'Épico',
      legendary => 'Legendario',
      _ => rarity != null
          ? '${rarity[0].toUpperCase()}${rarity.substring(1)}'
          : 'Singular',
    };
  }

  static String symbol(String? rarity) {
    return switch (normalize(rarity)) {
      singular => '◆',
      epic => '◆◆',
      legendary => '✦',
      _ => '◆',
    };
  }

  static int starCount(String? rarity) {
    return switch (normalize(rarity)) {
      singular => 1,
      epic => 2,
      legendary => 3,
      _ => 1,
    };
  }

  /// Colores del borde animado por rareza.
  static List<Color> borderColors(String? rarity) {
    return switch (normalize(rarity)) {
      singular => const [Color(0xFF2DD4BF), Color(0xFF99F6E4), Color(0xFF2DD4BF)],
      epic => const [
          Color(0xFF92400E),
          Color(0xFFF59E0B),
          Color(0xFFFEF08A),
          Color(0xFFF59E0B),
          Color(0xFF92400E),
        ],
      legendary => const [
          Color(0xFFFF6B6B),
          Color(0xFFFFD93D),
          Color(0xFF6BCB77),
          Color(0xFF4D96FF),
          Color(0xFFE879F9),
          Color(0xFFFF6B6B),
        ],
      _ => const [Color(0xFF9CA3AF), Color(0xFF9CA3AF)],
    };
  }
}
