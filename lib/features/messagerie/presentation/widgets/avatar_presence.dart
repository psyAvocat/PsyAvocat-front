import 'package:flutter/material.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/app_avatar.dart';

/// Photo du correspondant, avec une pastille verte quand il est connecté.
class AvatarPresence extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  final bool enLigne;

  const AvatarPresence({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 52,
    this.enLigne = false,
  });

  /// Vert de présence (le même partout dans la messagerie).
  static const couleurEnLigne = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final pastille = (size * 0.26).clamp(10.0, 16.0);
    return Semantics(
      label: enLigne ? '$name, en ligne' : name,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AppAvatar(name: name, photoUrl: photoUrl, size: size),
            Positioned(
              right: 0,
              bottom: 0,
              child: AnimatedScale(
                scale: enLigne ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Container(
                  width: pastille,
                  height: pastille,
                  decoration: BoxDecoration(
                    color: couleurEnLigne,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.palette.card, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
