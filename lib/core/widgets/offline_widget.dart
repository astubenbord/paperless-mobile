import 'package:flutter/material.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class OfflineWidget extends StatelessWidget {
  const OfflineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off,
              color: Theme.of(context).disabledColor,
              size: (Theme.of(context).iconTheme.size ?? 24) * 3),
          Text(
            S.of(context).offlineWidgetText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
