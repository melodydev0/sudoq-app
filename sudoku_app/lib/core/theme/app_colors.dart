import 'package:flutter/material.dart';

/// Handcrafted color palette – warm, editorial, human-made feel
class AppColors {
  // Brand – warmer, less “template” violet-blue
  static const Color gradientStart = Color(0xFF5B5F97);
  static const Color gradientMiddle = Color(0xFF6D5B8A);
  static const Color gradientEnd = Color(0xFFE8A4B8);

  // Accent – slightly muted, natural
  static const Color accentGold = Color(0xFFD4A84B);
  static const Color gold = Color(0xFFD4A84B);
  static const Color accentCoral = Color(0xFFD8736E);
  static const Color accentTeal = Color(0xFF5A9B94);
  static const Color accentPurple = Color(0xFF8B7A9E);

  // Primary – warm indigo/slate
  static const Color primary = Color(0xFF5558A8);
  static const Color primaryBlue = Color(0xFF5558A8);
  static const Color primaryLight = Color(0xFF7B7EC7);
  static const Color primaryDark = Color(0xFF3D4078);

  // Surface – Light (warm paper/cream tint)
  static const Color backgroundLight = Color(0xFFF6F5F2);
  static const Color surfaceLight = Color(0xFFFDFCF9);
  static const Color cardLight = Color(0xFFFDFCF9);

  // Surface – Dark (soft charcoal, not pure black)
  static const Color backgroundDark = Color(0xFF1C1B1F);
  static const Color surfaceDark = Color(0xFF252429);
  static const Color cardDark = Color(0xFF2A292E);
  static const Color backgroundDarkCard = Color(0xFF232228);

  // Text – warmer grays
  static const Color textPrimary = Color(0xFF2C2B30);
  static const Color textSecondary = Color(0xFF5E5D64);
  static const Color textHint = Color(0xFF8E8D92);
  static const Color textPrimaryDark = Color(0xFFE8E6E3);
  static const Color textSecondaryDark = Color(0xFFA8A6A3);

  // Game Grid Colors
  static const Color gridLine = Color(0xFFE5E7EB);
  static const Color gridLineBold = Color(0xFF9CA3AF);
  static const Color gridLineDark = Color(0xFF30363D);
  static const Color gridLineBoldDark = Color(0xFF484F58);

  // Cell Colors
  static const Color cellHighlight = Color(0xFFE8F4FD);
  static const Color cellSameNumber = Color(0xFFD1E7FF);
  static const Color cellError = Color(0xFFFFE5E5);
  static const Color cellFixed = Color(0xFFF3F4F6);
  static const Color cellHighlightDark = Color(0xFF1F3A5F);
  static const Color cellSameNumberDark = Color(0xFF2A4A6F);
  static const Color cellErrorDark = Color(0xFF5F1F1F);
  static const Color cellFixedDark = Color(0xFF2D333B);

  // Status – slightly softer
  static const Color success = Color(0xFF2E8B6C);
  static const Color warning = Color(0xFFD4942E);
  static const Color error = Color(0xFFC94A4A);
  static const Color info = Color(0xFF4A6FA5);

  // Number Colors
  static const Color numberFixed = Color(0xFF1F2937);
  static const Color numberUser = Color(0xFF3B82F6);
  static const Color numberNote = Color(0xFF6B7280);
  static const Color numberError = Color(0xFFEF4444);

  // Premium Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMiddle, gradientEnd],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
  );

  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  );

  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
  );

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
  );

  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F2027),
      Color(0xFF203A43),
      Color(0xFF2C5364),
    ],
  );
}
