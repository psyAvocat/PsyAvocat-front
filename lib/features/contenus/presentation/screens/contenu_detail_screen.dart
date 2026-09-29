import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/universe_provider.dart';
import '../controllers/contenus_controller.dart';

/// Écran de lecture détaillée d'un article ou guide juridique/psychologique
class ContenuDetailScreen extends ConsumerWidget {
  final String contenuId;

  const ContenuDetailScreen({super.key, required this.contenuId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final detailAsync = ref.watch(contenuDetailProvider(contenuId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: primaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF4B5563)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lien copié dans le presse-papiers !'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF4B5563)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Article ajouté aux favoris.'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Erreur lors du chargement de l\'article')),
        data: (article) {
          if (article == null) {
            return const Center(child: Text('Article introuvable'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag & Catégorie
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        article.categorie,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '•  ${article.dureeLecture}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Titre
                Text(
                  article.titre,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2432),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 16),

                // Auteur
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: primaryColor.withValues(alpha: 0.15),
                        child: Text(
                          article.auteur.isNotEmpty ? article.auteur[0] : 'P',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.auteur,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E2432)),
                          ),
                          Text(
                            article.auteurTitre,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contenu complet formaté
                Text(
                  article.contenuComplet,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 30),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: article.tags
                      .map(
                        (t) => Chip(
                          label: Text('#$t', style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                          backgroundColor: const Color(0xFFF3F4F6),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
