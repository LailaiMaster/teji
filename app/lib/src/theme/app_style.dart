import 'package:flutter/material.dart';

const bg = Color(0xFF080B12);
const panel = Color(0xFF111722);
const panel2 = Color(0xFF171F2E);
const line = Color(0xFF263245);
const text = Color(0xFFF4F7FB);
const muted = Color(0xFF8A95A8);
const cyan = Color(0xFF57D7FF);
const blue = Color(0xFF4E8DFF);
const green = Color(0xFF60E28C);
const amber = Color(0xFFFFC857);
const purple = Color(0xFF9C7CFF);
const red = Color(0xFFFF6B6B);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      surface: panel,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: text,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: TextStyle(
        color: text,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: text,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(
        color: muted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
