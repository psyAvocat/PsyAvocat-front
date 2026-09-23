import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Statuts de validation des professionnels (Chapitre 9 de project_context.md).
enum ValidationStatus {
  pending('PENDING', 'En attente de vérification', AppColors.statusPending),
  approved('APPROVED', 'Profil validé', AppColors.statusApproved),
  rejected('REJECTED', 'Profil rejeté', AppColors.statusRejected),
  suspended('SUSPENDED', 'Profil suspendu', AppColors.statusSuspended);

  final String code;
  final String label;
  final Color color;

  const ValidationStatus(this.code, this.label, this.color);

  static ValidationStatus fromCode(String? code) {
    return ValidationStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => ValidationStatus.pending,
    );
  }
}
