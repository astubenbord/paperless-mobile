import 'package:flutter/material.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class OfflineBanner extends StatelessWidget with PreferredSizeWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).disabledColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              Icons.cloud_off,
              size: 24,
            ),
          ),
          Text(S.of(context).genericMessageOfflineText),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(24);
}
