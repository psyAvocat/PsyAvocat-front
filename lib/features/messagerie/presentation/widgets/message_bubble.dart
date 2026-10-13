import 'package:flutter/material.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/messagerie_model.dart';
import '../../../../core/theme/app_palette.dart';

/// Bulle de message : à droite et à la couleur de l'univers pour le client,
/// à gauche, en gris et précédée de la photo pour le professionnel.
class MessageBubble extends StatelessWidget {
  final Message message;
  final Color primaryColor;
  final String participantName;
  final String? participantPhotoUrl;

  /// Utilisateur connecté : ses messages sont affichés à droite.
  final String? currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.primaryColor,
    required this.participantName,
    this.participantPhotoUrl,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isMe =
        message.expediteurId == null || message.expediteurId == currentUserId;

    final bulle = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isMe ? primaryColor : context.palette.bubbleIncoming,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message.contenu,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.25,
          color: isMe ? Colors.white : context.palette.onBubbleIncoming,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            AppAvatar(
              name: participantName,
              photoUrl: participantPhotoUrl,
              size: 30,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(child: bulle),
        ],
      ),
    );
  }
}
