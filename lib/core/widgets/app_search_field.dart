import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Barre de recherche de l'application : la `SearchBar` Material d'origine,
/// avec un focus visible. Touchée, elle s'entoure d'un liseré à la couleur de
/// l'univers ; toucher ailleurs la ramène à l'état neutre et ferme le clavier.
///
/// Exemple : `AppSearchField(hintText: tr('Rechercher un avocat…'), onChanged: …)`
class AppSearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final bool autofocus;

  /// Croix pour effacer la saisie (écran de recherche).
  final bool effacable;

  /// Barre d'accès (accueil) : un appui ouvre l'écran de recherche.
  final VoidCallback? onTap;

  const AppSearchField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.autofocus = false,
    this.effacable = false,
    this.onTap,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final _focus = FocusNode();
  TextEditingController? _controleurInterne;

  TextEditingController get _controleur =>
      widget.controller ?? (_controleurInterne ??= TextEditingController());

  bool get _acces => widget.onTap != null;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rafraichir);
    _controleur.addListener(_rafraichir);
  }

  @override
  void didUpdateWidget(covariant AppSearchField ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.controller != widget.controller) {
      (ancien.controller ?? _controleurInterne)?.removeListener(_rafraichir);
      _controleur.addListener(_rafraichir);
    }
  }

  @override
  void dispose() {
    _controleur.removeListener(_rafraichir);
    _focus.dispose();
    _controleurInterne?.dispose();
    super.dispose();
  }

  void _rafraichir() {
    if (mounted) setState(() {});
  }

  void _effacer() {
    _controleur.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final couleur = Theme.of(context).colorScheme.primary;
    final actif = _focus.hasFocus && !_acces;

    return SearchBar(
      controller: _controleur,
      focusNode: _focus,
      hintText: widget.hintText,
      autoFocus: widget.autofocus,
      readOnly: _acces,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      // Toucher ailleurs : barre neutre, clavier fermé.
      onTapOutside: (_) => _focus.unfocus(),
      leading: Icon(Icons.search_rounded, color: actif ? couleur : null),
      trailing: [
        if (widget.effacable && _controleur.text.isNotEmpty)
          // Dans la zone du champ : l'effacement ne lui retire pas le focus.
          TextFieldTapRegion(
            child: IconButton(
              tooltip: tr('Effacer'),
              icon: const Icon(Icons.close_rounded),
              onPressed: _effacer,
            ),
          ),
      ],
      elevation: const WidgetStatePropertyAll(0),
      // Focus : liseré à la couleur de l'univers.
      side: WidgetStatePropertyAll(
        actif ? BorderSide(color: couleur, width: 2) : BorderSide.none,
      ),
    );
  }
}
