import 'package:flutter/material.dart';

class AppTheme {
  // Koyu Tema
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    primaryColor: const Color(0xFF00D4FF),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00D4FF),
      secondary: Color(0xFF00D4FF),
      surface: Color(0xFF1A1A2E),
      background: Color(0xFF1A1A2E),
      error: Colors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A2E),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Color(0xFF00D4FF),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00D4FF),
        side: const BorderSide(color: Color(0xFF00D4FF)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.white38),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.white38),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFF00D4FF)),
      ),
    ),
  );

  // Açık Tema
  static ThemeData lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    primaryColor: const Color(0xFF00D4FF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00D4FF),
      secondary: Color(0xFF00D4FF),
      surface: Colors.white,
      background: Color(0xFFF8F9FA),
      error: Colors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
      titleTextStyle: TextStyle(
        color: Color(0xFF2C3E50),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFF2C3E50)),
      displayMedium: TextStyle(color: Color(0xFF2C3E50)),
      displaySmall: TextStyle(color: Color(0xFF2C3E50)),
      headlineLarge: TextStyle(color: Color(0xFF2C3E50)),
      headlineMedium: TextStyle(color: Color(0xFF2C3E50)),
      headlineSmall: TextStyle(color: Color(0xFF2C3E50)),
      titleLarge: TextStyle(color: Color(0xFF2C3E50)),
      titleMedium: TextStyle(color: Color(0xFF2C3E50)),
      titleSmall: TextStyle(color: Color(0xFF2C3E50)),
      bodyLarge: TextStyle(color: Color(0xFF2C3E50)),
      bodyMedium: TextStyle(color: Color(0xFF2C3E50)),
      bodySmall: TextStyle(color: Color(0xFF2C3E50)),
      labelLarge: TextStyle(color: Color(0xFF2C3E50)),
      labelMedium: TextStyle(color: Color(0xFF2C3E50)),
      labelSmall: TextStyle(color: Color(0xFF2C3E50)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00D4FF),
        side: const BorderSide(color: Color(0xFF00D4FF)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Color(0xFF2C3E50)),
      hintStyle: TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFF00D4FF)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.grey,
      thickness: 1,
    ),
    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w600),
      subtitleTextStyle: TextStyle(color: Colors.grey, fontSize: 12),
    ),
  );
}
