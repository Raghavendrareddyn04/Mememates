import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_auth/models/user_profile.dart';
import 'package:flutter_auth/screens/meme_detail_screen.dart';
import 'package:flutter_auth/screens/profile_screen.dart';
import 'package:flutter_auth/screens/video_feed_screen.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
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
import 'discovery_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MemeService _memeService = MemeService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  Map<String, dynamic>? _streakInfo;
  final bool _isLoading = false;
  int _currentIndex = 1;
  bool _isVideoMode = false;

  // Feed Preferences
  RangeValues _ageRange = const RangeValues(18, 35);
  String? _preferredGender;
  bool _showPreferences = false;

  // Animation controllers
  late AnimationController _fabController;
  late AnimationController _preferencesController;
  late Animation<double> _fabAnimation;
  late TabController _feedTabController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPreferences();
    _loadStreakInfo();
    _feedTabController = TabController(length: 2, vsync: this);
    _feedTabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_feedTabController.indexIsChanging) {
      setState(() {
        _isVideoMode = _feedTabController.index == 1;
      });
    }
  }

  void _initializeAnimations() {
    // FAB animation
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOut,
    );

    // Preferences panel animation
    _preferencesController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
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
        return const DiscoveryScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const MessagesScreen();
    }
  }

  Widget _buildHomeContent() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return const SizedBox();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.pink.shade900,
                Colors.deepPurple.shade900,
              ],
            ),
          ),
          child: TabBar(
            controller: _feedTabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white, // Selected tab text color
            unselectedLabelColor: Colors.white, // Unselected tab text color
            tabs: const [
              Tab(
                icon: Icon(Icons.photo_library,
                    color: Colors.white), // Icon in white
                child: Text('Memes',
                    style: TextStyle(color: Colors.white)), // Text in white
              ),
              Tab(
                icon: Icon(Icons.video_collection,
                    color: Colors.white), // Icon in white
                child: Text('Videos',
                    style: TextStyle(color: Colors.white)), // Text in white
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _feedTabController,
            children: [
              _buildMemeFeed(currentUser),
              const VideoFeedScreen(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemeFeed(currentUser) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        final isLargeScreen = constraints.maxWidth > 1200;

        return CustomScrollView(
          slivers: [
            if (_streakInfo != null)
              SliverToBoxAdapter(
                child: _buildStreakCard(isWideScreen),
              ),
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showPreferences ? null : 0,
                child: _buildPreferencesPanel(isWideScreen),
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
                    child: _buildErrorState(snapshot.error.toString()),
                  );
                }

                if (!snapshot.hasData) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: LoadingAnimation(
                        message: "Finding your perfect meme match...",
                      ),
                    ),
                  );
                }

                final memes = snapshot.data!;
                if (memes.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(isWideScreen),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 32 : 16,
                    vertical: 16,
                  ),
                  sliver: isLargeScreen
                      ? _buildLargeScreenGrid(memes, currentUser.uid)
                      : _buildResponsiveGrid(
                          memes, currentUser.uid, isWideScreen),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakCard(bool isWideScreen) {
    return Container(
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
            color: _streakInfo!['isStreakActive'] ? Colors.orange : Colors.red,
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
    );
  }

  Widget _buildPreferencesPanel(bool isWideScreen) {
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
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _preferredGender,
            dropdownColor: Colors.deepPurple,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Show Content From',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isWideScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isVideoMode ? Icons.video_library : Icons.sentiment_dissatisfied,
              size: isWideScreen ? 80 : 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _isVideoMode ? 'No videos yet' : 'No memes yet',
              style: TextStyle(
                fontSize: isWideScreen ? 24 : 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isVideoMode
                  ? 'Be the first to share a video!'
                  : 'Be the first to post a meme!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isWideScreen ? 18 : 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showPostMemeDialog,
              icon: Icon(_isVideoMode
                  ? Icons.video_library
                  : Icons.add_photo_alternate),
              label: Text(_isVideoMode ? 'Upload Video' : 'Post a Meme'),
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

  Widget _buildLargeScreenGrid(List<MemePost> memes, String currentUserId) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= memes.length) return null;
          return _buildMemeCard(memes[index], currentUserId, true);
        },
        childCount: memes.length,
      ),
    );
  }

  Widget _buildResponsiveGrid(
      List<MemePost> memes, String currentUserId, bool isWideScreen) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 2 : 1,
        crossAxisSpacing: isWideScreen ? 16 : 8,
        mainAxisSpacing: isWideScreen ? 16 : 8,
        childAspectRatio: isWideScreen ? 0.8 : 0.9,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= memes.length) return null;
          return _buildMemeCard(memes[index], currentUserId, isWideScreen);
        },
        childCount: memes.length,
      ),
    );
  }

  Widget _buildMemeCard(
      MemePost meme, String currentUserId, bool isWideScreen) {
    return FutureBuilder<bool>(
      key: ValueKey(meme.id),
      future: meme.canChatWith(currentUserId),
      builder: (context, snapshot) {
        final canChat = snapshot.data ?? false;
        return _MemeCard(
          meme: meme,
          currentUserId: currentUserId,
          onLike: () async {
            await _memeService.likeMeme(meme.id, currentUserId);
          },
          onPass: () async {
            await _memeService.passMeme(meme.id, currentUserId);
          },
          onChat: canChat ? () => _navigateToChat(context, meme) : null,
          isWideScreen: isWideScreen,
        );
      },
    );
  }

  Future<void> _navigateToChat(BuildContext context, MemePost meme) async {
    final userProfile = UserProfile(
      userId: meme.userId,
      name: meme.userName,
      age: 0,
      moodBoard: [],
      artistName: meme.artistName ?? '',
      trackTitle: meme.videoTitle ?? '',
      gender: 'Not specified',
      preferredGender: _preferredGender ?? 'All',
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
              Text(
                _isVideoMode ? 'Share a Video' : 'Post a Meme',
                style: const TextStyle(
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
                    label: _isVideoMode
                        ? 'Choose Video from Gallery'
                        : 'Choose from Gallery',
                    onPressed: () async {
                      final XFile? media = _isVideoMode
                          ? await _imagePicker.pickVideo(
                              source: ImageSource.gallery)
                          : await _imagePicker.pickImage(
                              source: ImageSource.gallery);
                      if (media != null) {
                        _showPostConfirmation(media, captionController.text);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPostOptionButton(
                    icon: _isVideoMode ? Icons.videocam : Icons.camera_alt,
                    label: _isVideoMode ? 'Record Video' : 'Take Photo',
                    onPressed: () async {
                      final XFile? media = _isVideoMode
                          ? await _imagePicker.pickVideo(
                              source: ImageSource.camera)
                          : await _imagePicker.pickImage(
                              source: ImageSource.camera);
                      if (media != null) {
                        _showPostConfirmation(media, captionController.text);
                      }
                    },
                  ),
                  if (!_isVideoMode) ...[
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

  void _showPostConfirmation(XFile media, String caption) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _isVideoMode ? 'Post Video?' : 'Post Meme?',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isVideoMode)
                FutureBuilder<Uint8List>(
                  future: media.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: LoadingAnimation(
                          message: "Loading preview...",
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: Text('Error loading preview')),
                      );
                    }
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              if (caption.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  caption,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              _handleMediaPost(media, caption);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMediaPost(XFile media, String caption) async {
    final currentUser = _authService.currentUser;
    if (currentUser != null && mounted) {
      try {
        if (_isVideoMode) {
          await _memeService.postVideo(
            userId: currentUser.uid,
            userName: currentUser.displayName ?? 'Anonymous',
            videoPath: media.path,
            caption: caption,
          );
        } else {
          await _memeService.postMeme(
            userId: currentUser.uid,
            userName: currentUser.displayName ?? 'Anonymous',
            imagePath: media.path,
            caption: caption,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isVideoMode
                  ? 'Video posted successfully!'
                  : 'Meme posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error posting ${_isVideoMode ? 'video' : 'meme'}: $e'),
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
        body: Center(
          child: LoadingAnimation(
            message: "Finding your perfect meme match...",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _currentIndex == 1
          ? AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  const Text(
                    'MemeMates',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  if (_currentIndex == 1)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune,
                              color: _showPreferences
                                  ? Colors.pink
                                  : const Color.fromARGB(241, 242, 245, 245),
                              size: 20,
                            ),
                            if (_showPreferences) const SizedBox(width: 4),
                            if (_showPreferences)
                              const Icon(
                                Icons.expand_less,
                                color: Color.fromARGB(241, 242, 245, 245),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _showPreferences = !_showPreferences;
                          if (_showPreferences) {
                            _preferencesController.forward();
                          } else {
                            _preferencesController.reverse();
                          }
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
                      Colors.purple.shade900,
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.white),
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
                    child: const Icon(Icons.notifications, color: Colors.red),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.diamond, color: Colors.amber),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PremiumScreen(),
                    ),
                  ),
                ),
              ],
            )
          : AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                _currentIndex == 0
                    ? 'Messages'
                    : _currentIndex == 2
                        ? 'Discover'
                        : 'Profile',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.pink.shade900,
                      Colors.purple.shade900,
                    ],
                  ),
                ),
              ),
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
          type: BottomNavigationBarType.fixed,
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
              icon: Icon(Icons.explore),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 1
          ? Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ScaleTransition(
                    scale: _fabAnimation,
                    child: FloatingActionButton.extended(
                      onPressed: _showPostMemeDialog,
                      backgroundColor: Colors.pink,
                      icon: Icon(_isVideoMode
                          ? Icons.video_library
                          : Icons.add_photo_alternate),
                      label: Text(_isVideoMode ? 'Upload Video' : 'Create'),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16, right: 16),
                    child: FloatingActionButton(
                      onPressed: _showPostMemeDialog,
                      backgroundColor: Colors.pink,
                      child: Icon(_isVideoMode
                          ? Icons.video_library
                          : Icons.add_photo_alternate),
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _preferencesController.dispose();
    _feedTabController.dispose();
    super.dispose();
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

class _MemeCardState extends State<_MemeCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isPassed = false;
  bool _isProcessing = false;
  bool _showRevertOption = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final Random _random = Random();

  final List<String> _datingQuotes = [
    "Sometimes the perfect match comes when you least expect it! 💫",
    "Your meme game is strong, and so is your heart! 💝",
    "Great minds meme alike! 🎭",
    "You've got great taste in memes! 🌟",
    "That's a match made in meme heaven! ✨",
    "Keep spreading the joy, one meme at a time! 🎪",
    "When memes align, magic happens! 🌈",
    "Your sense of humor is truly one of a kind! 🎯",
  ];
  final List<String> _passMessages = [
    "No worries, plenty more memes to explore! 🌟",
    "Changed your mind? Give it another chance! 🔄",
    "Keep swiping, your perfect meme match awaits! ✨",
    "Not your style? That's totally fine! 👍",
    "Next one might be the one! 🎯",
    "Trust your instincts and keep exploring! 🚀"
  ];

  String _currentQuote = '';

  @override
  void initState() {
    super.initState();
    _isLiked = widget.meme.isLikedBy(widget.currentUserId);
    _isPassed = widget.meme.isPassedBy(widget.currentUserId);
    _initializeAnimation();
    _currentQuote = _datingQuotes[_random.nextInt(_datingQuotes.length)];
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _handleLike() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _isLiked = true;
      _showRevertOption = false;
      _currentQuote = _datingQuotes[_random.nextInt(_datingQuotes.length)];
    });

    await _animationController.forward();

    try {
      widget.onLike();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      await _animationController.reverse();
    }
  }

  Future<void> _handlePass() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _isPassed = true;
      _showRevertOption = true;
      _currentQuote = _passMessages[_random.nextInt(_passMessages.length)];
    });

    await _animationController.forward();

    try {
      widget.onPass();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPassed = false;
          _showRevertOption = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      await _animationController.reverse();
    }
  }

  Future<void> _handleRevert() async {
    await _animationController.forward();
    setState(() {
      _isPassed = false;
      _showRevertOption = false;
    });
    await _animationController.reverse();
  }

  Widget _buildPlaceholder() {
    if (_isLiked) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink.shade400,
                Colors.purple.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.shade200.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentQuote,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Keep swiping to find more matches!",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else if (_isPassed && _showRevertOption) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade800,
                Colors.grey.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.undo,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentQuote,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Changed your mind?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Don't worry, we all make quick decisions sometimes!",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleRevert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text(
                            "Give it another chance",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLiked || (_isPassed && _showRevertOption)) {
      return _buildPlaceholder();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dismissible(
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
                            backgroundImage: widget.meme.userProfileImage !=
                                        null &&
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.meme.caption,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.meme.timestamp,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.block),
                                      title: const Text('Block User'),
                                      onTap: () {
                                        Navigator.pop(context);
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
                        if (widget.meme.videoTitle != null)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.music_note,
                                color: Colors.deepPurple),
                            title: Text(
                              widget.meme.videoTitle!,
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
                              onPressed: () {},
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
                  child: LoadingAnimation(
                    message: "Finding your perfect meme match...",
                  ),
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
