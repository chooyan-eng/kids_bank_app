import 'dart:io';

import 'package:flutter/material.dart';

import '../models/child.dart';

/// Circular avatar widget.
/// Displays [Child.iconImagePath] as an image when available,
/// otherwise falls back to the first character of the child's name.
class AvatarWidget extends StatelessWidget {
  final Child child;
  final double radius;

  const AvatarWidget({required this.child, this.radius = 28, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (child.iconImagePath != null) {
      final file = File(child.iconImagePath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
          backgroundColor: theme.colorScheme.primaryContainer,
        );
      }
    }

    final initial = child.name.isNotEmpty ? child.name[0] : '?';
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
