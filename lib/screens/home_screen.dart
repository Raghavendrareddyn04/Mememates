import 'package:flutter/material.dart';
import 'package:flutter_auth/models/user_profile.dart';
import 'package:flutter_auth/screens/meme_detail_screen.dart';
import 'package:flutter_auth/screens/profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meme_post.dart';
import '../services/meme_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/notification_badge.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import 'premium_screen.dart';
import 'messages_screen.dart';
import 'vibe_match_screen.dart';
import 'meme_creator_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MemeService _memeService = MemeService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  Map<String, dynamic>? _streakInfo;
  bool _isLoading = false;
  int _currentIndex = 1;

  // Feed Preferences
  RangeValues _ageRange = const RangeValues(18, 35);
  String? _preferredGender;
  bool _showPreferences = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadStreakInfo();
  }

  Future<void> _loadStreakInfo() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final streakInfo =
            await _memeService.getUserStreakInfo(currentUser.uid);
        setState(() {
          _streakInfo = streakInfo;
        });
      }
    } catch (e) {
      print('Error loading streak info: $e');
    }
  }

  Future<void> _loadPreferences() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final settings = await _userService.getUserSettings(currentUser.uid);
      if (settings != null) {
        setState(() {
          _ageRange = RangeValues(
            (settings['minAge'] ?? 18).toDouble(),
            (settings['maxAge'] ?? 35).toDouble(),
          );
          _preferredGender = settings['preferredGender'];
        });
      }
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const MessagesScreen();
      case 1:
        return _buildHomeContent();
      case 2:
        return const ProfileScreen();
      default:
        return const MessagesScreen();
    }
  }

  Widget _buildHomeContent() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        return CustomScrollView(
          slivers: [
            if (_streakInfo != null)
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.all(isWideScreen ? 24 : 16),
                  margin: EdgeInsets.all(isWideScreen ? 24 : 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.pink.shade900.withOpacity(0.8),
                        Colors.deepPurple.shade900.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _streakInfo!['isStreakActive']
                            ? Icons.local_fire_department
                            : Icons.timer,
                        color: _streakInfo!['isStreakActive']
                            ? Colors.orange
                            : Colors.red,
                        size: isWideScreen ? 32 : 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Streak: ${_streakInfo!['streak']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isWideScreen ? 24 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_streakInfo!['isStreakActive'])
                            Text(
                              'Post in ${_streakInfo!['hoursRemaining']}h to keep your streak!',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: isWideScreen ? 16 : 14,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showPreferences ? null : 0,
                child: _buildPreferencesPanel(),
              ),
            ),
            StreamBuilder<List<MemePost>>(
              stream: _memeService.getMemesFeed(
                currentUser.uid,
                minAge: _ageRange.start.round(),
                maxAge: _ageRange.end.round(),
                preferredGender: _preferredGender,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: isWideScreen ? 64 : 48,
                              color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                      ),
                    ),
                  );
                }

                final memes = snapshot.data!;
                if (memes.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sentiment_dissatisfied,
                            size: isWideScreen ? 80 : 64,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No memes yet',
                            style: TextStyle(
                              fontSize: isWideScreen ? 24 : 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Be the first to post a meme!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: isWideScreen ? 18 : 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _showPostMemeDialog,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Post a Meme'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isWideScreen ? 32 : 24,
                                vertical: isWideScreen ? 16 : 12,
                              ),
                              textStyle: TextStyle(
                                fontSize: isWideScreen ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsets.all(isWideScreen ? 16 : 8),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWideScreen ? 3 : 1,
                      crossAxisSpacing: isWideScreen ? 16 : 8,
                      mainAxisSpacing: isWideScreen ? 16 : 8,
                      childAspectRatio: isWideScreen ? 0.8 : 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final meme = memes[index];
                        return FutureBuilder<bool>(
                          future: meme.canChatWith(currentUser.uid),
                          builder: (context, snapshot) {
                            final canChat = snapshot.data ?? false;
                            return _MemeCard(
                              key: ValueKey(meme.id),
                              meme: meme,
                              currentUserId: currentUser.uid,
                              onLike: () {
                                _memeService.likeMeme(meme.id, currentUser.uid);
                                setState(() {});
                              },
                              onPass: () {
                                _memeService.passMeme(meme.id, currentUser.uid);
                                setState(() {});
                              },
                              onChat: canChat
                                  ? () => _navigateToChat(context, meme)
                                  : null,
                              isWideScreen: isWideScreen,
                            );
                          },
                        );
                      },
                      childCount: memes.length,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreferencesPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.shade900.withOpacity(0.8),
            Colors.deepPurple.shade900.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feed Preferences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Age Range',
            style: TextStyle(color: Colors.white),
          ),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 100,
            divisions: 82,
            activeColor: Colors.pink,
            inactiveColor: Colors.white.withOpacity(0.3),
            labels: RangeLabels(
              _ageRange.start.round().toString(),
              _ageRange.end.round().toString(),
            ),
            onChanged: (values) => setState(() => _ageRange = values),
            onChangeEnd: (values) => _savePreferences(),
          ),
          DropdownButtonFormField<String>(
            value: _preferredGender,
            dropdownColor: Colors.deepPurple,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Show Memes From',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ['All', 'Male', 'Female', 'Non-binary']
                .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _preferredGender = value);
              _savePreferences();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _savePreferences() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _userService.updateUserSettings(
        userId: currentUser.uid,
        settings: {
          'minAge': _ageRange.start.round(),
          'maxAge': _ageRange.end.round(),
          'preferredGender': _preferredGender,
        },
      );
    }
  }

  Future<void> _navigateToChat(BuildContext context, MemePost meme) async {
    final userProfile = UserProfile(
      userId: meme.userId,
      name: meme.userName,
      age: 0,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade900,
              Colors.deepPurple.shade900,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  _buildPostOptionButton(
                    icon: Icons.photo_library,
                    label: 'Choose from Gallery',
                    onPressed: () async {
                      final XFile? image = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        await _handleImagePost(image, captionController.text);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPostOptionButton(
                    icon: Icons.camera_alt,
                    label: 'Take Photo',
                    onPressed: () async {
                      final XFile? image = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        await _handleImagePost(image, captionController.text);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPostOptionButton(
                    icon: Icons.create,
                    label: 'Create Your Own Meme',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MemeCreatorScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _handleImagePost(XFile image, String caption) async {
    final currentUser = _authService.currentUser;
    if (currentUser != null && mounted) {
      try {
        await _memeService.postMeme(
          userId: currentUser.uid,
          userName: currentUser.displayName ?? 'Anonymous',
          imagePath: image.path,
          caption: caption,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meme posted successfully!'),
              backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'MemeMates',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(
                _showPreferences ? Icons.expand_less : Icons.tune,
                color: const Color.fromARGB(241, 242, 245, 245),
              ),
              onPressed: () {
                setState(() {
                  _showPreferences = !_showPreferences;
                });
              },
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink.shade900,
                Colors.deepPurple.shade900,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VibeMatchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: NotificationBadge(
              child: const Icon(Icons.notifications),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.diamond),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PremiumScreen()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade900,
              const Color.fromARGB(255, 158, 158, 159),
              Colors.deepPurple.shade900,
            ],
          ),
        ),
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade900,
              Colors.deepPurple.shade900,
            ],
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: _showPostMemeDialog,
              backgroundColor: Colors.pink,
              child: const Icon(Icons.add_photo_alternate),
            )
          : null,
    );
  }
}

class _MemeCard extends StatefulWidget {
  final MemePost meme;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final VoidCallback? onChat;
  final bool isWideScreen;

  const _MemeCard({
    super.key,
    required this.meme,
    required this.currentUserId,
    required this.onLike,
    required this.onPass,
    this.onChat,
    required this.isWideScreen,
  });

  @override
  State<_MemeCard> createState() => _MemeCardState();
}

class _MemeCardState extends State<_MemeCard> {
  bool _isLiked = false;
  bool _isPassed = false;
  bool _isProcessing = false;
  bool _isRemoved = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.meme.isLikedBy(widget.currentUserId);
    _isPassed = widget.meme.isPassedBy(widget.currentUserId);
  }

  Future<void> _handleLike() async {
    if (_isProcessing) return;

    setState(() {
      _isLiked = true;
      _isProcessing = true;
      _isRemoved = true;
    });

    try {
      widget.onLike();
    } catch (e) {
      setState(() {
        _isLiked = false;
        _isRemoved = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handlePass() async {
    if (_isProcessing) return;

    setState(() {
      _isPassed = true;
      _isProcessing = true;
      _isRemoved = true;
    });

    try {
      widget.onPass();
    } catch (e) {
      setState(() {
        _isPassed = false;
        _isRemoved = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRemoved) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key(widget.meme.id),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _handlePass();
        } else {
          _handleLike();
        }
      },
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade700],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.favorite, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade700],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.close, color: Colors.white, size: 32),
      ),
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: widget.isWideScreen ? 8 : 12,
          vertical: widget.isWideScreen ? 8 : 6,
        ),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.deepPurple.shade100,
                          backgroundImage:
                              widget.meme.userProfileImage != null &&
                                      widget.meme.userProfileImage!.isNotEmpty
                                  ? NetworkImage(widget.meme.userProfileImage!)
                                  : null,
                          child: widget.meme.userProfileImage == null ||
                                  widget.meme.userProfileImage!.isEmpty
                              ? Text(
                                  widget.meme.userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          widget.meme.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          widget.meme.caption,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MemeDetailScreen(meme: widget.meme),
                              ),
                            );
                          },
                          onDoubleTap: _handleLike,
                          child: Hero(
                            tag: 'meme_${widget.meme.id}',
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(widget.meme.memeUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.meme.songTitle != null)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.music_note,
                              color: Colors.deepPurple),
                          title: Text(
                            widget.meme.songTitle!,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: widget.meme.artistName != null
                              ? Text(
                                  widget.meme.artistName!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.play_circle),
                            onPressed: () {
                              // Play song preview
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.favorite,
                              color: _isLiked ? Colors.red : null,
                              onPressed: _handleLike,
                              label: 'Like',
                              isProcessing: _isProcessing && _isLiked,
                            ),
                            _buildActionButton(
                              icon: Icons.close,
                              onPressed: _handlePass,
                              label: 'Pass',
                              isProcessing: _isProcessing && _isPassed,
                            ),
                            if (widget.onChat != null)
                              _buildActionButton(
                                icon: Icons.chat,
                                color: Colors.deepPurple,
                                onPressed: widget.onChat ?? () {},
                                label: 'Chat',
                                isProcessing: false,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    Color? color,
    required VoidCallback onPressed,
    required String label,
    required bool isProcessing,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: isProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 28, color: color),
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
