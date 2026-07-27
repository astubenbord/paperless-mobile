import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/store/bloc/global_settings_builder.dart';
import 'package:paperless_mobile/features/settings/model/scanner_implementation.dart';
import 'package:paperless_mobile/features/settings/view/widgets/radio_settings_dialog.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class ScannerImplementationSetting extends StatelessWidget {
  const ScannerImplementationSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final localStore = context.localStore;
    return GlobalSettingsBuilder(
      builder: (context, settings) => ListTile(
        title: Text(S.of(context)!.scannerEngine),
        subtitle: Text(_label(context, settings.preferredScanner)),
        onTap: () async {
          final selected = await showDialog<ScannerImplementation>(
            useRootNavigator: false,
            context: context,
            builder: (context) => RadioSettingsDialog<ScannerImplementation>(
              titleText: S.of(context)!.scannerEngine,
              options: [
                RadioOption(
                  value: ScannerImplementation.edgeDetection,
                  label: _label(context, ScannerImplementation.edgeDetection),
                ),
                RadioOption(
                  value: ScannerImplementation.mlKit,
                  label: _label(context, ScannerImplementation.mlKit),
                ),
              ],
              initialValue: settings.preferredScanner,
            ),
          );
          if (selected != null) {
            localStore.updateGlobalSettings(
              (s) => s.copyWith(preferredScanner: selected),
            );
          }
        },
      ),
    );
  }

  String _label(BuildContext context, ScannerImplementation impl) {
    return switch (impl) {
      ScannerImplementation.edgeDetection =>
        S.of(context)!.scannerEngineEdgeDetection,
      ScannerImplementation.mlKit => S.of(context)!.scannerEngineMlKit,
    };
  }
}
