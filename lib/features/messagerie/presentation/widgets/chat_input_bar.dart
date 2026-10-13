import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/app_strings.dart';

/// Saisie d'un message : champ arrondi gris clair et bouton d'envoi rond à
/// la couleur de l'univers, posés sur une barre blanche arrondie.
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Color primaryColor;
  final bool isSending;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.primaryColor,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: tr('Écrire un message...'),
                  hintStyle: TextStyle(
                    color: context.palette.textSubtle,
                    fontSize: 15,
                  ),
                  filled: true,
                  fillColor: context.palette.inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              button: true,
              label: tr('Envoyer'),
              child: InkWell(
                onTap: isSending ? null : onSend,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: isSending
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.send_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
