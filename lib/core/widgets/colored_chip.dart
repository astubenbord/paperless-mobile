import 'package:flutter/material.dart';

///
/// Workaround class to change background color of chips without losing ripple effect.
/// Currently broken in flutter m3.
/// Applies only to light theme if [applyToDarkTheme] is not explicitly set to true.
///
class ColoredChipWrapper extends StatelessWidget {
  ////
  final Color? backgroundColor;
  final Widget child;
  final bool applyToDarkTheme;

  const ColoredChipWrapper({
    super.key,
    this.backgroundColor,
    required this.child,
    this.applyToDarkTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if ((brightness == Brightness.dark && applyToDarkTheme) ||
        brightness == Brightness.light) {
      return Theme(
        data: Theme.of(context).copyWith(
          canvasColor: backgroundColor ?? Colors.lightGreen[50]!,
        ),
        child: child,
      );
    }
    return child;
  }
}
