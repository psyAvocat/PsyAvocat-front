import 'package:flutter/material.dart';
import '../../../../core/theme/design_system.dart';

/// Image d'illustration d'une publication (URL fournie par le backend, R2).
///
/// Sans image (ou si elle ne se charge pas), on affiche un fond neutre avec
/// une icône — jamais une photo de remplacement trompeuse.
class PublicationImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const PublicationImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = AppRadii.r12,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
      ),
    );
    final url = imageUrl;

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: url == null || url.isEmpty
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
