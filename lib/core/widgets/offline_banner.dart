import 'package:flutter/material.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class OfflineBanner extends StatelessWidget with PreferredSizeWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.cloud_off,
              size: 24,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          Text(
            S.of(context).genericMessageOfflineText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(24);
}
