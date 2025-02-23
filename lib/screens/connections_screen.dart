import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/connection.dart';
import '../services/user_service.dart';
import '../widgets/loading_animation.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final UserService _userService = UserService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 1200;
    final currentUser = _userService.currentUser;

    if (currentUser == null) return const SizedBox();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade900,
              Colors.purple.shade900,
              Colors.deepPurple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(isSmallScreen),

              // Search
              _buildSearch(isSmallScreen),

              // Connections List
              Expanded(
                child: StreamBuilder<List<Connection>>(
                  stream: _userService.getUserConnections(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: LoadingAnimation(
                          message: "Loading your connections...",
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    var connections = snapshot.data!;

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      connections = connections
                          .where((c) => c.userName
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList();
                    }

                    // Sort by most recent first
                    connections
                        .sort((a, b) => b.connectedAt.compareTo(a.connectedAt));

                    if (isSmallScreen) {
                      return _buildMobileList(connections);
                    } else if (isMediumScreen) {
                      return _buildTabletGrid(connections);
                    } else {
                      return _buildDesktopGrid(connections);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Text(
            'Connections',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 24 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildSearch(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search connections...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOut).fadeIn(),
          const SizedBox(height: 16),
          Text(
            'No connections yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'Start connecting with other users!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<Connection> connections) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connection = connections[index];
        return _buildConnectionCard(connection, true)
            .animate()
            .fadeIn(delay: (50 * index).ms)
            .slideX(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildTabletGrid(List<Connection> connections) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connection = connections[index];
        return _buildConnectionCard(connection, false)
            .animate()
            .fadeIn(delay: (50 * index).ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
      },
    );
  }

  Widget _buildDesktopGrid(List<Connection> connections) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connection = connections[index];
        return _buildConnectionCard(connection, false)
            .animate()
            .fadeIn(delay: (50 * index).ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
      },
    );
  }

  Widget _buildConnectionCard(Connection connection, bool isMobile) {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return const SizedBox();

    return Card(
      color: Colors.white.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to connection profile
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 24 : 32,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: connection.profileImage != null
                    ? NetworkImage(connection.profileImage!)
                    : null,
                child: connection.profileImage == null
                    ? Text(
                        connection.userName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      connection.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connected ${_formatDate(connection.connectedAt)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.white.withOpacity(0.7),
                ),
                color: Colors.grey.shade900,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'message',
                    child: Row(
                      children: [
                        Icon(Icons.message, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Message',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.pink, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Remove',
                          style: TextStyle(color: Colors.pink),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'remove') {
                    _showRemoveConnectionDialog(
                      context,
                      connection,
                      currentUser.uid,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  Future<void> _showRemoveConnectionDialog(
    BuildContext context,
    Connection connection,
    String currentUserId,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Remove Connection',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove ${connection.userName} from your connections?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.removeConnection(
                  currentUserId,
                  connection.userId,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Removed ${connection.userName} from connections',
                      ),
                      backgroundColor: Colors.pink,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
