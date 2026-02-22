import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/widgets/global_settings_builder.dart';

class DisableAnimationsSetting extends StatelessWidget {
  const DisableAnimationsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(builder: (context, settings) {
      return SwitchListTile(
        value: settings.disableAnimations,
        title: Text('Disable animations'),
        subtitle: Text('Disables page transitions and most animations.'
            ' Temporary workaround until system accessibility settings can be used.'),
        onChanged: (val) async {
          settings.disableAnimations = val;
          await settings.save();
        },
      );
    });
  }
}
