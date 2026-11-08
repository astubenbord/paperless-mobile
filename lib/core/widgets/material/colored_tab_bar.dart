import 'package:flutter/material.dart';

class ColoredTabBar extends StatelessWidget implements PreferredSizeWidget {
  const ColoredTabBar({super.key, this.color, required this.tabBar});

  final TabBar tabBar;
  final Color? color;

  @override
  Size get preferredSize => tabBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color ?? Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }
}
