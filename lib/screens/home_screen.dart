import 'package:flutter/material.dart';
import 'package:flutter_auth/models/user_profile.dart';
import 'package:flutter_auth/screens/meme_detail_screen.dart';
import 'package:flutter_auth/screens/profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meme_post.dart';
import '../services/meme_service.dart';
import '../services/auth_service.dart';
import '../widgets/notification_badge.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'premium_screen.dart';
import 'messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MemeService _memeService = MemeService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _navigateToChat(BuildContext context, MemePost meme) async {
    final userProfile = UserProfile(
      userId: meme.userId,
      name: meme.userName,
      age: 0, // You might want to fetch this from user data
      moodBoard: [],
      anthem: meme.songTitle ?? '',
      artistName: meme.artistName ?? '',
      songTitle: meme.songTitle ?? '',
      hasLikedMe: true,
      canMessage: true,
      profileImage: meme.userProfileImage,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(profile: userProfile),
      ),
    );
  }

  void _showPostMemeDialog() {
    final captionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Post a Meme',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captionController,
                decoration: const InputDecoration(
                  hintText: 'Add a caption...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? image = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        final currentUser = _authService.currentUser;
                        if (currentUser != null && mounted) {
                          try {
                            await _memeService.postMeme(
                              userId: currentUser.uid,
                              userName: currentUser.displayName ?? 'Anonymous',
                              imagePath: image.path,
                              caption: captionController.text,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Meme posted successfully!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error posting meme: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? image = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        final currentUser = _authService.currentUser;
                        if (currentUser != null && mounted) {
                          try {
                            await _memeService.postMeme(
                              userId: currentUser.uid,
                              userName: currentUser.displayName ?? 'Anonymous',
                              imagePath: image.path,
                              caption: captionController.text,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Meme posted successfully!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error posting meme: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meme Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: NotificationBadge(
              child: const Icon(Icons.notifications),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.diamond),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PremiumScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade900,
                Colors.deepPurple.shade700,
                Colors.purple.shade500,
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: currentUser.photoURL != null
                          ? NetworkImage(currentUser.photoURL!)
                          : null,
                      child: currentUser.photoURL == null
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.deepPurple)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentUser.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUser.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Profile',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.white),
                title: const Text('Messages',
                    style: TextStyle(color: Colors.white)),
                trailing: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MessagesScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.diamond, color: Colors.white),
                title: const Text('Premium',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PremiumScreen()),
                ),
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text('Settings',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help, color: Colors.white),
                title: const Text('Help & Support',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  // Navigate to help
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  await _authService.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<MemePost>>(
        stream: _memeService.getMemesFeed(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final memes = snapshot.data!;
          if (memes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No memes yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to post a meme!',
                    style: TextStyle(
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showPostMemeDialog,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Post a Meme'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              itemCount: memes.length,
              itemBuilder: (context, index) {
                final meme = memes[index];
                return FutureBuilder<bool>(
                  future: meme.canChatWith(currentUser.uid),
                  builder: (context, snapshot) {
                    final canChat = snapshot.data ?? false;
                    return _MemeCard(
                      meme: meme,
                      currentUserId: currentUser.uid,
                      onLike: () =>
                          _memeService.likeMeme(meme.id, currentUser.uid),
                      onPass: () =>
                          _memeService.passMeme(meme.id, currentUser.uid),
                      onChat:
                          canChat ? () => _navigateToChat(context, meme) : null,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostMemeDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }
}

class _MemeCard extends StatelessWidget {
  final MemePost meme;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final VoidCallback? onChat;

  const _MemeCard({
    required this.meme,
    required this.currentUserId,
    required this.onLike,
    required this.onPass,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(meme.id),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onPass();
        } else {
          onLike();
        }
      },
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.favorite, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.close, color: Colors.white, size: 32),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                backgroundImage: meme.userProfileImage != null &&
                        meme.userProfileImage!.isNotEmpty
                    ? NetworkImage(meme.userProfileImage!)
                    : null,
                child: meme.userProfileImage == null ||
                        meme.userProfileImage!.isEmpty
                    ? Text(
                        meme.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                meme.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(meme.caption),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.report),
                          title: const Text('Report'),
                          onTap: () {
                            Navigator.pop(context);
                            // Show report dialog
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.block),
                          title: const Text('Block User'),
                          onTap: () {
                            Navigator.pop(context);
                            // Show block confirmation
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemeDetailScreen(meme: meme),
                  ),
                );
              },
              onDoubleTap: onLike,
              child: Hero(
                tag: 'meme_${meme.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                  child: Image.network(
                    meme.memeUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error_outline, size: 48),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (meme.songTitle != null)
              ListTile(
                leading: const Icon(Icons.music_note, color: Colors.deepPurple),
                title: Text(meme.songTitle!),
                subtitle: Text(meme.artistName ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle),
                  onPressed: () {
                    // Play song preview
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.favorite,
                    color: meme.isLikedBy(currentUserId) ? Colors.red : null,
                    onPressed: onLike,
                    label: 'Like',
                  ),
                  _buildActionButton(
                    icon: Icons.close,
                    onPressed: onPass,
                    label: 'Pass',
                  ),
                  if (onChat != null)
                    _buildActionButton(
                      icon: Icons.chat,
                      color: Colors.deepPurple,
                      onPressed: onChat ?? () {},
                      label: 'Chat',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    Color? color,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 32, color: color),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(
            color: color ?? Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
