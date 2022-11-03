import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class ElevatedConfirmationButton extends StatefulWidget {
  factory ElevatedConfirmationButton.icon(BuildContext context,
      {required void Function() onPressed,
      required Icon icon,
      required Widget label}) {
    final double scale = MediaQuery.maybeOf(context)?.textScaleFactor ?? 1;
    final double gap =
        scale <= 1 ? 8 : lerpDouble(8, 4, math.min(scale - 1, 1))!;
    return ElevatedConfirmationButton(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[icon, SizedBox(width: gap), Flexible(child: label)],
      ),
      onPressed: onPressed,
    );
  }

  const ElevatedConfirmationButton({
    Key? key,
    this.color,
    required this.onPressed,
    required this.child,
    this.confirmWidget = const Text("Confirm?"),
  }) : super(key: key);

  final Color? color;
  final void Function()? onPressed;
  final Widget child;
  final Widget confirmWidget;
  @override
  State<ElevatedConfirmationButton> createState() =>
      _ElevatedConfirmationButtonState();
}

class _ElevatedConfirmationButtonState
    extends State<ElevatedConfirmationButton> {
  bool _clickedOnce = false;
  double? _originalWidth;
  final GlobalKey _originalWidgetKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    if (!_clickedOnce) {
      return ElevatedButton(
        key: _originalWidgetKey,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(widget.color),
        ),
        onPressed: () {
          _originalWidth = (_originalWidgetKey.currentContext
                  ?.findRenderObject() as RenderBox)
              .size
              .width;
          setState(() => _clickedOnce = true);
        },
        child: widget.child,
      );
    } else {
      return Builder(builder: (context) {
        return SizedBox(
          width: _originalWidth,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(widget.color),
            ),
            onPressed: widget.onPressed,
            child: widget.confirmWidget,
          ),
        );
      });
    }
  }
}
