import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/contenu_model.dart';
import '../controllers/contenus_controller.dart';

/// Écran « Contenus & Guides » — Bibliothèque d'articles et vulgarisation juridique & psychologique.
class ContenusScreen extends ConsumerWidget {
  const ContenusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final contenusAsync = ref.watch(contenusListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Guides & Articles',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2432),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Bannière d'introduction
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conseils & Droits',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Articles rédigés par nos avocats et psychologues certifiés.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Liste des articles
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: contenusAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 40, color: Colors.redAccent),
                      const SizedBox(height: 8),
                      const Text('Impossible de charger les articles'),
                      TextButton(
                        onPressed: () => ref.read(contenusListProvider.notifier).refresh(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (articles) {
                if (articles.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Text('Aucun article disponible pour le moment.')),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = articles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ArticleCard(
                          article: article,
                          primaryColor: primaryColor,
                          onTap: () => context.push('/contenus/${article.id}'),
                        ),
                      );
                    },
                    childCount: articles.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final ContenuModel article;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.article,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPsy = article.univers == 'PSYCHOLOGIQUE';
    final cardAccent = isPsy ? const Color(0xFF0F766E) : const Color(0xFF1E3A8A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    article.categorie,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cardAccent,
                    ),
                  ),
                ),
                Text(
                  article.dureeLecture,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              article.titre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2432),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.extrait,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: cardAccent.withValues(alpha: 0.15),
                  child: Text(
                    article.auteur.isNotEmpty ? article.auteur[0] : 'P',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cardAccent),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${article.auteur} • ${article.auteurTitre}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 16, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
