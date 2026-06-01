import 'package:flutter/material.dart';
import 'package:paperless_mobile/features/scanner/models/debug_stage.dart';

class DebugStageSwitcher extends StatelessWidget {
  final DebugStage value;
  final ValueChanged<DebugStage> onChanged;

  const DebugStageSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _labels = {
    DebugStage.none: 'Off',
    DebugStage.grayscale: 'Gray',
    DebugStage.blurred: 'Blur',
    DebugStage.canny: 'Canny',
    DebugStage.morphClosed: 'Morph',
    DebugStage.contours: 'Contours',
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<DebugStage>(
            value: value,
            dropdownColor: Colors.black87,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            iconEnabledColor: Colors.white,
            isDense: true,
            items: DebugStage.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(_labels[s] ?? s.name),
                  ),
                )
                .toList(),
            onChanged: (s) {
              if (s != null) onChanged(s);
            },
          ),
        ),
      ),
    );
  }
}
