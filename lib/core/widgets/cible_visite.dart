import 'package:flutter/widgets.dart';

/// Repère d'un élément de l'interface présenté par la visite guidée
/// (cloche des notifications, onglets de la barre de navigation…).
///
/// La visite retrouve l'élément par son [id] pour l'entourer d'un halo. Pas de
/// `GlobalKey` : un repère monté deux fois (pendant une transition) ne casse
/// rien, le plus récent est retenu.
class CibleVisite extends StatefulWidget {
  final String id;
  final Widget child;

  const CibleVisite({super.key, required this.id, required this.child});

  static final _cibles = <String, _CibleVisiteState>{};

  /// Zone occupée par l'élément [id], dans le repère de [repere] ; `null` si
  /// l'élément n'est pas affiché.
  static Rect? zone(String id, RenderBox repere) {
    final boite = _cibles[id]?.context.findRenderObject();
    if (boite is! RenderBox || !boite.attached || !boite.hasSize) return null;
    final origine = repere.globalToLocal(boite.localToGlobal(Offset.zero));
    return origine & boite.size;
  }

  @override
  State<CibleVisite> createState() => _CibleVisiteState();
}

class _CibleVisiteState extends State<CibleVisite> {
  @override
  void initState() {
    super.initState();
    CibleVisite._cibles[widget.id] = this;
  }

  @override
  void didUpdateWidget(covariant CibleVisite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _oublier(oldWidget.id);
      CibleVisite._cibles[widget.id] = this;
    }
  }

  @override
  void dispose() {
    _oublier(widget.id);
    super.dispose();
  }

  void _oublier(String id) {
    if (CibleVisite._cibles[id] == this) CibleVisite._cibles.remove(id);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
