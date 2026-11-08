import 'package:flutter/material.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class ScannerControlTray extends StatelessWidget {
  final bool autoCaptureEnabled;
  final ValueChanged<bool> onAutoCaptureChanged;

  const ScannerControlTray({
    super.key,
    required this.autoCaptureEnabled,
    required this.onAutoCaptureChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Bubble overlay sliding animation
              AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                alignment: autoCaptureEnabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Option labels
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (autoCaptureEnabled) {
                          onAutoCaptureChanged(false);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 120),
                          style: TextStyle(
                            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: autoCaptureEnabled
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.black,
                          ),
                          child: Text(
                            S.of(context)?.livePreview ?? 'Live Preview',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!autoCaptureEnabled) {
                          onAutoCaptureChanged(true);
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 120),
                          style: TextStyle(
                            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: autoCaptureEnabled
                                ? Colors.black
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                          child: Text(
                            S.of(context)?.autoCapture ?? 'Auto Capture',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
