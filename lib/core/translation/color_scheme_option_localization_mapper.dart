import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/settings/model/color_scheme_option.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

String translateColorSchemeOption(
  BuildContext context,
  ColorSchemeOption option,
) {
  switch (option) {
    case ColorSchemeOption.classic:
      return S.of(context)!.classicColorScheme;
    case ColorSchemeOption.dynamic:
      return S.of(context)!.dynamicColorScheme;
  }
}
