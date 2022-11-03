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
        textScaleFactor: textScaleFactor,
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
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      style: TextStyle(overflow: overflow),
    );
  }

  List<TextSpan> _buildChildren(BuildContext context) {
    List<TextSpan> _spans = [];
    int _start = 0;

    String _text = caseSensitive ? text : text.toLowerCase();
    List<String> _highlights = caseSensitive
        ? highlights
        : highlights.map((e) => e.toLowerCase()).toList();

    while (true) {
      Map<int, String> _highlightsMap = {}; //key (index), value (highlight).

      for (final h in _highlights) {
        final idx = _text.indexOf(h, _start);
        if (idx >= 0) {
          _highlightsMap.putIfAbsent(_text.indexOf(h, _start), () => h);
        }
      }

      if (_highlightsMap.isNotEmpty) {
        int _currentIndex = _highlightsMap.keys.reduce(min);
        String _currentHighlight = text.substring(
          _currentIndex,
          _currentIndex + _highlightsMap[_currentIndex]!.length,
        );

        if (_currentIndex == _start) {
          _spans.add(_highlightSpan(_currentHighlight));
          _start += _currentHighlight.length;
        } else {
          _spans
              .add(_normalSpan(text.substring(_start, _currentIndex), context));
          _spans.add(_highlightSpan(_currentHighlight));
          _start = _currentIndex + _currentHighlight.length;
        }
      } else {
        _spans.add(_normalSpan(text.substring(_start, text.length), context));
        break;
      }
    }
    return _spans;
  }

  TextSpan _highlightSpan(String value) {
    return TextSpan(
      text: value,
      style: style?.copyWith(
        backgroundColor: color,
      ),
    );
  }

  TextSpan _normalSpan(String value, BuildContext context) {
    return TextSpan(
      text: value,
      style: style ?? Theme.of(context).textTheme.bodyText2,
    );
  }
}
