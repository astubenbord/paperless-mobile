import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n.dart';

class HintCard extends StatelessWidget {
  final String hintText;
  final double elevation;
  final VoidCallback onHintAcknowledged;
  final bool show;
  const HintCard({
    super.key,
    required this.hintText,
    required this.onHintAcknowledged,
    this.elevation = 1,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      sizeCurve: Curves.elasticOut,
      crossFadeState:
          show ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      secondChild: const SizedBox.shrink(),
      duration: const Duration(milliseconds: 500),
      firstChild: Card(
        elevation: elevation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.tips_and_updates_outlined,
              color: Theme.of(context).hintColor,
            ).padded(),
            Align(
              alignment: Alignment.center,
              child: Text(
                hintText,
                softWrap: true,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                child: Text(S.of(context).genericAcknowledgeLabel),
                onPressed: onHintAcknowledged,
              ),
            ),
          ],
        ).padded(),
      ).padded(),
    );
  }
}
