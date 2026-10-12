import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../controllers/profil_controller.dart';

/// Photo de l'utilisateur connecté (initiales à défaut), en haut à droite des
/// pages empilées.
class CurrentUserAvatar extends ConsumerWidget {
  final double size;

  const CurrentUserAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(currentProfilProvider).value;
    return AppAvatar(
      name: profil?.nomComplet ?? '',
      photoUrl: profil?.photoUrl,
      size: size,
    );
  }
}
