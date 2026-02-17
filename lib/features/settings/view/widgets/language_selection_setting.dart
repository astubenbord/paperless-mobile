import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/global_settings_builder.dart';
import 'package:paperless_mobile/features/settings/view/widgets/radio_settings_dialog.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class LanguageSelectionSetting extends StatefulWidget {
  const LanguageSelectionSetting({super.key});

  @override
  State<LanguageSelectionSetting> createState() =>
      _LanguageSelectionSettingState();
}

class _LanguageSelectionSettingState extends State<LanguageSelectionSetting> {
  static const _languageOptions = {
    'en': LanguageOption('English (US)', true),
    'en_GB': LanguageOption('English (GB)', true),
    'de': LanguageOption('Deutsch', true),
    'es': LanguageOption("Español", true),
    'fr': LanguageOption('Français', true),
    'cs': LanguageOption('Česky', true),
    'tr': LanguageOption('Türkçe', true),
    'pl': LanguageOption('Polska', true),
    'ca': LanguageOption('Català', true),
    'ru': LanguageOption('Русский', true),
    'it': LanguageOption('Italiano', true),
  };

  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(
      builder: (context, settings) {
        return ListTile(
          title: Text(S.of(context)!.language),
          subtitle:
              Text(_languageOptions[settings.preferredLocaleSubtag]!.name),
          onTap: () => showDialog<String>(
            context: context,
            builder: (_) => RadioSettingsDialog<String>(
              // footer: const Text(
              //   "* Not fully translated yet. Some words may be displayed in English!",
              // ),
              titleText: S.of(context)!.language,
              options: [
                for (var language in _languageOptions.entries)
                  RadioOption(
                    value: language.key,
                    label: language.value.name +
                        (language.value.isComplete ? '' : '*'),
                  ),
              ],
              initialValue: settings.preferredLocaleSubtag,
            ),
          ).then((value) {
            if (value != null) {
              settings.preferredLocaleSubtag = value;
              settings.save();
            }
          }),
        );
      },
    );
  }
}

class LanguageOption {
  final String name;
  final bool isComplete;

  const LanguageOption(this.name, this.isComplete);
}
