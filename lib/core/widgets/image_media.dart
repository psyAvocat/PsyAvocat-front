import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache des médias (photos de profil, illustrations) servis par Cloudflare R2.
///
/// Les images sont gardées sur l'appareil 30 jours : un écran déjà vu s'affiche
/// sans retélécharger ses images, même après un redémarrage de l'application.
abstract final class CacheMedias {
  static final instance = CacheManager(
    Config(
      'psyavocat_medias',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 400,
    ),
  );

  /// Clé stable d'un média : son adresse sans la signature. Le lien signé
  /// change régulièrement, la clé d'objet R2 jamais (nom unique à chaque envoi :
  /// une même clé désigne toujours la même image).
  static String cleDe(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasQuery) return url;
    return '${uri.scheme}://${uri.authority}${uri.path}';
  }
}

/// Fournisseur d'image en cache, pour `CircleAvatar.backgroundImage`, etc.
ImageProvider imageMediaProvider(String url) => CachedNetworkImageProvider(
  url,
  cacheKey: CacheMedias.cleDe(url),
  cacheManager: CacheMedias.instance,
);

/// Image d'un média distant, mise en cache (disque et mémoire).
///
/// Sans adresse, ou si l'image ne se charge pas : [substitut] (fond neutre par
/// défaut). [largeurAffichee] (en points) permet de décoder l'image à la taille
/// affichée plutôt qu'en pleine résolution (avatars, vignettes).
class ImageMedia extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? largeurAffichee;
  final Widget? substitut;

  const ImageMedia({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.largeurAffichee,
    this.substitut,
  });

  @override
  Widget build(BuildContext context) {
    final adresse = url;
    final secours =
        substitut ??
        ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHigh);
    if (adresse == null || adresse.isEmpty) return secours;
    // Largeur connue et finie seulement : une image pleine largeur
    // (`double.infinity`) est décodée à sa taille d'origine.
    final largeur = largeurAffichee;
    final decodage = largeur != null && largeur.isFinite && largeur > 0
        ? (largeur * MediaQuery.devicePixelRatioOf(context)).round()
        : null;
    return CachedNetworkImage(
      imageUrl: adresse,
      cacheKey: CacheMedias.cleDe(adresse),
      cacheManager: CacheMedias.instance,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: decodage,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: Duration.zero,
      placeholder: (context, _) => secours,
      errorWidget: (context, _, _) => secours,
    );
  }
}
