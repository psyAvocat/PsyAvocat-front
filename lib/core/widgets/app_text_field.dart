import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_system.dart';

/// Champ de texte officiel PsyAvocat.
///
/// Intègre :
/// - Typographie Montserrat pour labels, hints et texte de saisie.
/// - Bordures douces modernes (12 px).
/// - Gestion intégrée de la visibilité pour mot de passe.
/// - Focus stylisé selon l'univers actif.
/// - États d'erreur (#FB1216), disabled et validation.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final AppUniverse? universe;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.focusNode,
    this.universe,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final universeColors = widget.universe != null
        ? AppUniverseColors.fromUniverse(widget.universe!)
        : AppTheme.universeOf(context);

    final primaryColor = universeColors.primary;

    Widget? effectiveSuffixIcon = widget.suffixIcon;
    if (widget.obscureText && widget.suffixIcon == null) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textTertiary,
          size: AppIcons.sizeMd,
        ),
        splashRadius: 20,
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelInput.copyWith(
            color: widget.enabled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
        AppSpacing.vGap8,
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          maxLines: _obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          inputFormatters: widget.inputFormatters,
          style: AppTypography.texte.copyWith(
            color: widget.enabled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            helperStyle: AppTypography.miniTexte,
            errorStyle: AppTypography.miniTexte.copyWith(color: AppColors.danger),
            hintStyle: AppTypography.texteSecondaire.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: widget.enabled ? AppColors.neutralSurface : AppColors.neutralSurfaceSecondary,
            contentPadding: AppSpacing.inputPadding,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: widget.prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: effectiveSuffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: effectiveSuffixIcon,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            border: const OutlineInputBorder(
              borderRadius: AppRadii.r12,
              borderSide: BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadii.r12,
              borderSide: BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.r12,
              borderSide: BorderSide(color: primaryColor, width: 1.8),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadii.r12,
              borderSide: BorderSide(color: AppColors.danger, width: 1.2),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadii.r12,
              borderSide: BorderSide(color: AppColors.danger, width: 1.8),
            ),
            disabledBorder: const OutlineInputBorder(
              borderRadius: AppRadii.r12,
              borderSide: BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
