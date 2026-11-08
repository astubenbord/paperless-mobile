import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/extensions/context_extensions.dart';
import 'package:paperless_mobile/core/store/bloc/global_settings_builder.dart';
import 'package:paperless_mobile/core/store/slices/global_settings.dart';
import 'package:paperless_mobile/features/scanner/models/scanner_parameters.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class AdvancedScannerSettingsPage extends StatefulWidget {
  const AdvancedScannerSettingsPage({super.key});

  @override
  State<AdvancedScannerSettingsPage> createState() =>
      _AdvancedScannerSettingsPageState();
}

class _AdvancedScannerSettingsPageState
    extends State<AdvancedScannerSettingsPage> {
  // We keep local state during slider drag for smooth rendering,
  // then persist on drag end (`onChangeEnd`).
  ScannerParameters? _localParams;

  void _initLocalParams(ScannerParameters current) {
    _localParams ??= current;
  }

  void _updateParam(ScannerParameters Function(ScannerParameters) updater) {
    setState(() {
      if (_localParams != null) {
        _localParams = updater(_localParams!);
      }
    });
  }

  void _persistParams() {
    if (_localParams != null) {
      context.localStore.updateGlobalSettings(
        (state) => state.copyWith(scannerParameters: _localParams!),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(
      builder: (context, settings) {
        _initLocalParams(settings.scannerParameters);
        final current = _localParams!;

        return Scaffold(
          appBar: AppBar(
            title: Text(S.of(context)!.scannerParameterAdvancedScannerSettings),
            actions: [
              IconButton(
                icon: const Icon(Icons.restart_alt),
                tooltip: S.of(context)!.scannerParameterRestoreDefaults,
                onPressed: () {
                  setState(() {
                    _localParams = const ScannerParameters();
                  });
                  _persistParams();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        S
                            .of(context)!
                            .scannerParameterDefaultScannerParametersRestored,
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _buildSectionHeader(
                S.of(context)!.scannerParameterCameraSettings.toUpperCase(),
              ),
              (() {
                final deviates = current.resolutionPreset != 'max';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.of(context)!.scannerParameterResolutionPreset,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (deviates) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.restart_alt, size: 20),
                              tooltip: S
                                  .of(context)!
                                  .scannerParameterResetToDefaultValue('MAX'),
                              onPressed: () {
                                _updateParam(
                                  (p) => p.copyWith(resolutionPreset: 'max'),
                                );
                                _persistParams();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S
                            .of(context)!
                            .scannerParameterCameraSettingsResolutionPresetDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey(current.resolutionPreset),
                        initialValue: current.resolutionPreset,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: ResolutionPreset.values.map((preset) {
                          return DropdownMenuItem<String>(
                            value: preset.name,
                            child: Text(preset.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _updateParam(
                              (p) => p.copyWith(resolutionPreset: val),
                            );
                            _persistParams();
                          }
                        },
                      ),
                    ],
                  ),
                );
              })(),
              _buildSectionHeader(
                S
                    .of(context)!
                    .scannerParameterAutoCaptureParameters
                    .toUpperCase(),
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('stableDurationMs'),
                label: S.of(context)!.scannerParameterStableDuration,
                description: S
                    .of(context)!
                    .scannerParameterStableDurationDescription,
                value: current.stableDurationMs.toDouble(),
                min: 100,
                max: 3000,
                divisions: 29,
                defaultValue: 1000,
                unitSuffix: ' ms',
                isInteger: true,
                onChanged: (val) {
                  _updateParam(
                    (p) => p.copyWith(stableDurationMs: val.round()),
                  );
                },
                onPersist: _persistParams,
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('preStableDelayMs'),
                label: S.of(context)!.scannerParameterPreStableDelay,
                description: S
                    .of(context)!
                    .scannerParameterPreStableDelayDescription,
                value: current.preStableDelayMs.toDouble(),
                min: 0,
                max: 3000,
                divisions: 30,
                defaultValue: 1000,
                unitSuffix: ' ms',
                isInteger: true,
                onChanged: (val) {
                  _updateParam(
                    (p) => p.copyWith(preStableDelayMs: val.round()),
                  );
                },
                onPersist: _persistParams,
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('distanceThreshold'),
                label: S.of(context)!.scannerParameterDistanceThreshold,
                description: S
                    .of(context)!
                    .scannerParameterDistanceThresholdDescription,
                value: current.distanceThreshold,
                min: 5.0,
                max: 150.0,
                divisions: 29,
                defaultValue: 50.0,
                unitSuffix: ' px',
                onChanged: (val) {
                  _updateParam((p) => p.copyWith(distanceThreshold: val));
                },
                onPersist: _persistParams,
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('minConsecutiveSimilarFrames'),
                label: S
                    .of(context)!
                    .scannerParameterMinConsecutiveSimilarFrames,
                description: S
                    .of(context)!
                    .scannerParameterMinConsecutiveSimilarFramesDescription,
                value: current.minConsecutiveSimilarFrames.toDouble(),
                min: 2,
                max: 10,
                divisions: 8,
                defaultValue: 3,
                isInteger: true,
                onChanged: (val) {
                  _updateParam(
                    (p) => p.copyWith(minConsecutiveSimilarFrames: val.round()),
                  );
                },
                onPersist: _persistParams,
              ),
              _buildSectionHeader(
                S
                    .of(context)!
                    .scannerParameterEdgeDetectionParameters
                    .toUpperCase(),
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('resizeThreshold'),
                label: S.of(context)!.scannerParameterResizeThreshold,
                description: S
                    .of(context)!
                    .scannerParameterResizeThresholdDescription,
                value: current.resizeThreshold.toDouble(),
                min: 100,
                max: 1200,
                divisions: 22,
                defaultValue: 320,
                unitSuffix: ' px',
                isInteger: true,
                onChanged: (val) {
                  _updateParam((p) => p.copyWith(resizeThreshold: val.round()));
                },
                onPersist: _persistParams,
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('borderSize'),
                label: S.of(context)!.scannerParameterBorderPaddingSize,
                description: S
                    .of(context)!
                    .scannerParameterBorderPaddingSizeDescription,
                value: current.borderSize.toDouble(),
                min: 0,
                max: 50,
                divisions: 50,
                defaultValue: 10,
                unitSuffix: ' px',
                isInteger: true,
                onChanged: (val) {
                  _updateParam((p) => p.copyWith(borderSize: val.round()));
                },
                onPersist: _persistParams,
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('medianBlurKernel'),
                label: S.of(context)!.scannerParameterMedianBlurKernel,
                description: S
                    .of(context)!
                    .scannerParameterMedianBlurKernelDescription,
                value: current.medianBlurKernel.toDouble(),
                min: 1,
                max: 15,
                divisions: 7,
                defaultValue: 7,
                isInteger: true,
                isOddInteger: true,
                onChanged: (val) {
                  int intVal = val.round();
                  if (intVal % 2 == 0) {
                    intVal = (intVal + 1).clamp(1, 15);
                  }
                  _updateParam((p) => p.copyWith(medianBlurKernel: intVal));
                },
                onPersist: _persistParams,
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('approxEpsilonFactor'),
                label: S.of(context)!.scannerParameterPolygonEpsilonFactor,
                description: S
                    .of(context)!
                    .scannerParameterPolygonEpsilonFactorDescription,
                value: current.approxEpsilonFactor,
                min: 0.005,
                max: 0.05,
                divisions: 45,
                defaultValue: 0.018,
                decimalPlaces: 3,
                onChanged: (val) {
                  _updateParam((p) => p.copyWith(approxEpsilonFactor: val));
                },
                onPersist: _persistParams,
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('morphologyKernel'),
                label: S.of(context)!.scannerParameterMorphologyKernel,
                description: S
                    .of(context)!
                    .scannerParameterMorphologyKernelDescription,
                value: current.morphologyKernel.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                defaultValue: 3,
                isInteger: true,
                onChanged: (val) {
                  _updateParam(
                    (p) => p.copyWith(morphologyKernel: val.round()),
                  );
                },
                onPersist: _persistParams,
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('dilateKernel'),
                label: S.of(context)!.scannerParameterDilateKernel,
                description: S
                    .of(context)!
                    .scannerParameterDilateKernelDescription,
                value: current.dilateKernel.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                defaultValue: 2,
                isInteger: true,
                onChanged: (val) {
                  _updateParam((p) => p.copyWith(dilateKernel: val.round()));
                },
                onPersist: _persistParams,
              ),
              _ScannerParameterSliderTile(
                key: const ValueKey('minAreaFactor'),
                label: S.of(context)!.scannerParameterMinimumAreaFactor,
                description: S
                    .of(context)!
                    .scannerParameterMinimumAreaFactorDescription,
                value: current.minAreaFactor,
                min: 0.01,
                max: 0.50,
                divisions: 49,
                defaultValue: 0.03,
                unitSuffix: ' %',
                isPercent: true,
                onChanged: (val) {
                  _updateParam((p) => p.copyWith(minAreaFactor: val));
                },
                onPersist: _persistParams,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScannerParameterSliderTile extends StatefulWidget {
  final String label;
  final String description;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String unitSuffix;
  final bool isPercent;
  final bool isInteger;
  final bool isOddInteger;
  final int decimalPlaces;
  final double defaultValue;
  final ValueChanged<double> onChanged;
  final VoidCallback onPersist;

  const _ScannerParameterSliderTile({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.unitSuffix = '',
    this.isPercent = false,
    this.isInteger = false,
    this.isOddInteger = false,
    this.decimalPlaces = 1,
    required this.defaultValue,
    required this.onChanged,
    required this.onPersist,
  });

  @override
  State<_ScannerParameterSliderTile> createState() =>
      _ScannerParameterSliderTileState();
}

class _ScannerParameterSliderTileState
    extends State<_ScannerParameterSliderTile> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _updateTextFromValue(widget.value);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_ScannerParameterSliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _updateTextFromValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _updateTextFromValue(double val) {
    if (widget.isPercent) {
      _controller.text = (val * 100).toStringAsFixed(widget.decimalPlaces);
    } else if (widget.isInteger || widget.isOddInteger) {
      _controller.text = val.round().toString();
    } else {
      _controller.text = val.toStringAsFixed(widget.decimalPlaces);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _applyTextAndNotify();
    }
  }

  void _applyTextAndNotify() {
    final text = _controller.text;
    double? val = double.tryParse(text);
    if (val != null) {
      if (widget.isPercent) {
        val = val / 100.0;
      }
      if (widget.isInteger || widget.isOddInteger) {
        int intVal = val.round();
        if (widget.isOddInteger) {
          if (intVal % 2 == 0) {
            intVal = (intVal + 1).clamp(widget.min.round(), widget.max.round());
          }
        }
        val = intVal.toDouble();
      }
      val = val.clamp(widget.min, widget.max);
      widget.onChanged(val);
      widget.onPersist();
      _updateTextFromValue(val);
    } else {
      _updateTextFromValue(widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviates = widget.value != widget.defaultValue;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                child: deviates
                    ? IconButton(
                        icon: const Icon(Icons.restart_alt, size: 20),
                        tooltip: S
                            .of(context)!
                            .scannerParameterResetToDefaultValue(
                              widget.isPercent
                                  ? '${(widget.defaultValue * 100).toStringAsFixed(widget.decimalPlaces)} %'
                                  : widget.isInteger || widget.isOddInteger
                                  ? widget.defaultValue.round().toString()
                                  : widget.defaultValue.toStringAsFixed(
                                      widget.decimalPlaces,
                                    ),
                            ),
                        onPressed: () {
                          widget.onChanged(widget.defaultValue);
                          widget.onPersist();
                          _updateTextFromValue(widget.defaultValue);
                          setState(() {});
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                height: 38,
                child: TextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    suffixText: widget.unitSuffix.isNotEmpty
                        ? widget.unitSuffix.trim()
                        : null,
                    suffixStyle: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  onFieldSubmitted: (_) => _applyTextAndNotify(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider.adaptive(
                  value: widget.value.clamp(widget.min, widget.max),
                  min: widget.min,
                  max: widget.max,
                  divisions: widget.divisions,
                  onChanged: (val) {
                    widget.onChanged(val);
                    _updateTextFromValue(val);
                  },
                  onChangeEnd: (val) {
                    widget.onPersist();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
