import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/suivi_model.dart';
import '../controllers/suivi_controller.dart';

/// Écran « Mon suivi & Journal émotionnel » (Espace Psychologie).
class SuiviPsychologiqueScreen extends ConsumerWidget {
  const SuiviPsychologiqueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final historyAsync = ref.watch(humeurHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Suivi & Bien-être',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2432),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () => _showAddEntrySheet(context, ref, primaryColor),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Noter mon humeur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── 1. Carte Exercice de Respiration ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: _BreathingExerciseCard(primaryColor: primaryColor),
            ),
          ),

          // ─── 2. Titre Historique ──────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text(
                'Mon journal de bord récent',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2432),
                ),
              ),
            ),
          ),

          // ─── 3. Liste des entrées ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: historyAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => const SliverToBoxAdapter(
                child: Center(
                  child: Text('Erreur de chargement de l\'historique'),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Aucune note pour le moment.\nCliquez sur "Noter mon humeur" pour commencer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HumeurCard(
                        entry: item,
                        primaryColor: primaryColor,
                      ),
                    );
                  }, childCount: entries.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEntrySheet(
    BuildContext context,
    WidgetRef ref,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHumeurSheet(primaryColor: primaryColor, ref: ref),
    );
  }
}

// ─── Carte Exercice de Respiration ──────────────────────────────────────────
class _BreathingExerciseCard extends StatefulWidget {
  final Color primaryColor;
  const _BreathingExerciseCard({required this.primaryColor});

  @override
  State<_BreathingExerciseCard> createState() => _BreathingExerciseCardState();
}

class _BreathingExerciseCardState extends State<_BreathingExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.repeat(reverse: true);
      } else {
        _animController.stop();
        _animController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final scale = _isPlaying
                  ? 1.0 + (_animController.value * 0.25)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.air_rounded : Icons.spa_rounded,
                    color: widget.primaryColor,
                    size: 26,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cohérence cardiaque',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2432),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPlaying
                      ? 'Inspirez... et expirez calmement'
                      : '1 minute pour apaiser le stress',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _toggle,
            style: TextButton.styleFrom(
              foregroundColor: widget.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isPlaying ? 'Arrêter' : 'Démarrer',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte Humeur Item ──────────────────────────────────────────────────────
class _HumeurCard extends StatelessWidget {
  final HumeurEntryModel entry;
  final Color primaryColor;

  const _HumeurCard({required this.entry, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(entry.emojiHumeur, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.emotionDominante,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2432),
                      ),
                    ),
                    Text(
                      '${entry.date.day.toString().padLeft(2, '0')}/${entry.date.month.toString().padLeft(2, '0')}/${entry.date.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${entry.noteHumeur}/5',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (entry.noteText != null && entry.noteText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              entry.noteText!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ],
          if (entry.facteursDeclencheurs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: entry.facteursDeclencheurs
                  .map(
                    (f) => Chip(
                      label: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      backgroundColor: const Color(0xFFF3F4F6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── BottomSheet pour ajouter une entrée ────────────────────────────────────
class _AddHumeurSheet extends StatefulWidget {
  final Color primaryColor;
  final WidgetRef ref;

  const _AddHumeurSheet({required this.primaryColor, required this.ref});

  @override
  State<_AddHumeurSheet> createState() => _AddHumeurSheetState();
}

class _AddHumeurSheetState extends State<_AddHumeurSheet> {
  int _selectedNote = 4;
  String _selectedEmotion = 'Serein';
  final _noteController = TextEditingController();

  final List<String> _emotions = [
    'Serein',
    'Joyeux',
    'Soulagé',
    'Anxieux',
    'Fatigué',
    'Submergé',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await widget.ref
        .read(humeurHistoryProvider.notifier)
        .addEntry(
          noteHumeur: _selectedNote,
          emotionDominante: _selectedEmotion,
          noteText: _noteController.text.trim().isNotEmpty
              ? _noteController.text.trim()
              : null,
          facteurs: ['Personnel'],
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Entrée enregistrée dans votre journal.'
                : 'Erreur lors de l\'enregistrement',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Comment vous sentez-vous aujourd\'hui ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2432),
              ),
            ),
            const SizedBox(height: 16),

            // Échelle 1 à 5
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEmojiChoice(1, '😫'),
                _buildEmojiChoice(2, '😔'),
                _buildEmojiChoice(3, '😐'),
                _buildEmojiChoice(4, '🙂'),
                _buildEmojiChoice(5, '😄'),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Émotion dominante',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2432),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _emotions.map((em) {
                final isSelected = _selectedEmotion == em;
                return ChoiceChip(
                  label: Text(em),
                  selected: isSelected,
                  selectedColor: widget.primaryColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? widget.primaryColor
                        : const Color(0xFF4B5563),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (_) => setState(() => _selectedEmotion = em),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Une réflexion, un événement particulier ? (confidentiel)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Enregistrer dans mon journal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiChoice(int note, String emoji) {
    final isSelected = _selectedNote == note;
    return InkWell(
      onTap: () => setState(() => _selectedNote = note),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? widget.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 30)),
      ),
    );
  }
}
