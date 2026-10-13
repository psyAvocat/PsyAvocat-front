import 'package:flutter/material.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/app_strings.dart';

class MessagerieErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const MessagerieErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 60,
            color: context.palette.borderStrong,
          ),
          const SizedBox(height: 16),
          Text(tr('Impossible de charger les messages')),
          const SizedBox(height: 12),
          AppButton(
            text: tr('Réessayer'),
            isFullWidth: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
