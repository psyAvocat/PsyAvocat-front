import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/navigation/ouvrir_route.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/notification_model.dart';
import '../controllers/notifications_controller.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/visio.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/app_back_button.dart';

/// Catégorie d'affichage d'une notification, déduite de son type serveur
/// (RDV_CONFIRME, DOSSIER_ACCEPTE, NOUVEAU_MESSAGE…) et de sa ressource.
enum _Categorie { rendezVous, dossier, message, autre }

_Categorie _categorieDe(NotificationItem n) {
  final type = n.type.toUpperCase();
  final ressource = n.ressourceType?.toUpperCase();
  if (type.startsWith('RDV') ||
      type.startsWith('RAPPEL') ||
      ressource == 'RENDEZ_VOUS') {
    return _Categorie.rendezVous;
  }
  if (type.startsWith('DOSSIER') ||
      ressource == 'DOSSIER' ||
      ressource == 'SOUMISSION') {
    return _Categorie.dossier;
  }
  if (type.contains('MESSAGE') || ressource == 'CONVERSATION') {
    return _Categorie.message;
  }
  return _Categorie.autre;
}

/// Centre de notifications : rappels, réponses et messages de l'univers courant.
/// Une notification se supprime en la balayant vers la gauche ou avec sa corbeille.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _message(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(texte), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _toutLire() async {
    try {
      await ref.read(notificationsListProvider.notifier).markAllAsRead();
      if (mounted) {
        _message(tr('Toutes les notifications ont été marquées comme lues.'));
      }
    } catch (error) {
      if (mounted) _message(userMessageFor(error));
    }
  }

  Future<void> _supprimerLues() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Supprimer les notifications lues ?')),
        content: Text(
          tr(
            'Les notifications non lues sont conservées. Cette action est définitive.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Annuler')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Supprimer')),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    try {
      await ref.read(notificationsListProvider.notifier).deleteRead();
      if (mounted) _message(tr('Notifications lues supprimées.'));
    } catch (error) {
      if (mounted) _message(userMessageFor(error));
    }
  }

  Future<void> _supprimer(NotificationItem notif) async {
    try {
      await ref
          .read(notificationsListProvider.notifier)
          .deleteNotification(notif.id);
      if (mounted) _message(tr('Notification supprimée.'));
    } catch (error) {
      if (mounted) _message(userMessageFor(error));
    }
  }

  void _ouvrir(NotificationItem notif) {
    ref.read(notificationsListProvider.notifier).markAsRead(notif.id);
    final route = notif.targetRoute;
    if (route != null) ouvrirRoute(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final avocat = ref.watch(currentUniverseProvider).isLawyer;
    // Notifications de l'univers courant (même liste que le badge de la cloche).
    final notifsAsync = ref.watch(visibleNotificationsProvider);
    final aDesLues = notifsAsync.value?.any((n) => n.lu) ?? false;
    final troisiemeOnglet = avocat ? _Categorie.dossier : _Categorie.message;

    return Scaffold(
      backgroundColor: context.palette.page,
      appBar: AppBar(
        backgroundColor: context.palette.card,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(tr('Notifications')),
        actions: [
          PopupMenuButton<String>(
            tooltip: '',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              if (action == 'lire') _toutLire();
              if (action == 'supprimer') _supprimerLues();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'lire',
                child: ListTile(
                  leading: const Icon(Icons.done_all_rounded),
                  title: Text(tr('Tout marquer comme lu')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'supprimer',
                enabled: aDesLues,
                child: ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: Text(tr('Supprimer les lues')),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: context.palette.textSubtle,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: tr('Toutes')),
            Tab(text: tr('Rendez-vous')),
            Tab(text: avocat ? tr('Dossiers') : tr('Messages')),
          ],
        ),
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(tr('Impossible de charger les notifications')),
              const SizedBox(height: 12),
              AppButton(
                text: tr('Réessayer'),
                isFullWidth: false,
                onPressed: () =>
                    ref.read(notificationsListProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        data: (notifications) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(context, notifications, primaryColor),
              _buildList(
                context,
                notifications
                    .where((n) => _categorieDe(n) == _Categorie.rendezVous)
                    .toList(),
                primaryColor,
              ),
              _buildList(
                context,
                notifications
                    .where((n) => _categorieDe(n) == troisiemeOnglet)
                    .toList(),
                primaryColor,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<NotificationItem> list,
    Color primaryColor,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('Aucune notification'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr('Vous êtes à jour avec vos rappels et messages.'),
              style: TextStyle(fontSize: 13, color: context.palette.textSubtle),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsListProvider.notifier).refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notif = list[index];
          return _NotificationCard(
            key: ValueKey(notif.id),
            notification: notif,
            primaryColor: primaryColor,
            onTap: () => _ouvrir(notif),
            onDelete: () => _supprimer(notif),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    super.key,
    required this.notification,
    required this.primaryColor,
    required this.onTap,
    required this.onDelete,
  });

  Future<void> _rejoindre(BuildContext context, String lien) async {
    final ouvert = await rejoindreVisio(lien);
    if (!ouvert && context.mounted) {
      AppNotification.showError(
        context,
        tr('Impossible d’ouvrir le lien de visioconférence.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = switch (_categorieDe(notification)) {
      _Categorie.rendezVous => (
        notification.type == 'RAPPEL_VISIO'
            ? Icons.videocam_rounded
            : Icons.calendar_month_rounded,
        primaryColor,
      ),
      _Categorie.dossier => (Icons.folder_rounded, const Color(0xFFD97706)),
      _Categorie.message => (
        Icons.chat_bubble_rounded,
        const Color(0xFF6366F1),
      ),
      _Categorie.autre => (Icons.notifications_rounded, primaryColor),
    };
    final lue = notification.isRead;

    return Dismissible(
      key: ValueKey('swipe-${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Material(
        color: lue
            ? context.palette.card
            : primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: lue
                    ? context.palette.border
                    : primaryColor.withValues(alpha: 0.3),
                width: lue ? 1 : 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
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
                              notification.titre,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: lue
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: context.palette.textStrong,
                              ),
                            ),
                          ),
                          if (!lue)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.palette.text,
                          height: 1.3,
                        ),
                      ),
                      if (notification.lienVisio != null) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () =>
                              _rejoindre(context, notification.lienVisio!),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F9D58),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  tr('Rejoindre la visioconférence'),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(notification.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.textSubtle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: context.palette.textSubtle,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return tr('À l’instant');
    if (diff.inMinutes < 60) {
      return tr('Il y a {n} min', {'n': diff.inMinutes});
    }
    if (diff.inHours < 24) return tr('Il y a {n} h', {'n': diff.inHours});
    return tr('{date} à {heure}', {
      'date':
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
      'heure': Formatters.formatHeure(date),
    });
  }
}
