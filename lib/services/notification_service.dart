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

  NotificationService._internal() {
    _initNotificationsStream();
  }

  void _initNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        _notifications.clear();
        _notifications.addAll(snapshot.docs.map((doc) {
          final data = doc.data();
          return AppNotification(
            id: doc.id,
            type: NotificationType.values[data['type'] as int],
            title: data['title'] as String,
            message: data['message'] as String,
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            isRead: data['isRead'] as bool,
            relatedId: data['relatedId'] as String?,
            senderId: data['senderId'] as String?,
            receiverId: data['receiverId'] as String?,
          );
        }));
        _notifyListeners();
      });
    }
  }

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
    String? relatedId,
    String? senderId,
    String? receiverId,
  }) async {
    try {
      // Don't create notification if user is sending to themselves
      if (senderId == userId) return;

      // Create a unique ID for the notification
      final notificationId =
          '${DateTime.now().millisecondsSinceEpoch}_${userId}';

      final notification = {
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.index,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'relatedId': relatedId,
        'senderId': senderId,
        'receiverId': receiverId,
      };

      // Use the unique ID when creating the notification
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification);

      // Add to local notifications if it's for the current user
      if (userId == _auth.currentUser?.uid) {
        final localNotification = AppNotification(
          id: notificationId,
          type: type,
          title: title,
          message: message,
          timestamp: DateTime.now(),
          relatedId: relatedId,
          isRead: false,
          senderId: senderId,
          receiverId: receiverId,
        );

        _notifications.insert(0, localNotification);
        _notifyListeners();
      }
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  Future<void> handleVibeMatch(String userId, String matchedUserName) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Create notification for the matched user
      await createNotification(
        userId: userId,
        title: 'New Vibe Match! 🎉',
        message: 'You matched with $matchedUserName! Start chatting now!',
        type: NotificationType.match,
        senderId: currentUser.uid,
        receiverId: userId,
      );
    } catch (e) {
      print('Error handling vibe match notification: $e');
    }
  }

  Future<void> handleMemeInteraction({
    required String memeOwnerId,
    required String interactorName,
    required bool isLike,
    String? memeId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid == memeOwnerId) return;

      await createNotification(
        userId: memeOwnerId,
        title: isLike ? 'New Like! ❤️' : 'New Comment! 💭',
        message: isLike
            ? '$interactorName liked your meme!'
            : '$interactorName commented on your meme!',
        type: NotificationType.activity,
        senderId: currentUser.uid,
        receiverId: memeOwnerId,
        relatedId: memeId,
      );
    } catch (e) {
      print('Error handling meme interaction notification: $e');
    }
  }

  Future<void> handleMoodBoardInteraction({
    required String boardOwnerId,
    required String interactorName,
    required bool isLike,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid == boardOwnerId) return;

      await createNotification(
        userId: boardOwnerId,
        title: isLike ? 'Mood Board Like! 🎨' : 'Mood Board Comment! 💬',
        message: isLike
            ? '$interactorName liked your mood board!'
            : '$interactorName commented on your mood board!',
        type: NotificationType.activity,
        senderId: currentUser.uid,
        receiverId: boardOwnerId,
      );
    } catch (e) {
      print('Error handling mood board interaction notification: $e');
    }
  }

  Future<void> handleConnectionRequest({
    required String receiverId,
    required String senderName,
    required bool isAccepted,
    required String requestId,
    required String senderId,
  }) async {
    try {
      if (isAccepted) {
        // Notify the sender that their request was accepted
        await createNotification(
          userId: senderId,
          title: 'Connection Accepted! 🤝',
          message: '$senderName accepted your connection request!',
          type: NotificationType.connection,
          relatedId: requestId,
          senderId: receiverId,
          receiverId: senderId,
        );
      } else {
        // Notify the receiver about the new connection request
        await createNotification(
          userId: receiverId,
          title: 'New Connection Request! 🤝',
          message: '$senderName wants to connect with you!',
          type: NotificationType.connection,
          relatedId: requestId,
          senderId: senderId,
          receiverId: receiverId,
        );
      }
    } catch (e) {
      print('Error handling connection request notification: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Update in Firestore first
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Then update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final updatedNotification = AppNotification(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          timestamp: _notifications[index].timestamp,
          relatedId: _notifications[index].relatedId,
          senderId: _notifications[index].senderId,
          receiverId: _notifications[index].receiverId,
          isRead: true,
        );

        _notifications[index] = updatedNotification;
        _notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Clear from Firestore first
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Then clear local state
      _notifications.clear();
      _notifyListeners();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
}

enum NotificationType {
  match,
  streak,
  activity,
  connection,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? relatedId;
  final String? senderId;
  final String? receiverId;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.relatedId,
    this.senderId,
    this.receiverId,
    this.isRead = false,
  });
}
