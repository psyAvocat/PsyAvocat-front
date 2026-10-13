import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/app_strings.dart';

class MessagerieEmptyState extends StatelessWidget {
  final Color primaryColor;

  const MessagerieEmptyState({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              tr('Aucune conversation'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.palette.textStrong,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tr(
                'Vos conversations avec les avocats et psychologues apparaîtront ici.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.palette.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
