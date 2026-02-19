import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paperless_mobile/core/model/color_scheme_option.dart';

const _classicThemeColorSeed = Color(0xFF2E7D32);

const _defaultListTileTheme = ListTileThemeData(
  tileColor: Colors.transparent,
);

final _defaultCardTheme = CardThemeData(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);

final _defaultInputDecorationTheme = InputDecorationTheme(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  filled: true,
  contentPadding: const EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 16.0,
  ),
);

ThemeData buildTheme({
  required Brightness brightness,
  required ColorSchemeOption preferredColorScheme,
  ColorScheme? dynamicScheme,
}) {
  final classicScheme = ColorScheme.fromSeed(
    seedColor: _classicThemeColorSeed,
    brightness: brightness,
  );
  late ColorScheme colorScheme;
  switch (preferredColorScheme) {
    case ColorSchemeOption.classic:
      colorScheme = classicScheme;
      break;
    case ColorSchemeOption.dynamic:
      colorScheme = dynamicScheme ?? classicScheme;
      break;
  }
  return ThemeData.from(
    colorScheme: colorScheme.harmonized(),
    useMaterial3: true,
  ).copyWith(
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      height: 64,
    ),
    inputDecorationTheme: _defaultInputDecorationTheme,
    listTileTheme: _defaultListTileTheme,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
    ),
    cardTheme: _defaultCardTheme.copyWith(
      elevation: 0.5,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      checkmarkColor: colorScheme.onSurfaceVariant,
      deleteIconColor: colorScheme.onSurfaceVariant,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

SystemUiOverlayStyle buildOverlayStyle(
  ThemeData theme, {
  Color? systemNavigationBarColor,
}) {
  final color = systemNavigationBarColor ??
      ElevationOverlay.applySurfaceTint(
        theme.colorScheme.surface,
        theme.colorScheme.surfaceTint,
        3,
      );
  return switch (theme.brightness) {
    Brightness.light => SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: color,
        systemNavigationBarDividerColor: color,
        statusBarColor: theme.colorScheme.surface,
        // statusBarColor: theme.colorScheme.background,
        // systemNavigationBarDividerColor: theme.colorScheme.surface,
      ),
    Brightness.dark => SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: color,
        systemNavigationBarDividerColor: color,
        statusBarColor: theme.colorScheme.surface,
        // statusBarColor: theme.colorScheme.background,
        // systemNavigationBarDividerColor: theme.colorScheme.surface,
      ),
  };
}
