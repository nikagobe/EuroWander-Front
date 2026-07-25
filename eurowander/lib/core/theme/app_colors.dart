import 'package:flutter/material.dart';

/// Semantic color tokens for EuroWander.
/// All raw hex values live here — screens reference only these tokens.
abstract final class AppColors {
  // ──────────────────────────────────────────────
  // Brand
  // ──────────────────────────────────────────────
  static const Color brandPrimary = Color(0xFF6C3CE0);
  static const Color brandSecondary = Color(0xFF9B59B6);
  static const Color brandAccent = Color(0xFFAB47BC);
  static const Color brandAmber = Color(0xFFFF9800);
  static const Color brandDeepOrange = Color(0xFFE65100);

  // ──────────────────────────────────────────────
  // Light palette
  // ──────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F5FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3EFFE);
  static const Color lightSurfaceDim = Color(0xFFEDE7F6);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightBorderSubtle = Color(0xFFF3F4F6);
  static const Color lightInputFill = Color(0xFFF9FAFB);
  static const Color lightScrim = Color(0x33000000);

  // ──────────────────────────────────────────────
  // Dark palette
  // ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkSurfaceVariant = Color(0xFF252540);
  static const Color darkSurfaceDim = Color(0xFF12121F);
  static const Color darkCard = Color(0xFF1E1E32);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFA1A1B5);
  static const Color darkTextTertiary = Color(0xFF6B6B80);
  static const Color darkBorder = Color(0xFF2E2E45);
  static const Color darkBorderSubtle = Color(0xFF1F1F35);
  static const Color darkInputFill = Color(0xFF1A1A2E);
  static const Color darkScrim = Color(0x80000000);

  // ──────────────────────────────────────────────
  // Semantic / Status
  // ──────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ──────────────────────────────────────────────
  // Travel-specific semantics
  // ──────────────────────────────────────────────
  static const Color flight = Color(0xFF3B82F6);
  static const Color hotel = Color(0xFFEC4899);
  static const Color restaurant = Color(0xFFF97316);
  static const Color attraction = Color(0xFF8B5CF6);
  static const Color transport = Color(0xFF06B6D4);
  static const Color budget = Color(0xFF10B981);

  // ──────────────────────────────────────────────
  // Gradients
  // ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandPrimary, Color(0xFF8B5CF6), brandSecondary],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightBackground, lightSurfaceDim, Color(0xFFF3E5F5)],
  );

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBackground, darkSurface, Color(0xFF1A1028)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFEEEEEE),
      Color(0xFFF5F5F5),
      Color(0xFFEEEEEE),
    ],
  );

  static const LinearGradient darkShimmerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF2A2A3E),
      Color(0xFF353550),
      Color(0xFF2A2A3E),
    ],
  );

  /// Gradient overlay for text readability on images
  static const LinearGradient imageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC000000)],
  );
}
