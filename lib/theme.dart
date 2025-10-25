import 'package:flutter/material.dart';

/// Centralized theme factory for the app.
/// Keeps existing visual styles intact while moving them into one place.
class AppTheme {
  AppTheme._();

  /// Seed color for ColorScheme.fromSeed when dynamic color is unavailable.
  static const Color seed = Color(0xFF6750A4);

  /// Build light and dark ThemeData from optional dynamic color schemes.
  static (ThemeData, ThemeData) fromDynamic(
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
  ) {
    final ColorScheme lightScheme =
        lightDynamic ?? ColorScheme.fromSeed(seedColor: seed);
    final ColorScheme darkScheme =
        darkDynamic ??
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

    return (
      ThemeData(
        colorScheme: lightScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.surfaceContainer,
          scrolledUnderElevation: 2.0,
          shadowColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: lightScheme.surfaceContainer,
          indicatorColor: lightScheme.secondaryContainer,
        ),
      ),
      ThemeData(
        colorScheme: darkScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.surfaceContainer,
          scrolledUnderElevation: 2.0,
          shadowColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkScheme.surfaceContainer,
          indicatorColor: darkScheme.secondaryContainer,
        ),
      ),
    );
  }
}
