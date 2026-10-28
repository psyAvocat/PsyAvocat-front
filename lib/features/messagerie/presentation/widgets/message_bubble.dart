import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/models/messagerie_model.dart';
import '../../../../core/theme/app_palette.dart';

/// Bulle de message : à droite et à la couleur de l'univers pour le client,
/// à gauche, en gris et précédée de la photo pour le professionnel.
class MessageBubble extends StatelessWidget {
  static final RegExp _urlRegex = RegExp(r'https?:\/\/[^\s]+', caseSensitive: false);

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

  String? _extractFirstUrl(String text) {
    final match = _urlRegex.firstMatch(text);
    return match?.group(0);
  }

  Future<void> _openUrl(String rawUrl) async {
    final fallbackId = message.conversationId.isNotEmpty
        ? message.conversationId
        : 'Direct';
    final target = rawUrl.contains('meet.google.com')
        ? 'https://meet.ffmuc.net/PsyAvocat-Consultation-$fallbackId'
        : rawUrl.trim().replaceAll('https://meet.jit.si/', 'https://meet.ffmuc.net/');
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  List<InlineSpan> _buildTextSpans(String text, Color textColor, Color linkColor) {
    final spans = <InlineSpan>[];
    int start = 0;
    for (final match in _urlRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: linkColor,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
            fontWeight: FontWeight.w700,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _openUrl(url),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isMe =
        message.expediteurId == null || message.expediteurId == currentUserId;
    final textColor = isMe ? Colors.white : context.palette.onBubbleIncoming;
    final linkColor = isMe ? Colors.white : primaryColor;
    final firstUrl = _extractFirstUrl(message.contenu);

    final bulle = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isMe ? primaryColor : context.palette.bubbleIncoming,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
                color: textColor,
              ),
              children: _buildTextSpans(message.contenu, textColor, linkColor),
            ),
          ),
          if (firstUrl != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openUrl(firstUrl),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F9D58),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tr('Rejoindre la visioconférence'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
