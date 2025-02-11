import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/meme_service.dart';
import '../models/meme_post.dart';
import 'profile_edit_screen.dart';

class _StreakTimer extends StatelessWidget {
  final int hoursRemaining;
  final int currentStreak;
  final bool isStreakActive;

  const _StreakTimer({
    required this.hoursRemaining,
    required this.currentStreak,
    required this.isStreakActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isStreakActive ? Icons.local_fire_department : Icons.timer,
                color: isStreakActive ? Colors.orange : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Streak: $currentStreak',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isStreakActive) ...[
            const SizedBox(height: 8),
            Text(
              'Post a meme in ${hoursRemaining}h to keep your streak!',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _LikedMemesGrid extends StatelessWidget {
  final List<MemePost> memes;
  final Function(String) onPass;

  const _LikedMemesGrid({
    required this.memes,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: memes.length,
      itemBuilder: (context, index) {
        final meme = memes[index];
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(meme.memeUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                color: Colors.white,
                onPressed: () => onPass(meme.id),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _memeService = MemeService();
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _streakInfo;
  List<MemePost> _likedMemes = [];
  int _postedMemesCount = 0;
  int _likedMemesCount = 0;
  bool _showPostedMemes = true;

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
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _handlePassMeme(String memeId) async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        await _memeService.passMeme(memeId, currentUser.uid);
        await _memeService.removeLikedMeme(memeId, currentUser.uid);
        await _loadLikedMemes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error passing meme: $e')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUser = _userService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openEditProfile,
          ),
        ],
      ),
      body: Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: _userProfile?['profileImage'] != null
                          ? NetworkImage(_userProfile!['profileImage'])
                          : null,
                      child: _userProfile?['profileImage'] == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
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
                  ],
                ),
              ),
              if (_streakInfo != null) ...[
                const SizedBox(height: 24),
                _StreakTimer(
                  hoursRemaining: _streakInfo!['hoursRemaining'],
                  currentStreak: _streakInfo!['streak'],
                  isStreakActive: _streakInfo!['isStreakActive'],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showPostedMemes = true),
                    child: _buildStatCard(
                      icon: Icons.post_add,
                      label: 'Posted',
                      value: _postedMemesCount.toString(),
                      isSelected: _showPostedMemes,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showPostedMemes = false),
                    child: _buildStatCard(
                      icon: Icons.favorite,
                      label: 'Liked',
                      value: _likedMemesCount.toString(),
                      isSelected: !_showPostedMemes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoCard(
                title: 'Age',
                content: _userProfile?['age']?.toString() ?? 'Not set',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Gender',
                content: _userProfile?['gender'] ?? 'Not set',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Interested In',
                content: _userProfile?['preferredGender'] ?? 'Not set',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Bio',
                content: _userProfile?['bio'] ?? 'No bio yet',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Interests',
                content: (_userProfile?['interests'] as List<dynamic>?)
                        ?.join(', ') ??
                    'No interests added',
              ),
              const SizedBox(height: 24),
              const Text(
                'Mood Board',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (_userProfile?['moodBoardImages'] != null)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: (_userProfile!['moodBoardImages'] as List).length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(
                            _userProfile!['moodBoardImages'][index],
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              _buildInfoCard(
                title: 'Anthem',
                content: _userProfile?['anthem'] ?? 'No anthem selected',
                icon: Icons.music_note,
              ),
              if (_userProfile?['artistName'] != null) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Artist',
                  content: _userProfile!['artistName'],
                  icon: Icons.person,
                ),
              ],
              if (_userProfile?['songTitle'] != null) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Song',
                  content: _userProfile!['songTitle'],
                  icon: Icons.music_note,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                _showPostedMemes ? 'Your Memes' : 'Liked Memes',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (_showPostedMemes)
                StreamBuilder<List<MemePost>>(
                  stream: _memeService.getUserMemes(currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading memes: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
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
                      return const Center(
                        child: Text(
                          'No memes posted yet',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: memes.length,
                      itemBuilder: (context, index) =>
                          _buildMemeCard(memes[index]),
                    );
                  },
                )
              else
                _LikedMemesGrid(
                  memes: _likedMemes,
                  onPass: _handlePassMeme,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white70),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.deepPurple : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
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
    );
  }

  Widget _buildMemeCard(MemePost meme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(meme.memeUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
