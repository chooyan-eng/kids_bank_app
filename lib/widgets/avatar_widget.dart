import 'dart:io';

import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

import '../models/child.dart';

/// Circular neumorphic avatar widget.
/// Displays [Child.iconImagePath] as an image when available,
/// otherwise falls back to the first character of the child's name.
class AvatarWidget extends StatelessWidget {
  final Child child;
  final double radius;

  const AvatarWidget({required this.child, this.radius = 28, super.key});

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    if (child.iconImagePath != null) {
      final file = File(child.iconImagePath!);
      if (file.existsSync()) {
        return Neumorphic(
          style: NeumorphicStyle(
            boxShape: NeumorphicBoxShape.circle(),
            depth: 4,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: ClipOval(
              child: Image.file(
                file,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    }

    final initial = child.name.isNotEmpty ? child.name[0] : '?';
    return Neumorphic(
      style: NeumorphicStyle(
        boxShape: NeumorphicBoxShape.circle(),
        depth: 4,
        color: const Color(0xFFFFCC80),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7B4F00),
            ),
          ),
        ),
      ),
    );
  }
}
