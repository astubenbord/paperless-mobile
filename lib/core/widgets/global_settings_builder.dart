import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:paperless_mobile/core/database/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';

class GlobalSettingsBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, GlobalSettings settings) builder;
  const GlobalSettingsBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<GlobalSettings>(HiveBoxes.globalSettings).listenable(),
      builder: (context, value, _) {
        final settings = value.getValue()!;
        return builder(context, settings);
      },
    );
  }
}
