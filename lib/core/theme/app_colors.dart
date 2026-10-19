import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Theme Palette (Primary Default)
  static const Color darkBackground = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF161A23);
  static const Color darkCard = Color(0xFF1E2230);
  static const Color darkCardElevated = Color(0xFF262C3E);
  static const Color darkBorder = Color(0xFF2A3042);

  static const Color darkPrimary = Color(0xFFF5A623); // Amber Gold
  static const Color darkPrimaryContainer = Color(0xFF38270A);
  static const Color darkAccent = Color(0xFF4ECDC4); // Soft Teal
  static const Color darkAccentContainer = Color(0xFF0D3230);

  static const Color darkSuccess = Color(0xFF2ECC71); // Emerald
  static const Color darkDanger = Color(0xFFFF6B6B); // Coral Red
  static const Color darkWarning = Color(0xFFF39C12);
  static const Color darkInfo = Color(0xFF3498DB);

  // Semantics aliases
  static const Color income = Color(0xFF2ECC71);
  static const Color expense = Color(0xFFFF6B6B);

  static const Color darkTextPrimary = Color(0xFFF0F0F5);
  static const Color darkTextSecondary = Color(0xFF8E8E9A);
  static const Color darkTextTertiary = Color(0xFF5A5A68);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFFAFAF8);
  static const Color lightSurface = Color(0xFFF5F3EF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E3DC);

  static const Color lightPrimary = Color(0xFFE8961E); // Deep Amber
  static const Color lightPrimaryContainer = Color(0xFFFDF3E3);
  static const Color lightAccent = Color(0xFF3DBDB5); // Ocean Teal
  static const Color lightAccentContainer = Color(0xFFE2F8F6);

  static const Color lightSuccess = Color(0xFF27AE60);
  static const Color lightDanger = Color(0xFFE74C3C);
  static const Color lightWarning = Color(0xFFD35400);
  static const Color lightInfo = Color(0xFF2980B9);

  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B7B);
  static const Color lightTextTertiary = Color(0xFFA0A0AF);

  // Category Accent Colors
  static const List<Color> categoryPalette = [
    Color(0xFFFF6B6B), // Food & Dining
    Color(0xFF4ECDC4), // Transportation
    Color(0xFFF5A623), // Housing & Rent
    Color(0xFF45B7D1), // Utilities
    Color(0xFFFF8A5C), // Shopping
    Color(0xFF2ECC71), // Healthcare
    Color(0xFFA855F7), // Entertainment
    Color(0xFF3B82F6), // Education
    Color(0xFFEC4899), // Travel
    Color(0xFF6366F1), // Subscriptions
    Color(0xFFF472B6), // Gifts
    Color(0xFF8E8E9A), // Other
  ];
}
