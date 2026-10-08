import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/auth/presentation/controllers/session_controller.dart';
import '../config/app_config.dart';
import '../network/network_providers.dart';

/// Types d'événements temps réel émis par Spring Boot (`/ws`).
class RealtimeEventType {
  RealtimeEventType._();

  static const notification = 'NOTIFICATION';
  static const message = 'MESSAGE';
  static const creneauMisAJour = 'CRENEAU_MIS_A_JOUR';
  static const creneauxMisAJour = 'CRENEAUX_MIS_A_JOUR';
  static const contenuMisAJour = 'CONTENU_MIS_A_JOUR';
  static const professionnelMisAJour = 'PROFESSIONNEL_MIS_A_JOUR';
}

/// Événement reçu du serveur : `{ "type": ..., "payload": {...} }`.
class RealtimeEvent {
  final String type;
  final Map<String, dynamic> payload;

  const RealtimeEvent(this.type, [this.payload = const {}]);

  /// Lecture tolérante : un message mal formé est ignoré (null).
  static RealtimeEvent? tryParse(Object? raw) {
    if (raw is! String) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final type = json['type'];
      if (type is! String) return null;
      final payload = json['payload'];
      return RealtimeEvent(type, payload is Map<String, dynamic> ? payload : const {});
    } catch (_) {
      return null;
    }
  }
}

/// Connexion WebSocket unique de l'application.
///
/// - ouverte uniquement quand la session est autorisée ;
/// - authentifiée par le jeton Firebase (vérifié côté serveur au handshake) ;
/// - reconnectée avec un délai croissant (1 s → 30 s) en cas de coupure ;
/// - fermée à la déconnexion.
class RealtimeService {
  final Future<String?> Function() _tokenProvider;
  final WebSocketChannel Function(Uri uri) _connect;
  final _events = StreamController<RealtimeEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  Timer? _reconnectTimer;
  int _attempts = 0;
  bool _wanted = false;

  RealtimeService({
    required Future<String?> Function() tokenProvider,
    WebSocketChannel Function(Uri uri)? connect,
  }) : _tokenProvider = tokenProvider,
       _connect = connect ?? WebSocketChannel.connect;

  Stream<RealtimeEvent> get events => _events.stream;

  /// Adresse WebSocket dérivée de l'URL du serveur (http → ws, https → wss).
  static Uri socketUri(String token) {
    final base = Uri.parse(AppConfig.serverBaseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws',
      queryParameters: {'token': token},
    );
  }

  void start() {
    if (_wanted) return;
    _wanted = true;
    _attempts = 0;
    _open();
  }

  void stop() {
    _wanted = false;
    _reconnectTimer?.cancel();
    _closeChannel();
  }

  Future<void> _open() async {
    if (!_wanted) return;
    try {
      final token = await _tokenProvider();
      if (!_wanted) return;
      if (token == null) {
        _scheduleReconnect();
        return;
      }
      final channel = _connect(socketUri(token));
      _channel = channel;
      await channel.ready;
      if (!_wanted) {
        _closeChannel();
        return;
      }
      _attempts = 0;
      _subscription = channel.stream.listen(
        (raw) {
          final event = RealtimeEvent.tryParse(raw);
          if (event != null) _events.add(event);
        },
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: true,
      );
    } catch (error) {
      // Jamais affiché à l'utilisateur : on retente simplement plus tard.
      debugPrint('Realtime: connexion indisponible.');
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    _closeChannel();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_wanted) return;
    _reconnectTimer?.cancel();
    final seconds = min(30, pow(2, _attempts).toInt());
    _attempts++;
    _reconnectTimer = Timer(Duration(seconds: seconds), _open);
  }

  void _closeChannel() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    stop();
    _events.close();
  }
}

/// Service temps réel, piloté par l'état de session.
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final service = RealtimeService(tokenProvider: () => authRepository.getIdToken());
  ref.listen<SessionState>(sessionControllerProvider, (_, session) {
    if (session.isAuthorized) {
      service.start();
    } else {
      service.stop();
    }
  }, fireImmediately: true);
  ref.onDispose(service.dispose);
  return service;
});

/// Flux des événements temps réel (surchargeable dans les tests).
final realtimeEventsProvider = StreamProvider<RealtimeEvent>((ref) {
  return ref.watch(realtimeServiceProvider).events;
});

/// Écoute les événements d'un type donné et déclenche [onEvent].
/// À utiliser dans les contrôleurs (jamais dans les widgets).
void listenRealtime(
  Ref ref,
  Set<String> types,
  void Function(RealtimeEvent event) onEvent,
) {
  ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (_, next) {
    final event = next.value;
    if (event != null && types.contains(event.type)) onEvent(event);
  });
}
