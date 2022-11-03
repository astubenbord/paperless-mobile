import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/model/application_settings_state.dart';
import 'package:paperless_mobile/features/settings/view/widgets/radio_settings_dialog.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class LanguageSelectionSetting extends StatefulWidget {
  const LanguageSelectionSetting({super.key});

  @override
  State<LanguageSelectionSetting> createState() =>
      _LanguageSelectionSettingState();
}

class _LanguageSelectionSettingState extends State<LanguageSelectionSetting> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicationSettingsCubit, ApplicationSettingsState>(
      builder: (context, settings) {
        return ListTile(
          title: Text(S.of(context).settingsPageLanguageSettingLabel),
          subtitle: Text(_mapSubtagToLanguage(settings.preferredLocaleSubtag)),
          onTap: () => showDialog(
            context: context,
            builder: (_) => RadioSettingsDialog<String>(
              title: Text(S.of(context).settingsPageLanguageSettingLabel),
              options: [
                RadioOption(
                  value: 'en',
                  label: _mapSubtagToLanguage('en'),
                ),
                RadioOption(
                  value: 'de',
                  label: _mapSubtagToLanguage('de'),
                ),
              ],
              initialValue: BlocProvider.of<ApplicationSettingsCubit>(context)
                  .state
                  .preferredLocaleSubtag,
            ),
          ).then((value) => BlocProvider.of<ApplicationSettingsCubit>(context)
              .setLocale(value)),
        );
      },
    );
  }

  _mapSubtagToLanguage(String subtag) {
    switch (subtag) {
      case 'en':
        return "English";
      case 'de':
        return "Deutsch";
      default:
        return "English";
    }
  }
}
