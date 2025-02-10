import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  late SharedPreferences _prefs;
  final _listeners = <VoidCallback>[];

  // Settings keys
  static const String _keyAutoplayMusic = 'autoplay_music';
  static const String _keyShowAge = 'show_age';
  static const String _keyPrivateMoodBoard = 'private_mood_board';
  static const String _keyShowOnlineStatus = 'show_online_status';
  static const String _keyReceiveNotifications = 'receive_notifications';

  SettingsService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Autoplay Music
  bool get autoplayMusic => _prefs.getBool(_keyAutoplayMusic) ?? true;
  Future<void> setAutoplayMusic(bool value) async {
    await _prefs.setBool(_keyAutoplayMusic, value);
    _notifyListeners();
  }

  // Show Age
  bool get showAge => _prefs.getBool(_keyShowAge) ?? true;
  Future<void> setShowAge(bool value) async {
    await _prefs.setBool(_keyShowAge, value);
    _notifyListeners();
  }

  // Private Mood Board
  bool get privateMoodBoard => _prefs.getBool(_keyPrivateMoodBoard) ?? false;
  Future<void> setPrivateMoodBoard(bool value) async {
    await _prefs.setBool(_keyPrivateMoodBoard, value);
    _notifyListeners();
  }

  // Show Online Status
  bool get showOnlineStatus => _prefs.getBool(_keyShowOnlineStatus) ?? true;
  Future<void> setShowOnlineStatus(bool value) async {
    await _prefs.setBool(_keyShowOnlineStatus, value);
    _notifyListeners();
  }

  // Receive Notifications
  bool get receiveNotifications =>
      _prefs.getBool(_keyReceiveNotifications) ?? true;
  Future<void> setReceiveNotifications(bool value) async {
    await _prefs.setBool(_keyReceiveNotifications, value);
    _notifyListeners();
  }
}
