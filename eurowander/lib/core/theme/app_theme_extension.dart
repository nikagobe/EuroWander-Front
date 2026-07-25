import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Custom ThemeExtension providing travel-app-specific design tokens
/// accessible via `Theme.of(context).extension<EuroWanderTheme>()!`.
class EuroWanderTheme extends ThemeExtension<EuroWanderTheme> {
  const EuroWanderTheme({
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.borderSubtle,
    required this.cardColor,
    required this.inputFill,
    required this.scrim,
    required this.surfaceGradient,
    required this.shimmerGradient,
    required this.flightColor,
    required this.hotelColor,
    required this.restaurantColor,
    required this.attractionColor,
    required this.transportColor,
    required this.budgetColor,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color borderSubtle;
  final Color cardColor;
  final Color inputFill;
  final Color scrim;
  final LinearGradient surfaceGradient;
  final LinearGradient shimmerGradient;

  // Travel category colors
  final Color flightColor;
  final Color hotelColor;
  final Color restaurantColor;
  final Color attractionColor;
  final Color transportColor;
  final Color budgetColor;

  // ──────────────────────────────────────────────
  // Presets
  // ──────────────────────────────────────────────
  static const light = EuroWanderTheme(
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    border: AppColors.lightBorder,
    borderSubtle: AppColors.lightBorderSubtle,
    cardColor: AppColors.lightCard,
    inputFill: AppColors.lightInputFill,
    scrim: AppColors.lightScrim,
    surfaceGradient: AppColors.surfaceGradient,
    shimmerGradient: AppColors.shimmerGradient,
    flightColor: AppColors.flight,
    hotelColor: AppColors.hotel,
    restaurantColor: AppColors.restaurant,
    attractionColor: AppColors.attraction,
    transportColor: AppColors.transport,
    budgetColor: AppColors.budget,
  );

  static const dark = EuroWanderTheme(
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    border: AppColors.darkBorder,
    borderSubtle: AppColors.darkBorderSubtle,
    cardColor: AppColors.darkCard,
    inputFill: AppColors.darkInputFill,
    scrim: AppColors.darkScrim,
    surfaceGradient: AppColors.darkSurfaceGradient,
    shimmerGradient: AppColors.darkShimmerGradient,
    flightColor: AppColors.flight,
    hotelColor: AppColors.hotel,
    restaurantColor: AppColors.restaurant,
    attractionColor: AppColors.attraction,
    transportColor: AppColors.transport,
    budgetColor: AppColors.budget,
  );

  @override
  EuroWanderTheme copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? borderSubtle,
    Color? cardColor,
    Color? inputFill,
    Color? scrim,
    LinearGradient? surfaceGradient,
    LinearGradient? shimmerGradient,
    Color? flightColor,
    Color? hotelColor,
    Color? restaurantColor,
    Color? attractionColor,
    Color? transportColor,
    Color? budgetColor,
  }) {
    return EuroWanderTheme(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      cardColor: cardColor ?? this.cardColor,
      inputFill: inputFill ?? this.inputFill,
      scrim: scrim ?? this.scrim,
      surfaceGradient: surfaceGradient ?? this.surfaceGradient,
      shimmerGradient: shimmerGradient ?? this.shimmerGradient,
      flightColor: flightColor ?? this.flightColor,
      hotelColor: hotelColor ?? this.hotelColor,
      restaurantColor: restaurantColor ?? this.restaurantColor,
      attractionColor: attractionColor ?? this.attractionColor,
      transportColor: transportColor ?? this.transportColor,
      budgetColor: budgetColor ?? this.budgetColor,
    );
  }

  @override
  EuroWanderTheme lerp(covariant ThemeExtension<EuroWanderTheme>? other, double t) {
    if (other is! EuroWanderTheme) return this;
    return EuroWanderTheme(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      surfaceGradient: LinearGradient.lerp(surfaceGradient, other.surfaceGradient, t)!,
      shimmerGradient: LinearGradient.lerp(shimmerGradient, other.shimmerGradient, t)!,
      flightColor: Color.lerp(flightColor, other.flightColor, t)!,
      hotelColor: Color.lerp(hotelColor, other.hotelColor, t)!,
      restaurantColor: Color.lerp(restaurantColor, other.restaurantColor, t)!,
      attractionColor: Color.lerp(attractionColor, other.attractionColor, t)!,
      transportColor: Color.lerp(transportColor, other.transportColor, t)!,
      budgetColor: Color.lerp(budgetColor, other.budgetColor, t)!,
    );
  }
}

/// Convenience extension on BuildContext for quick access.
extension EuroWanderThemeX on BuildContext {
  EuroWanderTheme get ew => Theme.of(this).extension<EuroWanderTheme>()!;
}
