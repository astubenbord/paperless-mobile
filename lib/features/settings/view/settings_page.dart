import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_mobile/features/settings/bloc/application_settings_cubit.dart';
import 'package:paperless_mobile/features/settings/view/pages/application_settings_page.dart';
import 'package:paperless_mobile/features/settings/view/pages/security_settings_page.dart';
import 'package:paperless_mobile/features/settings/view/pages/storage_settings_page.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).appDrawerSettingsLabel),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(S.of(context).settingsPageApplicationSettingsLabel),
            subtitle: Text(
                S.of(context).settingsPageApplicationSettingsDescriptionText),
            onTap: () => _goto(const ApplicationSettingsPage(), context),
          ),
          ListTile(
            title: Text(S.of(context).settingsPageSecuritySettingsLabel),
            subtitle:
                Text(S.of(context).settingsPageSecuritySettingsDescriptionText),
            onTap: () => _goto(const SecuritySettingsPage(), context),
          ),
          ListTile(
            title: Text(S.of(context).settingsPageStorageSettingsLabel),
            subtitle:
                Text(S.of(context).settingsPageStorageSettingsDescriptionText),
            onTap: () => _goto(const StorageSettingsPage(), context),
          ),
        ],
      ),
    );
  }

  void _goto(Widget page, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctxt) => BlocProvider.value(
            value: BlocProvider.of<ApplicationSettingsCubit>(context),
            child: page),
        maintainState: true,
      ),
    );
  }
}
