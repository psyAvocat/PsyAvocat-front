import 'dart:async';
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

  @override
  State<AutoCrossfadeImages> createState() => _AutoCrossfadeImagesState();
}

class _AutoCrossfadeImagesState extends State<AutoCrossfadeImages> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        setState(() => _index = (_index + 1) % widget.images.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      // Les deux photos se superposent pendant le fondu (pas de saut).
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: Image.asset(
        widget.images[_index],
        key: ValueKey(widget.images[_index]),
        fit: BoxFit.cover,
        // Cadrage sur le haut : les visages restent visibles.
        alignment: Alignment.topCenter,
      ),
    );
  }
}
