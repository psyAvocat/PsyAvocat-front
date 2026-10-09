import 'package:flutter/material.dart';

class MessagerieErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const MessagerieErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 60,
            color: Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 16),
          const Text('Impossible de charger les messages'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
