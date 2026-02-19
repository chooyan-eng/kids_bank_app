import 'dart:io';

import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

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
    if (child.iconImagePath != null) {
      final file = File(child.iconImagePath!);
      if (file.existsSync()) {
        return Neumorphic(
          style: NeumorphicStyle(
            depth: -4,
            boxShape: NeumorphicBoxShape.circle(),
          ),
          child: ClipOval(
            child: SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: Image.file(file, fit: BoxFit.cover),
            ),
          ),
        );
      }
    }

    final initial = child.name.isNotEmpty ? child.name[0] : '?';
    return Neumorphic(
      style: NeumorphicStyle(
        depth: 4,
        boxShape: NeumorphicBoxShape.circle(),
        color: const Color(0xFFDDD4C8),
      ),
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B7355),
            ),
          ),
        ),
      ),
    );
  }
}
