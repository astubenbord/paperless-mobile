import 'package:flutter/material.dart';

class TextPlaceholder extends StatelessWidget {
  final double length;
  final double fontSize;

  const TextPlaceholder({
    super.key,
    required this.length,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.white, width: length, height: fontSize);
  }
}
