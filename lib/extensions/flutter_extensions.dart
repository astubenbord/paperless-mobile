import 'package:flutter/widgets.dart';

extension WidgetPadding on Widget {
  Widget padded([EdgeInsetsGeometry value = const EdgeInsets.all(8)]) {
    return Padding(
      padding: value,
      child: this,
    );
  }
}

extension WidgetsPadding on List<Widget> {
  List<Widget> padded([EdgeInsetsGeometry value = const EdgeInsets.all(8)]) {
    return map((child) => Padding(
          padding: value,
          child: child,
        )).toList();
  }
}
