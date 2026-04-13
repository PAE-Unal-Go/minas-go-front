import 'package:flutter/material.dart';

abstract final class PoiRarity {
  static const String basic = 'basic';
  static const String important = 'important';
  static const String legendary = 'legendary';

  static Color primaryColor(String? rarity) {
    return switch (rarity?.toLowerCase()) {
      basic => const Color(0xFF2DD4BF),
      important => const Color(0xFFF59E0B),
      legendary => const Color(0xFFE879F9),
      _ => const Color(0xFF9CA3AF),
    };
  }

  static String label(String? rarity) {
    return switch (rarity?.toLowerCase()) {
      basic => 'Básico',
      important => 'Importante',
      legendary => 'Legendario',
      _ => rarity != null
          ? '${rarity[0].toUpperCase()}${rarity.substring(1)}'
          : 'Básico',
    };
  }

  static String symbol(String? rarity) {
    return switch (rarity?.toLowerCase()) {
      basic => '◆',
      important => '◆◆',
      legendary => '✦',
      _ => '◆',
    };
  }

  static int starCount(String? rarity) {
    return switch (rarity?.toLowerCase()) {
      basic => 1,
      important => 2,
      legendary => 3,
      _ => 1,
    };
  }

  /// Colores del borde animado por rareza.
  static List<Color> borderColors(String? rarity) {
    return switch (rarity?.toLowerCase()) {
      basic => const [Color(0xFF2DD4BF), Color(0xFF99F6E4), Color(0xFF2DD4BF)],
      important => const [
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
