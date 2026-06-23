import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/shared/models/app_notification.dart';

class NotificationService {
  NotificationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance;

  static final NotificationService instance = NotificationService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenRefreshSub;
  Timer? _tokenSyncRetry;
  int _tokenSyncRetryCount = 0;

  static const int _maxTokenSyncRetries = 3;

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('notifications');
  }

  CollectionReference<Map<String, dynamic>> _tokensRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notificationTokens');
  }

  Stream<List<AppNotification>> watchNotifications({int limit = 50}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return _notificationsRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotification.fromDoc)
              .toList(growable: false),
        );
  }

  Stream<int> watchUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _notificationsRef(uid)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _notificationsRef(uid).doc(notificationId).update({
      'status': 'read',
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final unreadDocs =
        await _notificationsRef(
          uid,
        ).where('status', isEqualTo: 'unread').limit(100).get();

    if (unreadDocs.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadDocs.docs) {
      batch.update(doc.reference, {
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> syncMessagingToken() {
    _tokenSyncRetry?.cancel();
    _tokenSyncRetry = null;
    _tokenSyncRetryCount = 0;
    return _syncMessagingToken();
  }

  Future<void> _syncMessagingToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || kIsWeb) return;

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      _listenForTokenRefresh();

      final canRequestFcmToken = await _waitForAppleApnsToken();
      if (!canRequestFcmToken) return;

      final token = await _messaging.getToken();
      if (token != null) await _saveToken(uid, token);
    } catch (e) {
      if (_isApnsTokenNotReadyError(e)) {
        _scheduleTokenSyncRetry();
        return;
      }
      debugPrint('Falha ao sincronizar token de notificacao: $e');
    }
  }

  void _listenForTokenRefresh() {
    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen((newToken) {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid != null) {
        _saveToken(currentUid, newToken).catchError((e) {
          debugPrint('Falha ao atualizar token de notificacao: $e');
        });
      }
    });
  }

  Future<bool> _waitForAppleApnsToken() async {
    if (!_isApplePlatform) return true;

    for (var attempt = 0; attempt < 3; attempt++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) return true;

      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
    }

    _scheduleTokenSyncRetry();
    return false;
  }

  bool get _isApplePlatform {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  bool _isApnsTokenNotReadyError(Object error) {
    final message = error.toString();
    return message.contains('apns-token-not-set') ||
        message.contains('APNS token has not been received') ||
        message.contains('APNS token has not been set');
  }

  void _scheduleTokenSyncRetry() {
    if (_tokenSyncRetryCount >= _maxTokenSyncRetries) {
      debugPrint(
        'Token APNs ainda nao disponivel; o sync FCM sera tentado novamente '
        'quando o app carregar o usuario outra vez.',
      );
      return;
    }

    _tokenSyncRetryCount += 1;
    _tokenSyncRetry?.cancel();
    _tokenSyncRetry = Timer(Duration(seconds: 2 * _tokenSyncRetryCount), () {
      _tokenSyncRetry = null;
      _syncMessagingToken();
    });
  }

  Future<void> _saveToken(String uid, String token) {
    return _tokensRef(uid).doc(token).set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'enabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> dispose() async {
    _tokenSyncRetry?.cancel();
    _tokenSyncRetry = null;
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
