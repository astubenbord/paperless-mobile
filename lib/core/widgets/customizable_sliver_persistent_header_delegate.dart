import 'package:flutter/material.dart';

class CustomizableSliverPersistentHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  @override
  final double minExtent;
  @override
  final double maxExtent;
  final Widget child;

  CustomizableSliverPersistentHeaderDelegate({
    required this.child,
    required this.minExtent,
    required this.maxExtent,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(CustomizableSliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
