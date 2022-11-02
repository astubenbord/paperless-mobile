import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/settings/view/widgets/language_selection_setting.dart';
import 'package:paperless_mobile/features/settings/view/widgets/theme_mode_setting.dart';

class ApplicationSettingsPage extends StatelessWidget {
  const ApplicationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Application"),
      ),
      body: ListView(
        children: const [
          LanguageSelectionSetting(),
          ThemeModeSetting(),
        ],
      ),
    );
  }
}
