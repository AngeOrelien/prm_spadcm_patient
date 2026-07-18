import 'package:flutter/material.dart';

/// Palette de couleurs unique de l'app Patients/Familles.
///
/// Même identité de marque que l'app Personnel (mobile-app-personnel) pour
/// que les deux apps soient reconnaissables comme faisant partie du même
/// écosystème PRM — SPAD Cameroun.
class AppColors {
  AppColors._();

  // --- Marque ---
  static const Color primary = Color(0xFF00A7BB);
  static const Color primaryDark = Color(0xFF007583);
  static const Color primaryLight = Color(0xFF40C0CD);
  static const Color primarySurface = Color(0xFFE5F6F7);

  static const Color secondary = Color(0xFFFF6F61); // corail
  static const Color secondaryDark = Color(0xFFE0503F);
  static const Color secondaryLight = Color(0xFFFFA898);
  static const Color secondarySurface = Color(0xFFFFEDE9);

  // --- Neutres ---
  static const Color background = Color(0xFFF7F9F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F3F4);
  static const Color border = Color(0xFFE3E7E8);

  static const Color textPrimary = Color(0xFF1B1F1E);
  static const Color textSecondary = Color(0xFF6B7573);
  static const Color textDisabled = Color(0xFFAAB2B0);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Retours utilisateur ---
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD8453A);
  static const Color info = Color(0xFF1976D2);

  // --- Alerte SOS ---
  // Couleur dédiée au bouton d'urgence, volontairement distincte de la
  // palette "erreur" (feedback de formulaire) pour qu'il reste immédiatement
  // reconnaissable où qu'il apparaisse dans l'app.
  static const Color sos = Color(0xFFD32F2F);
  static const Color sosDark = Color(0xFFA31515);
}
