import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<AppNotification> _notifications = [];
  final _notificationControllers = <VoidCallback>[];

  NotificationService._internal();

  void addListener(VoidCallback listener) {
    _notificationControllers.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _notificationControllers.remove(listener);
  }

  void _notifyListeners() {
    for (final controller in _notificationControllers) {
      controller();
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    try {
      final notification = {
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.index,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await _firestore.collection('notifications').add(notification);

      final localNotification = AppNotification(
        type: type,
        title: title,
        message: message,
        timestamp: DateTime.now(),
      );

      _notifications.insert(0, localNotification);
      _notifyListeners();
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<void> handleVibeMatch(
      String matchedUserId, String matchedUserName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await createNotification(
      userId: currentUser.uid,
      title: 'New Vibe Match! 🎉',
      message: 'You and $matchedUserName have matched! Start chatting now!',
      type: NotificationType.match,
    );
  }

  Future<void> handleMemeInteraction({
    required String memeOwnerId,
    required String interactorName,
    required bool isLike,
  }) async {
    await createNotification(
      userId: memeOwnerId,
      title: isLike ? 'New Like! ❤️' : 'New Comment! 💭',
      message: isLike
          ? '$interactorName liked your meme!'
          : '$interactorName commented on your meme!',
      type: NotificationType.activity,
    );
  }

  Future<void> handleMoodBoardInteraction({
    required String boardOwnerId,
    required String interactorName,
    required bool isLike,
  }) async {
    await createNotification(
      userId: boardOwnerId,
      title: isLike ? 'Mood Board Like! 🎨' : 'Mood Board Comment! 💬',
      message: isLike
          ? '$interactorName liked your mood board!'
          : '$interactorName commented on your mood board!',
      type: NotificationType.activity,
    );
  }

  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification(
          id: doc.id,
          type: NotificationType.values[data['type'] as int],
          title: data['title'] as String,
          message: data['message'] as String,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          isRead: data['isRead'] as bool,
        );
      }).toList();
    });
  }

  void markAsRead(String id) {
    final notification = _notifications.firstWhere((n) => n.id == id);
    notification.isRead = true;
    _notifyListeners();

    // Update in Firestore
    _firestore.collection('notifications').doc(id).update({'isRead': true});
  }

  void clearAll() {
    _notifications.clear();
    _notifyListeners();
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
}

enum NotificationType {
  match,
  streak,
  activity,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    String? id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}
