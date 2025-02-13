import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/meme_service.dart';
import '../models/meme_post.dart';
import 'profile_edit_screen.dart';
import 'settings_screen.dart';
import 'mood_board_editor_screen.dart';
import '../widgets/spotify_player.dart';
import '../widgets/spotify_track_picker.dart';
import '../services/spotify_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _memeService = MemeService();
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _streakInfo;
  List<MemePost> _likedMemes = [];
  int _postedMemesCount = 0;
  int _likedMemesCount = 0;
  bool _showPostedMemes = true;
  SpotifyTrack? _selectedTrack;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadMemeCounts();
    _loadStreakInfo();
    _loadLikedMemes();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        final profile = await _userService.getUserProfile(currentUser.uid);
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMemeCounts() async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        final postedMemes =
            await _memeService.getUserMemes(currentUser.uid).first;
        final likedMemes = await _memeService.getLikedMemes(currentUser.uid);

        setState(() {
          _postedMemesCount = postedMemes.length;
          _likedMemesCount = likedMemes.length;
        });
      }
    } catch (e) {
      print('Error loading meme counts: $e');
    }
  }

  Future<void> _loadStreakInfo() async {
    try {
      final currentUser = _userService.currentUser;
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

  Future<void> _loadLikedMemes() async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        final likedMemes = await _memeService.getLikedMemes(currentUser.uid);
        setState(() {
          _likedMemes = likedMemes;
        });
      }
    } catch (e) {
      print('Error loading liked memes: $e');
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

  void _showSpotifyTrackPicker() {
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
              child: SpotifyTrackPicker(
                onTrackSelected: (track) async {
                  setState(() => _selectedTrack = track);
                  final currentUser = _userService.currentUser;
                  if (currentUser != null) {
                    await _userService.updateUserProfile(
                      userId: currentUser.uid,
                      anthem: track.uri,
                      artistName: track.artist,
                      songTitle: track.name,
                      interests:
                          List<String>.from(_userProfile?['interests'] ?? []),
                    );
                    await _loadUserProfile();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodBoardSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mood Board',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 24 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
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
                                  content:
                                      Text('Error updating mood board: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmallScreen ? 3 : 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: (_userProfile?['moodBoardImages'] as List?)?.length ?? 0,
          itemBuilder: (context, index) {
            final images =
                List<String>.from(_userProfile?['moodBoardImages'] ?? []);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(images[index]),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMusicSection() {
    final hasAnthem = _userProfile?['anthem'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Music',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton.icon(
              onPressed: _showSpotifyTrackPicker,
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
          SpotifyPlayer(
            trackUri: _userProfile!['anthem'],
            trackName: _userProfile!['songTitle'] ?? '',
            artistName: _userProfile!['artistName'] ?? '',
            albumArt: _selectedTrack?.albumArt ?? '',
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

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
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _openEditProfile,
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _openSettings,
                                icon: const Icon(Icons.settings,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            icon: Icons.post_add,
                            label: 'Posts',
                            value: _postedMemesCount.toString(),
                            isSelected: _showPostedMemes,
                            onTap: () =>
                                setState(() => _showPostedMemes = true),
                          ),
                          _buildStatCard(
                            icon: Icons.favorite,
                            label: 'Likes',
                            value: _likedMemesCount.toString(),
                            isSelected: !_showPostedMemes,
                            onTap: () =>
                                setState(() => _showPostedMemes = false),
                          ),
                          if (_streakInfo != null)
                            _buildStatCard(
                              icon: Icons.local_fire_department,
                              label: 'Streak',
                              value: _streakInfo!['streak'].toString(),
                              isSelected: false,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        title: 'About',
                        content: Column(
                          children: [
                            _buildInfoRow(
                                'Age', '${_userProfile?['age'] ?? 'Not set'}'),
                            _buildInfoRow(
                                'Gender', _userProfile?['gender'] ?? 'Not set'),
                            _buildInfoRow('Interested In',
                                _userProfile?['preferredGender'] ?? 'Not set'),
                            if (_userProfile?['bio'] != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bio',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _userProfile!['bio'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_userProfile?['interests'] != null &&
                          (_userProfile!['interests'] as List).isNotEmpty)
                        _buildSection(
                          title: 'Interests',
                          content: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_userProfile!['interests'] as List)
                                .map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.pink.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  interest,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildMusicSection(),
                      const SizedBox(height: 24),
                      _buildMoodBoardSection(isSmallScreen),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: _showPostedMemes ? 'Your Memes' : 'Liked Memes',
                        content: _showPostedMemes
                            ? StreamBuilder<List<MemePost>>(
                                stream: _memeService.getUserMemes(
                                    _userService.currentUser!.uid),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isSmallScreen ? 2 : 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) =>
                                        _buildMemeCard(snapshot.data![index]),
                                  );
                                },
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isSmallScreen ? 2 : 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _likedMemes.length,
                                itemBuilder: (context, index) =>
                                    _buildMemeCard(_likedMemes[index]),
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
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
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
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color ?? Colors.white,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemeCard(MemePost meme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: NetworkImage(meme.memeUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meme.caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (meme.songTitle != null) ...[
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
                      meme.songTitle!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
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
    );
  }
}
