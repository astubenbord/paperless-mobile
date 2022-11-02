import 'package:flutter/material.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onNavigationChanged;

  const BottomNavBar({Key? key, required this.selectedIndex, required this.onNavigationChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      elevation: 4.0,
      onDestinationSelected: onNavigationChanged,
      selectedIndex: selectedIndex,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.description),
          label: S.of(context).bottomNavDocumentsPageLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.document_scanner),
          label: S.of(context).bottomNavScannerPageLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.sell),
          label: S.of(context).bottomNavLabelsPageLabel,
        ),
      ],
    );
  }
}
