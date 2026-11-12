import 'package:flutter/material.dart';

/// Angkor Bronze & Deep Teakwood palette (taken from the design export).
class C {
  static const bg = Color(0xFF101418);
  static const lowest = Color(0xFF0B0F12);
  static const surfaceLow = Color(0xFF181C20);
  static const surface = Color(0xFF1C2024);
  static const high = Color(0xFF262A2F);
  static const highest = Color(0xFF313539);
  static const primary = Color(0xFFF2BE71);
  static const primaryContainer = Color(0xFFD4A359);
  static const onPrimary = Color(0xFF442B00);
  static const secondary = Color(0xFF6FDBA8);
  static const secondaryContainer = Color(0xFF32A375);
  static const tertiary = Color(0xFFFFB3AE);
  static const error = Color(0xFFFFB4AB);
  static const onSurface = Color(0xFFE0E3E8);
  static const onVar = Color(0xFFD3C4B3);
  static const outline = Color(0xFF9C8F7F);
  static const outlineVar = Color(0xFF4F4538);
  static const woodDark = Color(0xFF7A5230);
  static const woodLight = Color(0xFFEADBCA);
}

TextStyle serif(double size, {Color color = C.onSurface, FontWeight w = FontWeight.w600}) =>
    TextStyle(fontFamily: 'serif', fontSize: size, color: color, fontWeight: w, height: 1.2);

TextStyle mono(double size, {Color color = C.onSurface, FontWeight w = FontWeight.w700}) =>
    TextStyle(fontFamily: 'monospace', fontSize: size, color: color, fontWeight: w, letterSpacing: .4);

TextStyle body(double size, {Color color = C.onVar, FontWeight w = FontWeight.w400}) =>
    TextStyle(fontSize: size, color: color, fontWeight: w, height: 1.4);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: C.bg,
      colorScheme: const ColorScheme.dark(
        primary: C.primary,
        onPrimary: C.onPrimary,
        secondary: C.secondary,
        surface: C.surface,
        error: C.error,
      ),
    );

BoxDecoration card({Color color = C.high, double radius = 14, Color? border}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border == null ? null : Border.all(color: border),
    );
