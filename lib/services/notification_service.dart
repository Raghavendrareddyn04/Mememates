import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final _notificationControllers = <VoidCallback>[];

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

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _notifyListeners();
  }

  void markAsRead(String id) {
    final notification = _notifications.firstWhere((n) => n.id == id);
    notification.isRead = true;
    _notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _notifyListeners();
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Simulated notification triggers
  void simulateMatch(String userName) {
    addNotification(
      AppNotification(
        type: NotificationType.match,
        title: 'New Match!',
        message: "You've matched with $userName!",
        timestamp: DateTime.now(),
      ),
    );
  }

  void simulateStreak(int days) {
    addNotification(
      AppNotification(
        type: NotificationType.streak,
        title: 'Keep Your Streak Alive!',
        message: 'Send a meme to maintain your $days-day streak',
        timestamp: DateTime.now(),
      ),
    );
  }

  void simulateProfileActivity(int likes) {
    addNotification(
      AppNotification(
        type: NotificationType.activity,
        title: 'Profile Activity',
        message: 'Your mood board got $likes likes today!',
        timestamp: DateTime.now(),
      ),
    );
  }
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
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        isRead = false;
}