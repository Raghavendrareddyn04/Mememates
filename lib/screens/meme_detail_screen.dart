import 'package:flutter/material.dart';
import '../models/meme_post.dart';
import '../services/user_service.dart';
import '../services/meme_service.dart';

class MemeDetailScreen extends StatefulWidget {
  final MemePost meme;

  const MemeDetailScreen({
    super.key,
    required this.meme,
  });

  @override
  State<MemeDetailScreen> createState() => _MemeDetailScreenState();
}

class _MemeDetailScreenState extends State<MemeDetailScreen> {
  final _userService = UserService();
  final _memeService = MemeService();
  Map<String, dynamic>? _posterProfile;
  Map<String, dynamic>? _streakInfo;
  List<MemePost>? _userMemes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userService.getUserProfile(widget.meme.userId);
      final streakInfo =
          await _memeService.getUserStreakInfo(widget.meme.userId);

      setState(() {
        _posterProfile = profile;
        _streakInfo = streakInfo;
        _isLoading = false;
      });

      // Load user's memes after setting initial state
      _memeService.getUserMemes(widget.meme.userId).listen((memes) {
        if (mounted) {
          setState(() => _userMemes = memes);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Colors.deepPurple.shade900,
              Colors.purple.shade900,
              Colors.pink.shade900,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  _buildAppBar(isSmallScreen),
                  SliverToBoxAdapter(
                    child: isLargeScreen
                        ? _buildLargeScreenLayout()
                        : _buildSmallScreenLayout(isSmallScreen),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildMemeCard(),
                const SizedBox(height: 24),
                _buildInteractionSection(),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildUserProfileCard(),
                const SizedBox(height: 24),
                _buildUserStats(),
                const SizedBox(height: 24),
                _buildUserMemes(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallScreenLayout(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        children: [
          _buildMemeCard(),
          const SizedBox(height: 24),
          _buildInteractionSection(),
          const SizedBox(height: 24),
          _buildUserProfileCard(),
          const SizedBox(height: 24),
          _buildUserStats(),
          const SizedBox(height: 24),
          _buildUserMemes(),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isSmallScreen) {
    return SliverAppBar(
      expandedHeight: isSmallScreen ? 0 : 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade900,
                Colors.purple.shade900,
              ],
            ),
          ),
          child: !isSmallScreen
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: widget.meme.userProfileImage != null
                            ? NetworkImage(widget.meme.userProfileImage!)
                            : null,
                        child: widget.meme.userProfileImage == null
                            ? Text(
                                widget.meme.userName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 32),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.meme.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildMemeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Hero(
              tag: 'meme_${widget.meme.id}',
              child: Image.network(
                widget.meme.memeUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.meme.caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                if (widget.meme.songTitle != null) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.pink),
                    ),
                    title: Text(
                      widget.meme.songTitle!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: widget.meme.artistName != null
                        ? Text(
                            widget.meme.artistName!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle, color: Colors.pink),
                      onPressed: () {
                        // Implement music preview
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInteractionButton(
            icon: Icons.favorite,
            label: 'Like',
            count: widget.meme.likedByUsers.length,
            color: Colors.pink,
          ),
          _buildInteractionButton(
            icon: Icons.close,
            label: 'Pass',
            count: widget.meme.passedByUsers.length,
            color: Colors.red,
          ),
          _buildInteractionButton(
            icon: Icons.share,
            label: 'Share',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    int? count,
    required Color color,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: color,
          onPressed: () {
            // Implement interaction
          },
        ),
        if (count != null)
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfileCard() {
    if (_posterProfile == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: widget.meme.userProfileImage != null
                    ? NetworkImage(widget.meme.userProfileImage!)
                    : null,
                child: widget.meme.userProfileImage == null
                    ? Text(
                        widget.meme.userName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.meme.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Age: ${_posterProfile!['age']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_posterProfile!['bio'] != null) ...[
            const SizedBox(height: 16),
            Text(
              _posterProfile!['bio'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_posterProfile!['interests'] != null) ...[
            const Text(
              'Interests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_posterProfile!['interests'] as List)
                  .map((interest) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    if (_streakInfo == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.local_fire_department,
                value: _streakInfo!['streak'].toString(),
                label: 'Day Streak',
                color: Colors.orange,
              ),
              _buildStatItem(
                icon: Icons.post_add,
                value: _userMemes?.length.toString() ?? '0',
                label: 'Posts',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.favorite,
                value: widget.meme.likedByUsers.length.toString(),
                label: 'Likes',
                color: Colors.pink,
              ),
            ],
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
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
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
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUserMemes() {
    if (_userMemes == null || _userMemes!.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More Memes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _userMemes!.length,
          itemBuilder: (context, index) {
            final meme = _userMemes![index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemeDetailScreen(meme: meme),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(meme.memeUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
