import 'package:flutter/material.dart';

/// App color palette - Futuristic, dark-first design with neon highlights
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ===== Dark Base Colors =====
  static const Color background = Color(0xFF020004);
  static const Color surface = Color(0xFF34195B);
  static const Color surfaceVariant = Color(0xFF1A0D2E);

  // ===== Neon Accent Colors =====
  static const Color primary = Color(0xFF540CC3);
  static const Color primaryLight = Color(0xFF9F3BDB);
  static const Color secondary = Color(0xFF00D9FF);
  static const Color accent = Color(0xFFFF6B9D);

  // ===== Status Colors =====
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF40C4FF);

  // ===== Neutral Colors =====
  static const Color textPrimary = Color(0xFFF7F7F8);
  static const Color textSecondary = Color(0xFFA7A1AB);
  static const Color textDisabled = Color(0xFF6B6570);
  static const Color divider = Color(0xFF3D2D5A);

  // ===== Gradient Definitions =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF540CC3), Color(0xFF00D9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A0D2E), Color(0xFF34195B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== Neon Glow Effects =====
  static List<BoxShadow> neonGlow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.6 * intensity),
        blurRadius: 8,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.3 * intensity),
        blurRadius: 16,
        spreadRadius: 4,
      ),
    ];
  }

  static List<BoxShadow> get primaryGlow => neonGlow(primary);
  static List<BoxShadow> get successGlow => neonGlow(success);
  static List<BoxShadow> get accentGlow => neonGlow(accent);
}
