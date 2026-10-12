import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Photos plein écran qui se succèdent automatiquement en fondu enchaîné.
///
/// Exemple : `AutoCrossfadeImages(images: ['a.jpg', 'b.jpg'])` affiche `a`,
/// puis `b` après [interval], puis `a` à nouveau, etc.
class AutoCrossfadeImages extends StatefulWidget {
  final List<String> images;
  final Duration interval;

  const AutoCrossfadeImages({
    super.key,
    required this.images,
    this.interval = const Duration(seconds: 3),
  });

  /// Photo décodée à la hauteur de l'écran (2048 px au plus) plutôt qu'en
  /// pleine résolution : une photo de 4480×6720 occuperait sinon ~120 Mo.
  /// Les photos sont en portrait, plus larges que l'écran en proportion : en
  /// `BoxFit.cover`, c'est la hauteur qui détermine la taille affichée.
  /// Le même fournisseur sert au préchargement (même clé de cache).
  static ImageProvider provider(BuildContext context, String asset) {
    final media = MediaQuery.of(context);
    final height = min(media.size.height * media.devicePixelRatio, 2048.0);
    return ResizeImage(AssetImage(asset), height: height.round());
  }

  @override
  State<AutoCrossfadeImages> createState() => _AutoCrossfadeImagesState();
}

class _AutoCrossfadeImagesState extends State<AutoCrossfadeImages> {
  int _index = 0;
  Timer? _timer;

  int get _nextIndex => (_index + 1) % widget.images.length;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        setState(() => _index = _nextIndex);
        _precacheNext();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheNext();
  }

  /// La photo suivante est décodée pendant l'affichage de la courante :
  /// le fondu ne marque aucun temps d'arrêt.
  void _precacheNext() {
    if (widget.images.length < 2) return;
    precacheImage(
      AutoCrossfadeImages.provider(context, widget.images[_nextIndex]),
      context,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.images[_index];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      // Les deux photos se superposent pendant le fondu (pas de saut).
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: Image(
        image: AutoCrossfadeImages.provider(context, asset),
        key: ValueKey(asset),
        fit: BoxFit.cover,
        // Cadrage sur le haut : les visages restent visibles.
        alignment: Alignment.topCenter,
      ),
    );
  }
}
