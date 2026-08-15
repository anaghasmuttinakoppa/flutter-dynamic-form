import 'package:flutter/material.dart';

/// Animates field appearance/disappearance based on visibility.
class AnimatedFormField extends StatelessWidget {
  /// Creates an [AnimatedFormField].
  const AnimatedFormField({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
    this.curve = Curves.easeInOut,
  });

  /// Whether the field should be shown.
  final bool visible;

  /// Field content.
  final Widget child;

  /// Animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: visible
          ? KeyedSubtree(key: const ValueKey('visible'), child: child)
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}
