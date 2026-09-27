import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/services/services_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/auth_controller.dart';

/// Écran d'accueil et tableau de bord après authentification.
/// Permet de vérifier l'état Firebase Auth et tester FCM selon les règles de sécurité.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _idTokenStatus;
  String? _fcmTokenStatus;
  String? _fcmPermissionStatus;
  bool _isLoadingToken = false;
  bool _isLoadingFcm = false;

  Future<void> _checkIdToken() async {
    setState(() {
      _isLoadingToken = true;
      _idTokenStatus = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final token = await authRepo.getIdToken();

    setState(() {
      _isLoadingToken = false;
      if (token != null && token.isNotEmpty) {
        _idTokenStatus = 'Jeton Firebase ID valide généré avec succès (${token.length} car.).';
      } else {
        _idTokenStatus = 'Impossible de récupérer le jeton ID (utilisateur non connecté).';
      }
    });
  }

  Future<void> _requestFcmPermission() async {
    final fcmService = ref.read(firebaseMessagingServiceProvider);
    final settings = await fcmService.requestPermission();
    setState(() {
      _fcmPermissionStatus = 'Statut autorisation : ${settings.authorizationStatus.name}';
    });
  }

  Future<void> _fetchFcmToken() async {
    setState(() {
      _isLoadingFcm = true;
      _fcmTokenStatus = null;
    });

    final fcmService = ref.read(firebaseMessagingServiceProvider);
    final token = await fcmService.getToken();

    setState(() {
      _isLoadingFcm = false;
      if (token != null && token.isNotEmpty) {
        _fcmTokenStatus = 'Jeton FCM généré et actif (${token.length} car.).';
      } else {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
          _fcmTokenStatus = 'Token APNs non encore disponible sur iOS / Xcode.';
        } else if (kIsWeb) {
          _fcmTokenStatus = 'FCM Web : Vérifiez la clé VAPID ou l\'enregistrement du Service Worker.';
        } else {
          _fcmTokenStatus = 'Jeton FCM non disponible.';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final user = authState.asData?.value;
    final lastMessage = ref.watch(fcmForegroundMessageProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord PsyAvocat'),
        backgroundColor: AppColors.lawyer,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. CARTE UTILISATEUR CONNECTÉ
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.lawyerBorder),
                  ),
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.lawyerSurface,
                              child: Icon(Icons.person, color: AppColors.lawyer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.email ?? 'Utilisateur non connecté',
                                    style: AppTypography.petitTitre,
                                  ),
                                  Text(
                                    'UID : ${user?.uid ?? "N/A"}',
                                    style: AppTypography.miniTexte,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          'Authentification Firebase active et sécurisée.',
                          style: AppTypography.texteSecondaire,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          text: 'Tester l\'obtention du Firebase ID Token',
                          isLoading: _isLoadingToken,
                          onPressed: _checkIdToken,
                          variant: AppButtonVariant.secondary,
                        ),
                        if (_idTokenStatus != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _idTokenStatus!,
                            style: AppTypography.miniTexte.copyWith(
                              color: _idTokenStatus!.contains('succès')
                                  ? AppColors.success
                                  : AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. CARTE FIREBASE CLOUD MESSAGING (FCM)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.psychologistBorder),
                  ),
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.psychologistSurface,
                              child: Icon(
                                Icons.notifications_active,
                                color: AppColors.psychologist,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Firebase Cloud Messaging (FCM)',
                              style: AppTypography.petitTitre,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gestion des notifications push multi-plateforme (Android, iOS, Web).',
                          style: AppTypography.texteSecondaire,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: '1. Demander permission',
                                onPressed: _requestFcmPermission,
                                variant: AppButtonVariant.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                text: '2. Récupérer Token FCM',
                                isLoading: _isLoadingFcm,
                                onPressed: _fetchFcmToken,
                                variant: AppButtonVariant.primary,
                              ),
                            ),
                          ],
                        ),
                        if (_fcmPermissionStatus != null) ...[
                          const SizedBox(height: 8),
                          Text(_fcmPermissionStatus!, style: AppTypography.miniTexte),
                        ],
                        if (_fcmTokenStatus != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _fcmTokenStatus!,
                            style: AppTypography.miniTexte.copyWith(
                              color: _fcmTokenStatus!.contains('actif')
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (lastMessage != null) ...[
                          const Divider(height: 24),
                          Text(
                            'Dernier message reçu au premier plan :',
                            style: AppTypography.labelInput,
                          ),
                          const SizedBox(height: 4),
                          Text('Titre : ${lastMessage.notification?.title ?? "Sans titre"}'),
                          Text('Corps : ${lastMessage.notification?.body ?? "Sans contenu"}'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. ACTION DECONNEXION
                AppButton(
                  text: 'Se déconnecter',
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
