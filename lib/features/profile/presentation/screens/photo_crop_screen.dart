import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_button.dart';

/// Recadrage de la photo de profil avant envoi : on déplace et on zoome la photo
/// (deux doigts) pour placer son visage dans le cercle.
/// Renvoie une photo carrée PNG de [taillePhoto] px, ou null si l'utilisateur annule.
class PhotoCropScreen extends StatefulWidget {
  final Uint8List octets;

  const PhotoCropScreen({super.key, required this.octets});

  /// Côté de la photo produite : nette dans l'application comme sur le web.
  static const double taillePhoto = 512;

  static Future<Uint8List?> ouvrir(BuildContext context, Uint8List octets) {
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoCropScreen(octets: octets),
      ),
    );
  }

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final _cadreKey = GlobalKey();
  final _transformation = TransformationController();
  Size? _tailleImage;
  double? _coteCentre;
  bool _erreur = false;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _lireDimensions();
  }

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  Future<void> _lireDimensions() async {
    try {
      final image = await decodeImageFromList(widget.octets);
      if (!mounted) return;
      setState(
        () => _tailleImage = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      );
      image.dispose();
    } catch (_) {
      if (mounted) setState(() => _erreur = true);
    }
  }

  /// Image affichée à la taille qui couvre exactement le cadre.
  Size _tailleCouvrante(double cote) {
    final taille = _tailleImage!;
    final echelle = math.max(cote / taille.width, cote / taille.height);
    return Size(taille.width * echelle, taille.height * echelle);
  }

  /// Photo centrée dans le cadre à l'ouverture (et si le cadre change de taille).
  void _centrer(double cote) {
    if (_coteCentre == cote) return;
    _coteCentre = cote;
    final affichee = _tailleCouvrante(cote);
    _transformation.value = Matrix4.translationValues(
      -(affichee.width - cote) / 2,
      -(affichee.height - cote) / 2,
      0,
    );
  }

  Future<void> _valider(double cote) async {
    setState(() => _enCours = true);
    try {
      final boundary =
          _cadreKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(
        pixelRatio: PhotoCropScreen.taillePhoto / cote,
      );
      final donnees = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (!mounted) return;
      Navigator.of(context).pop(donnees?.buffer.asUint8List());
    } catch (_) {
      // Recadrage impossible : la photo d'origine est envoyée telle quelle.
      if (mounted) Navigator.of(context).pop(widget.octets);
    }
  }

  @override
  Widget build(BuildContext context) {
    final couleur = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(tr('Ajuster la photo')),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cote = math.min(constraints.maxWidth - 48, 360.0);
            return Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    tr('Déplacez et zoomez la photo pour bien cadrer votre visage.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _erreur
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              tr('Cette image ne peut pas être lue. Choisissez une autre photo.'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          )
                        : _tailleImage == null
                        ? const CircularProgressIndicator(color: Colors.white)
                        : _cadre(cote),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: tr('Annuler'),
                          isOutlined: true,
                          color: Colors.white,
                          textColor: Colors.white,
                          onPressed: _enCours
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: tr('Valider'),
                          color: couleur,
                          isLoading: _enCours,
                          onPressed: _tailleImage == null || _enCours
                              ? null
                              : () => _valider(cote),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cadre(double cote) {
    _centrer(cote);
    final affichee = _tailleCouvrante(cote);
    return SizedBox(
      width: cote,
      height: cote,
      child: Stack(
        children: [
          RepaintBoundary(
            key: _cadreKey,
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _transformation,
                constrained: false,
                minScale: 1,
                maxScale: 4,
                boundaryMargin: EdgeInsets.zero,
                child: Image.memory(
                  widget.octets,
                  width: affichee.width,
                  height: affichee.height,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              size: Size.square(cote),
              painter: _MasqueCercle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Assombrit tout ce qui est hors du cercle de cadrage.
class _MasqueCercle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cercle = Rect.fromLTWH(0, 0, size.width, size.height);
    final masque = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(cercle)
      ..addOval(cercle);
    canvas.drawPath(masque, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawOval(
      cercle.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
