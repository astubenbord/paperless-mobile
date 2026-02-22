import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_ce/hive.dart';
import 'package:paperless_mobile/core/database/hive/hive_extensions.dart';
import 'package:paperless_mobile/core/widgets/global_settings_builder.dart';

extension AccessibilityAwareAnimationDurationExtension on Duration {
  Duration accessible() {
    bool shouldDisableAnimations = WidgetsBinding.instance.disableAnimations ||
        Hive.globalSettings.disableAnimations;
    // print(shouldDisableAnimations);
    if (shouldDisableAnimations) {
      return 0.seconds;
    }
    return this;
  }
}

extension AccessibleHero on Hero {
  Widget accessible() {
    return GlobalSettingsBuilder(
      builder: (context, settings) {
        return HeroMode(
          enabled: WidgetsBinding.instance.disableAnimations ||
              !settings.disableAnimations,
          child: this,
        );
      },
    );
  }
}

class _AccessibilityAwareObserverWidget extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    AccessibilityFeatures accessibilityFeatures,
  ) accessibilityAwareBuilder;
  const _AccessibilityAwareObserverWidget({
    required this.accessibilityAwareBuilder,
  });

  @override
  State<_AccessibilityAwareObserverWidget> createState() =>
      _AccessibilityAwareObserverWidgetState();
}

class _AccessibilityAwareObserverWidgetState
    extends State<_AccessibilityAwareObserverWidget>
    with WidgetsBindingObserver {
  late final AccessibilityFeatures _accessibilityFeatures;

  @override
  void initState() {
    super.initState();
    _accessibilityFeatures = WidgetsBinding.instance.accessibilityFeatures;
  }

  @override
  void didChangeAccessibilityFeatures() {
    super.didChangeAccessibilityFeatures();
    setState(() {
      _accessibilityFeatures = WidgetsBinding.instance.accessibilityFeatures;
    });
    // Accessibility features changed - no action needed.
  }

  @override
  Widget build(BuildContext context) {
    return widget.accessibilityAwareBuilder(
      context,
      _accessibilityFeatures,
    );
  }
}
