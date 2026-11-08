import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ResolutionSwitcher extends StatelessWidget {
  final ResolutionPreset value;
  final ValueChanged<ResolutionPreset> onChanged;

  const ResolutionSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _labels = {
    ResolutionPreset.low: 'Low',
    ResolutionPreset.medium: 'Med',
    ResolutionPreset.high: 'High',
    ResolutionPreset.veryHigh: 'V.High',
    ResolutionPreset.ultraHigh: 'Ultra',
    ResolutionPreset.max: 'Max',
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ResolutionPreset>(
            value: value,
            dropdownColor: Colors.black87,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            iconEnabledColor: Colors.white,
            isDense: true,
            items: ResolutionPreset.values
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(_labels[r] ?? r.name),
                  ),
                )
                .toList(),
            onChanged: (r) {
              if (r != null) onChanged(r);
            },
          ),
        ),
      ),
    );
  }
}
