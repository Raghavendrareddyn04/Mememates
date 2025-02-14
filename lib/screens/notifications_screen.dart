import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';
import 'dart:ui';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final _notificationService = NotificationService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showFilterMenu = false;
  String _selectedFilter = 'All';
  List<AppNotification> _filteredNotifications = [];

  final List<String> _filters = ['All', 'Matches', 'Streaks', 'Activity'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _handleNotificationUpdate();
    _notificationService.addListener(_handleNotificationUpdate);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _handleNotificationUpdate() {
    setState(() {
      _filterNotifications();
    });
  }

  void _filterNotifications() {
    final notifications = _notificationService.notifications;
    if (_selectedFilter == 'All') {
      _filteredNotifications = notifications;
    } else {
      final filterType = NotificationType.values.firstWhere(
        (type) => type.toString().split('.').last == _selectedFilter,
        orElse: () => NotificationType.activity,
      );
      _filteredNotifications =
          notifications.where((n) => n.type == filterType).toList();
    }
  }

  @override
  void dispose() {
    _notificationService.removeListener(_handleNotificationUpdate);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;
    final isLargeScreen = size.width >= 1200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(isSmallScreen),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade900,
                Colors.purple.shade900,
                Colors.pink.shade900,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (!isSmallScreen) _buildHeader(isSmallScreen),
                _buildFilterChips(isSmallScreen),
                Expanded(
                  child: _filteredNotifications.isEmpty
                      ? _buildEmptyState(isSmallScreen)
                      : isLargeScreen
                          ? _buildLargeScreenLayout()
                          : isMediumScreen
                              ? _buildMediumScreenLayout()
                              : _buildSmallScreenLayout(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _filteredNotifications.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () {
                  _notificationService.clearAll();
                  setState(() {});
                },
                backgroundColor: Colors.pink,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All'),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isSmallScreen) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.2),
          ),
        ),
      ),
      title: isSmallScreen ? _buildHeader(true) : null,
      actions: [
        IconButton(
          icon: AnimatedRotation(
            duration: const Duration(milliseconds: 300),
            turns: _showFilterMenu ? 0.5 : 0,
            child: const Icon(Icons.filter_list),
          ),
          onPressed: () {
            setState(() => _showFilterMenu = !_showFilterMenu);
          },
        ),
      ],
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 0 : 24,
        vertical: isSmallScreen ? 0 : 16,
      ),
      child: Row(
        mainAxisAlignment:
            isSmallScreen ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.pink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _filteredNotifications.length.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isSmallScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilterMenu ? (isSmallScreen ? 60 : 80) : 0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 8 : 16,
        ),
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                    _filterNotifications();
                  });
                },
                backgroundColor: Colors.white.withOpacity(0.1),
                selectedColor: Colors.pink,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.pink : Colors.white24,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: isSmallScreen ? 64 : 96,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'All'
                ? 'No notifications yet'
                : 'No $_selectedFilter notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for updates!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildNotificationList(true),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: _buildNotificationStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumScreenLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildNotificationList(true),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallScreenLayout() {
    return _buildNotificationList(false);
  }

  Widget _buildNotificationList(bool isWideScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 0 : 16,
            vertical: 8,
          ),
          itemCount: _filteredNotifications.length,
          itemBuilder: (context, index) {
            final notification = _filteredNotifications[index];
            return _buildNotificationCard(notification, isWideScreen);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
      AppNotification notification, bool isWideScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _notificationService.markAsRead(notification.id),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead
                    ? Colors.transparent
                    : Colors.pink.withOpacity(0.5),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isWideScreen ? 20 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(notification.type),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWideScreen ? 18 : 16,
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              _formatTimestamp(notification.timestamp),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: isWideScreen ? 14 : 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: isWideScreen ? 16 : 14,
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _notificationService
                                    .markAsRead(notification.id),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.pink,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('Mark as Read'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.match:
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case NotificationType.streak:
        icon = Icons.local_fire_department;
        color = Colors.orange;
        break;
      case NotificationType.activity:
        icon = Icons.notifications_active;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildNotificationStats() {
    final totalNotifications = _notificationService.notifications.length;
    final unreadCount =
        _notificationService.notifications.where((n) => !n.isRead).length;
    final readCount = totalNotifications - unreadCount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatItem(
            icon: Icons.notifications,
            label: 'Total',
            value: totalNotifications,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            icon: Icons.mark_email_unread,
            label: 'Unread',
            value: unreadCount,
            color: Colors.pink,
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            icon: Icons.mark_email_read,
            label: 'Read',
            value: readCount,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
