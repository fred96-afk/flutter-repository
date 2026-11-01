import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Primary brand terracotta colors
  static const Color terracotta = Color(0xFF914F3A);
  static const Color terracottaLight = Color(0xFFE58F75);

  // Light theme colors
  static const Color lightBg = Color(0xFFFFF3EE);
  static const Color lightSurface = Color(0xFFFFFAF7);
  static const Color lightCard = Color(0xFFFFFAF7);
  static const Color lightDarkBrown = Color(0xFF302724);
  static const Color lightSoftBrown = Color(0xFF69483E);
  static const Color lightBorder = Color(0xFFE5C9BE);
  static const Color lightContainer = Color(0xFFF3DCD3);

  // Dark theme colors
  static const Color darkBg = Color(0xFF1E1A19);
  static const Color darkSurface = Color(0xFF282322);
  static const Color darkCard = Color(0xFF282322);
  static const Color darkLightCream = Color(0xFFF5EBE6);
  static const Color darkMutedCream = Color(0xFFB8A6A0);
  static const Color darkBorder = Color(0xFF453935);
  static const Color darkContainer = Color(0xFF3D2721);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: terracotta,
      brightness: Brightness.light,
      primary: terracotta,
      onPrimary: Colors.white,
      primaryContainer: lightContainer,
      onPrimaryContainer: const Color(0xFF38150D),
      surface: lightSurface,
      onSurface: lightDarkBrown,
      onSurfaceVariant: lightSoftBrown,
      outline: lightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: lightDarkBrown,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      dividerColor: lightBorder,
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: terracotta, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: lightBg,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: terracotta,
      brightness: Brightness.dark,
      primary: terracottaLight,
      onPrimary: const Color(0xFF2E120A),
      primaryContainer: darkContainer,
      onPrimaryContainer: const Color(0xFFFFDBD1),
      surface: darkSurface,
      onSurface: darkLightCream,
      onSurfaceVariant: darkMutedCream,
      outline: darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkLightCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      dividerColor: darkBorder,
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF352D2B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: terracottaLight, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: darkBg,
      ),
    );
  }
}
