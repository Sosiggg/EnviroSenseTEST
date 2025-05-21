import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors
  static const Color _lightPrimaryColor = Color(0xFF0078D7); // Modern blue
  static const Color _lightPrimaryVariantColor = Color(0xFF0050A1);
  static const Color _lightSecondaryColor = Color(0xFF00C853); // Green
  static const Color _lightOnPrimaryColor = Colors.white;
  static const Color _lightBackgroundColor = Color(0xFFF8F9FA); // Light gray
  static const Color _lightErrorColor = Color(0xFFFF3D00); // Bright orange-red
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightOnSurfaceColor = Color(0xFF202124); // Dark gray

  // Dark Theme Colors
  static const Color _darkPrimaryColor = Color(
    0xFF4DA3FF,
  ); // Lighter blue for dark theme
  static const Color _darkPrimaryVariantColor = Color(0xFF0078D7);
  static const Color _darkSecondaryColor = Color(0xFF5EFF82); // Lighter green
  static const Color _darkOnPrimaryColor = Colors.white;
  static const Color _darkBackgroundColor = Color(0xFF121212);
  static const Color _darkErrorColor = Color(0xFFFF7539); // Lighter orange-red
  static const Color _darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color _darkOnSurfaceColor = Colors.white;

  // Chart Colors - More vibrant and accessible
  static const List<Color> chartColors = [
    Color(0xFF4DA3FF), // Blue
    Color(0xFF5EFF82), // Green
    Color(0xFFFFC107), // Amber
    Color(0xFFFF7539), // Orange
    Color(0xFFBB86FC), // Purple
  ];

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _lightPrimaryColor,
    colorScheme: const ColorScheme.light(
      primary: _lightPrimaryColor,
      primaryContainer: _lightPrimaryVariantColor,
      secondary: _lightSecondaryColor,
      onPrimary: _lightOnPrimaryColor,
      // Use surface-related properties instead of background
      surface: _lightSurfaceColor,
      surfaceContainerHighest: _lightBackgroundColor,
      surfaceTint: _lightPrimaryColor,
      onSurface: _lightOnSurfaceColor,
      // Error colors
      error: _lightErrorColor,
      onError: Colors.white,
      // Secondary colors
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFDCF8E8), // Light green for containers
      onSecondaryContainer: Color(
        0xFF004D25,
      ), // Dark green for text on containers
      // Tertiary colors
      tertiary: Color(0xFFFFC107), // Amber for tertiary actions
      onTertiary: Colors.black87,
    ),
    scaffoldBackgroundColor: _lightBackgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightPrimaryColor,
      foregroundColor: _lightOnPrimaryColor,
      elevation: 0,
      centerTitle: false, // Left-aligned title for modern look
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _lightOnPrimaryColor,
      ),
      iconTheme: const IconThemeData(color: _lightOnPrimaryColor),
      actionsIconTheme: const IconThemeData(color: _lightOnPrimaryColor),
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 32,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
      displaySmall: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        letterSpacing: 0.15,
      ),
      titleLarge: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimaryColor,
        foregroundColor: _lightOnPrimaryColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(
          88,
          48,
        ), // Taller buttons for better touch targets
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lightPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lightErrorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _darkPrimaryColor,
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimaryColor,
      primaryContainer: _darkPrimaryVariantColor,
      secondary: _darkSecondaryColor,
      onPrimary: _darkOnPrimaryColor,
      // Surface colors
      surface: _darkSurfaceColor,
      surfaceContainerHighest: _darkBackgroundColor,
      surfaceTint: _darkPrimaryColor,
      onSurface: _darkOnSurfaceColor,
      // Error colors
      error: _darkErrorColor,
      onError: Colors.white,
      // Secondary colors
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFF004D25), // Dark green for containers
      onSecondaryContainer: Color(
        0xFFDCF8E8,
      ), // Light green for text on containers
      // Tertiary colors
      tertiary: Color(0xFFFFD54F), // Lighter amber for dark theme
      onTertiary: Colors.black,
    ),
    scaffoldBackgroundColor: _darkBackgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurfaceColor,
      foregroundColor: _darkOnSurfaceColor,
      elevation: 0,
      centerTitle: false, // Left-aligned title for modern look
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _darkOnSurfaceColor,
      ),
      iconTheme: const IconThemeData(color: _darkOnSurfaceColor),
      actionsIconTheme: const IconThemeData(color: _darkOnSurfaceColor),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 32,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      displayMedium: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: Colors.white,
      ),
      displaySmall: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: Colors.white,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        letterSpacing: 0.15,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: _darkOnPrimaryColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(
          88,
          48,
        ), // Taller buttons for better touch targets
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkErrorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardTheme(
      color: _darkSurfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
