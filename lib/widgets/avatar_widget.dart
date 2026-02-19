import 'package:flutter/material.dart';

import '../models/child.dart';

/// Circular avatar widget that displays the first character of the child's name.
/// Phase 2: will show [Child.iconImagePath] when set.
class AvatarWidget extends StatelessWidget {
  final Child child;
  final double radius;

  const AvatarWidget({required this.child, this.radius = 28, super.key});

  @override
  Widget build(BuildContext context) {
    final initial = child.name.isNotEmpty ? child.name[0] : '?';
    final theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
