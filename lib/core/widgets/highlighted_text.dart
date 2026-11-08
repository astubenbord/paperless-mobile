import 'dart:math';

import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final List<String> highlights;
  final Color? color;
  final TextStyle? style;
  final bool caseSensitive;

  final TextAlign textAlign;
  final TextDirection? textDirection;
  final TextOverflow overflow;
  final double textScaleFactor;
  final int? maxLines;
  final StrutStyle? strutStyle;
  final TextWidthBasis textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlights,
    this.style,
    this.color = Colors.yellowAccent,
    this.caseSensitive = true,
    this.textAlign = TextAlign.start,
    this.textDirection = TextDirection.ltr,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty || highlights.isEmpty || highlights.contains('')) {
      return SelectableText.rich(
        _normalSpan(text, context),
        key: key,
        textAlign: textAlign,
        textDirection: textDirection,
        textScaler: TextScaler.linear(textScaleFactor),
        maxLines: maxLines,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        style: TextStyle(overflow: overflow),
      );
    }

    return SelectableText.rich(
      TextSpan(children: _buildChildren(context)),
      key: key,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: TextScaler.linear(textScaleFactor),
      maxLines: maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      style: TextStyle(overflow: overflow),
    );
  }

  List<TextSpan> _buildChildren(BuildContext context) {
    List<TextSpan> spans = [];
    int start = 0;

    String maybeLowerText = caseSensitive ? text : text.toLowerCase();
    List<String> maybeLowerHighlights = caseSensitive
        ? highlights
        : highlights.map((e) => e.toLowerCase()).toList();

    while (true) {
      Map<int, String> highlightsMap = {}; //key (index), value (highlight).

      for (final h in maybeLowerHighlights) {
        final idx = maybeLowerText.indexOf(h, start);
        if (idx >= 0) {
          highlightsMap.putIfAbsent(maybeLowerText.indexOf(h, start), () => h);
        }
      }

      if (highlightsMap.isNotEmpty) {
        int currentIndex = highlightsMap.keys.reduce(min);
        String currentHighlight = text.substring(
          currentIndex,
          currentIndex + highlightsMap[currentIndex]!.length,
        );

        if (currentIndex == start) {
          spans.add(_highlightSpan(currentHighlight));
          start += currentHighlight.length;
        } else {
          spans.add(_normalSpan(text.substring(start, currentIndex), context));
          spans.add(_highlightSpan(currentHighlight));
          start = currentIndex + currentHighlight.length;
        }
      } else {
        spans.add(_normalSpan(text.substring(start, text.length), context));
        break;
      }
    }
    return spans;
  }

  TextSpan _highlightSpan(String value) {
    return TextSpan(
      text: value,
      style: style?.copyWith(backgroundColor: color),
    );
  }

  TextSpan _normalSpan(String value, BuildContext context) {
    return TextSpan(
      text: value,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}
