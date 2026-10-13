import 'package:flutter/material.dart';
import '../../data/models/messagerie_model.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/app_strings.dart';

class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final Color primaryColor;
  final VoidCallback onTap;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.messagesNonLus > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: hasUnread
            ? Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5)
            : Border.all(color: context.palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AppAvatar(
                  name: conversation.correspondantDisplayName,
                  photoUrl: conversation.correspondantPhotoUrl,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.correspondantDisplayName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: context.palette.textStrong,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.dernierMessage?.dateEnvoi != null)
                            Text(
                              _formatDate(
                                conversation.dernierMessage!.dateEnvoi!,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: hasUnread
                                    ? primaryColor
                                    : context.palette.textSubtle,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.dernierMessage?.contenu ??
                                  tr('Aucun message'),
                              style: TextStyle(
                                fontSize: 13,
                                color: hasUnread
                                    ? context.palette.text
                                    : context.palette.textSubtle,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                conversation.messagesNonLus.toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${date.day}/${date.month}';
  }
}
