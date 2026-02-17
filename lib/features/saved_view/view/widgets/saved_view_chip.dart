import 'dart:math';

import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/accessibility/accessibility_utils.dart';
import 'package:paperless_mobile/core/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/routing/routes/saved_views_route.dart';

class SavedViewChip extends StatefulWidget {
  final SavedView view;
  final void Function(SavedView view) onViewSelected;
  final void Function(SavedView view) onUpdateView;
  final void Function(SavedView view) onDeleteView;
  final bool selected;
  final bool hasChanged;

  const SavedViewChip({
    super.key,
    required this.view,
    required this.onViewSelected,
    required this.selected,
    required this.hasChanged,
    required this.onUpdateView,
    required this.onDeleteView,
  });

  @override
  State<SavedViewChip> createState() => _SavedViewChipState();
}

class _SavedViewChipState extends State<SavedViewChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200).accessible(),
    );
    _animation = _animationController.drive(Tween(begin: 0, end: 1));
  }

  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    final effectiveBackgroundColor = widget.selected
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest ;
    final effectiveForegroundColor = widget.selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    final expandedChild = Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.edit,
            color: effectiveForegroundColor,
          ),
          onPressed: () {
            EditSavedViewRoute($extra: widget.view).push(context);
          },
        ),
        IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.delete,
            color: colorScheme.error,
          ),
          onPressed: () async {
            widget.onDeleteView(widget.view);
          },
        ),
      ],
    );

    return Material(
      color: effectiveBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outline,
        ),
      ),
      child: InkWell(
        enableFeedback: true,
        borderRadius: BorderRadius.circular(8),
        onTap: () => widget.onViewSelected(widget.view),
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildCheckmark(effectiveForegroundColor),
                  _buildLabel(context, effectiveForegroundColor)
                      .paddedSymmetrically(
                    horizontal: 12,
                  ),
                ],
              ).paddedOnly(left: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _isExpanded ? expandedChild : const SizedBox.shrink(),
              ),
              _buildTrailing(effectiveForegroundColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(Color effectiveForegroundColor) {
    return IconButton(
      padding: EdgeInsets.zero,
      icon: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animation.value * pi,
            child: Icon(
              _isExpanded ? Icons.close : Icons.chevron_right,
              color: effectiveForegroundColor,
            ),
          );
        },
      ),
      onPressed: () {
        if (_isExpanded) {
          _animationController.reverse();
        } else {
          _animationController.forward();
        }
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
    );
  }

  Widget _buildLabel(BuildContext context, Color effectiveForegroundColor) {
    return Text(
      widget.view.name,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(color: effectiveForegroundColor),
    );
  }

  Widget _buildCheckmark(Color effectiveForegroundColor) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: widget.selected
          ? Icon(Icons.check, color: effectiveForegroundColor)
          : const SizedBox.shrink(),
    );
  }
}
