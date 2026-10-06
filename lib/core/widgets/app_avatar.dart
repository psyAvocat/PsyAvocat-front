import 'package:flutter/material.dart';
import '../theme/design_system.dart';

/// Photo ronde d'une personne, avec ses initiales si aucune photo n'est disponible.
///
/// Exemple : `AppAvatar(name: 'Awa Traoré', photoUrl: pro.photoUrl)`
class AppAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;

  const AppAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 56,
  });

  /// « Awa Traoré » → « AT »
  String get _initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = Center(
      child: Text(
        _initials,
        style: AppTypography.texteSemiBold.copyWith(
          fontSize: size * 0.36,
          color: scheme.primary,
        ),
      ),
    );

    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Semantics(
      label: 'Photo de $name',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primaryContainer,
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initials,
              )
            : initials,
      ),
    );
  }
}
