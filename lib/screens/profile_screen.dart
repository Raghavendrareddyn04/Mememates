import 'package:flutter/material.dart';
import 'package:flutter_auth/screens/connections_screen.dart';
import 'package:flutter_auth/screens/mood_board_upload_screen.dart';
import 'package:flutter_auth/services/meme_service.dart';
import 'package:flutter_auth/services/user_service.dart';
import 'package:flutter_auth/widgets/audius_player.dart';
import 'package:flutter_auth/widgets/audius_track_picker.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
import '../models/meme_post.dart';
import 'profile_edit_screen.dart';
import 'settings_screen.dart';
import 'mood_board_editor_screen.dart';
import 'package:flutter_auth/widgets/meme_media.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _userService = UserService();
  final _memeService = MemeService();
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _streakInfo;
  List<MemePost> _likedMemes = [];
  int _postedMemesCount = 0;
  int _likedMemesCount = 0;
  int _connectionsCount = 0;
  bool _showPostedMemes = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserProfile();
    _loadMemeCounts();
    _loadStreakInfo();
    _loadLikedMemes();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadUserProfile() async {
    if (!_mounted) return;
    try {
      setState(() => _isLoading = true);
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        final profile = await _userService.getUserProfile(currentUser.uid);

        final connections =
            await _userService.getUserConnections(currentUser.uid).first;

        if (profile != null && _mounted) {
          setState(() {
            _userProfile = {
              'name': profile.name,
              'age': profile.age,
              'bio': profile.bio,
              'profileImage': profile.profileImage,
              'moodBoardImages': profile.moodBoard,
              'audiusTrackId': profile.audiusTrackId,
              'trackTitle': profile.trackTitle,
              'artistName': profile.artistName,
              'interests': profile.interests ?? [],
            };
            _connectionsCount = connections.length;
          });
        }
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMemeCounts() async {
    if (!_mounted) return;
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        final postedMemes =
            await _memeService.getUserMemes(currentUser.uid).first;
        final likedMemes = await _memeService.getLikedMemes(currentUser.uid);

        if (_mounted) {
          setState(() {
            _postedMemesCount = postedMemes.length;
            _likedMemesCount = likedMemes.length;
          });
        }
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meme counts: $e')),
        );
      }
    }
  }

  Future<void> _loadStreakInfo() async {
    if (!_mounted) return;
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        final streakInfo =
            await _memeService.getUserStreakInfo(currentUser.uid);
        if (_mounted) {
          setState(() {
            _streakInfo = streakInfo;
          });
        }
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading streak info: $e')),
        );
      }
    }
  }

  Future<void> _loadLikedMemes() async {
    if (!_mounted) return;
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        final likedMemes = await _memeService.getLikedMemes(currentUser.uid);
        if (_mounted) {
          setState(() {
            _likedMemes = likedMemes;
          });
        }
      }
    } catch (e) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading liked memes: $e')),
        );
      }
    }
  }

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(
          initialProfile: _userProfile,
          onProfileUpdated: () {
            _loadUserProfile();
          },
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _showAudiusTrackPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select Your Anthem',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AudiusTrackPicker(
                onTrackSelected: (track) async {
                  try {
                    final currentUser = _userService.currentUser;
                    if (currentUser != null) {
                      await _userService.updateUserProfile(
                        userId: currentUser.uid,
                        audiusTrackId: track['id'],
                        trackTitle: track['title'],
                        artistName: track['user'],
                        interests:
                            List<String>.from(_userProfile?['interests'] ?? []),
                      );
                      await _loadUserProfile();
                    }
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating anthem: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
          child: const Center(
            child: LoadingAnimation(
              message: "Loading your profile...",
            ),
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isLargeScreen = size.width > 1200;

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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: isLargeScreen
                    ? _buildLargeScreenLayout()
                    : _buildResponsiveLayout(isSmallScreen),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      children: [
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            border: Border(
              right: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          child: _buildSidebarContent(),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildMusicSection(),
                            const SizedBox(height: 24),
                            _buildMoodBoardSection(false),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildUserStats(),
                            const SizedBox(height: 24),
                            _buildMemesSection(false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveLayout(bool isSmallScreen) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          expandedHeight: 0,
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _openEditProfile,
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _openSettings,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
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
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildProfileHeader(isSmallScreen),
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                child: Column(
                  children: [
                    _buildUserStats(),
                    const SizedBox(height: 24),
                    _buildMusicSection(),
                    const SizedBox(height: 24),
                    _buildMoodBoardSection(isSmallScreen),
                    const SizedBox(height: 24),
                    _buildMemesSection(isSmallScreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      children: [
        const SizedBox(height: 32),
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white.withOpacity(0.2),
          backgroundImage: _userProfile?['profileImage'] != null
              ? NetworkImage(_userProfile!['profileImage'])
              : null,
          child: _userProfile?['profileImage'] == null
              ? Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white.withOpacity(0.8),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          _userProfile?['name'] ?? 'Not set',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (_userProfile?['bio'] != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _userProfile!['bio'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 32),
        _buildSidebarStats(),
        const Spacer(),
        _buildSidebarActions(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSidebarStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildStatRow(
            icon: Icons.post_add,
            label: 'Posts',
            value: _postedMemesCount.toString(),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            icon: Icons.favorite,
            label: 'Likes',
            value: _likedMemesCount.toString(),
          ),
          if (_streakInfo != null) ...[
            const SizedBox(height: 16),
            _buildStatRow(
              icon: Icons.local_fire_department,
              label: 'Streak',
              value: _streakInfo!['streak'].toString(),
              color: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Colors.pink).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? Colors.pink, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarActions() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _openEditProfile,
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _openSettings,
          icon: const Icon(Icons.settings),
          label: const Text('Settings'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 50 : 60,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: _userProfile?['profileImage'] != null
                ? NetworkImage(_userProfile!['profileImage'])
                : null,
            child: _userProfile?['profileImage'] == null
                ? Icon(
                    Icons.person,
                    size: isSmallScreen ? 50 : 60,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?['name'] ?? 'Not set',
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_userProfile?['bio'] != null) ...[
            const SizedBox(height: 8),
            Text(
              _userProfile!['bio'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.post_add,
                      value: _postedMemesCount.toString(),
                      label: 'Posts',
                      color: Colors.green,
                      onTap: () => setState(() => _showPostedMemes = true),
                      isSelected: _showPostedMemes,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.favorite,
                      value: _likedMemesCount.toString(),
                      label: 'Likes',
                      color: Colors.pink,
                      onTap: () => setState(() => _showPostedMemes = false),
                      isSelected: !_showPostedMemes,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.people,
                      value: _connectionsCount.toString(),
                      label: 'Connections',
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConnectionsScreen(),
                        ),
                      ),
                    ),
                  ),
                  if (_streakInfo != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.local_fire_department,
                        value: _streakInfo!['streak'].toString(),
                        label: 'Streak',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicSection() {
    final hasAnthem = _userProfile?['audiusTrackId'] != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Anthem',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: _showAudiusTrackPicker,
                icon: const Icon(Icons.edit, color: Colors.pink),
                label: Text(
                  hasAnthem ? 'Change Song' : 'Add Song',
                  style: const TextStyle(color: Colors.pink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasAnthem)
            AudiusPlayer(
              trackId: _userProfile!['audiusTrackId'],
              title: _userProfile!['trackTitle'] ?? '',
              artistName: _userProfile!['artistName'] ?? '',
              artwork: _userProfile!['artwork'],
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.music_note,
                    size: 48,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No anthem selected',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your favorite song to express your vibe',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoodBoardSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mood Board',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.edit, color: Colors.pink),
                color: Colors.deepPurple.shade900,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'upload',
                    child: Row(
                      children: [
                        Icon(Icons.upload, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Upload Images',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'editor',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Open Editor',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'upload') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MoodBoardUploadScreen(
                          initialImages: List<String>.from(
                              _userProfile?['moodBoardImages'] ?? []),
                          onSave: (updatedImages) async {
                            try {
                              final currentUser = _userService.currentUser;
                              if (currentUser != null) {
                                await _userService.updateUserProfile(
                                  userId: currentUser.uid,
                                  moodBoardImages: updatedImages,
                                  interests: List<String>.from(
                                      _userProfile?['interests'] ?? []),
                                );
                                await _loadUserProfile();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error updating mood board: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  } else if (value == 'editor') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MoodBoardEditorScreen(
                          initialImages: List<String>.from(
                              _userProfile?['moodBoardImages'] ?? []),
                          onSave: (updatedImages) async {
                            try {
                              final currentUser = _userService.currentUser;
                              if (currentUser != null) {
                                await _userService.updateUserProfile(
                                  userId: currentUser.uid,
                                  moodBoardImages: updatedImages,
                                  interests: List<String>.from(
                                      _userProfile?['interests'] ?? []),
                                );
                                await _loadUserProfile();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error updating mood board: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if ((_userProfile?['moodBoardImages'] as List?)?.isEmpty ?? true)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.image,
                    size: 48,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your mood board is empty',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add images that represent your vibe',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 2 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount:
                  (_userProfile?['moodBoardImages'] as List?)?.length ?? 0,
              itemBuilder: (context, index) {
                final imageUrl =
                    (_userProfile?['moodBoardImages'] as List)[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.white.withOpacity(0.5),
                          size: 32,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMemesSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _showPostedMemes ? 'My Memes' : 'Liked Memes',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _showPostedMemes
              ? StreamBuilder<List<MemePost>>(
                  stream:
                      _memeService.getUserMemes(_userService.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: LoadingAnimation(
                          message: "Loading your memes...",
                        ),
                      );
                    }
                    return _buildMemeGrid(snapshot.data!, isSmallScreen);
                  },
                )
              : _buildMemeGrid(_likedMemes, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildMemeGrid(List<MemePost> memes, bool isSmallScreen) {
    if (memes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              _showPostedMemes ? Icons.post_add : Icons.favorite,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _showPostedMemes
                  ? 'You haven\'t posted any memes yet'
                  : 'No liked memes yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showPostedMemes
                  ? 'Share your first meme with the community!'
                  : 'Start liking memes to see them here',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: memes.length,
      itemBuilder: (context, index) {
        final meme = memes[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MemeMedia(
                  url: meme.memeUrl,
                  isVideo: meme.isVideo,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        meme.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (meme.videoId != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                meme.videoTitle!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
        );
      },
    );
  }

  @override
  void dispose() {
    _mounted = false;
    _animationController.dispose();
    super.dispose();
  }
}
