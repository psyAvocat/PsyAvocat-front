import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/notification_model.dart';
import '../controllers/notifications_controller.dart';

/// Centre de notifications PsyAvocat — liste des rappels, alertes et messages récents.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
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

  @override
  Widget build(BuildContext context) {
    final universe = ref.watch(currentUniverseProvider);
    final primaryColor = universe.primaryColor;
    final notifsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2432),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(notificationsListProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toutes les notifications ont été marquées comme lues.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(Icons.done_all_rounded, size: 18, color: primaryColor),
            label: Text(
              'Tout lire',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryColor),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'Rendez-vous'),
            Tab(text: 'Dossiers'),
          ],
        ),
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('Impossible de charger les notifications'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(notificationsListProvider.notifier).refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(context, notifications, primaryColor),
              _buildList(context, notifications.where((n) => n.type == 'RDV').toList(), primaryColor),
              _buildList(context, notifications.where((n) => n.type == 'DOSSIER').toList(), primaryColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<NotificationModel> list, Color primaryColor) {
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
              child: Icon(Icons.notifications_none_rounded, size: 44, color: primaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vous êtes à jour avec vos rappels et messages.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notif = list[index];
        return _NotificationCard(
          notification: notif,
          primaryColor: primaryColor,
          onTap: () {
            ref.read(notificationsListProvider.notifier).markAsRead(notif.id);
            if (notif.targetRoute != null) {
              context.push(notif.targetRoute!);
            }
          },
          onDismissed: () {
            ref.read(notificationsListProvider.notifier).deleteNotification(notif.id);
          },
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationCard({
    required this.notification,
    required this.primaryColor,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'RDV':
        icon = Icons.calendar_month_rounded;
        iconColor = const Color(0xFF059669);
        break;
      case 'DOSSIER':
        icon = Icons.folder_rounded;
        iconColor = const Color(0xFFD97706);
        break;
      case 'MESSAGE':
        icon = Icons.chat_bubble_rounded;
        iconColor = const Color(0xFF6366F1);
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = primaryColor;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : primaryColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead ? const Color(0xFFE5E7EB) : primaryColor.withValues(alpha: 0.3),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.titre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: const Color(0xFF1E2432),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.date),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }
}
