import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../models/meme_post.dart';
import '../services/user_service.dart';
import '../services/meme_service.dart';
import 'chat_screen.dart';
import '../models/user_profile.dart';
import '../widgets/audius_player.dart';

class MemeDetailScreen extends StatefulWidget {
  final MemePost meme;

  const MemeDetailScreen({
    super.key,
    required this.meme,
  });

  @override
  State<MemeDetailScreen> createState() => _MemeDetailScreenState();
}

class _MemeDetailScreenState extends State<MemeDetailScreen>
    with SingleTickerProviderStateMixin {
  final _userService = UserService();
  final _memeService = MemeService();
  Map<String, dynamic>? _posterProfile;
  Map<String, dynamic>? _streakInfo;
  List<MemePost>? _userMemes;
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isPassed = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        final profile = await _userService.getUserProfile(widget.meme.userId);
        final streakInfo =
            await _memeService.getUserStreakInfo(widget.meme.userId);

        setState(() {
          _posterProfile = {
            'name': profile?.name,
            'age': profile?.age,
            'bio': profile?.bio,
            'profileImage': profile?.profileImage,
            'moodBoardImages': profile?.moodBoard,
            'audiusTrackId': profile?.audiusTrackId,
            'trackTitle': profile?.trackTitle,
            'artistName': profile?.artistName,
            'interests': profile?.interests ?? [],
          };
          _streakInfo = streakInfo;
          _isLiked = widget.meme.isLikedBy(currentUser.uid);
          _isPassed = widget.meme.isPassedBy(currentUser.uid);
          _isLoading = false;
        });

        // Load user's memes after setting initial state
        _memeService.getUserMemes(widget.meme.userId).listen((memes) {
          if (mounted) {
            setState(() => _userMemes = memes);
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Widget _buildMusicAnthemSection() {
    final hasMusic = _posterProfile != null &&
        _posterProfile!['audiusTrackId'] != null &&
        _posterProfile!['trackTitle'] != null &&
        _posterProfile!['artistName'] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasMusic
                      ? Colors.pink.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.music_note,
                  color: hasMusic ? Colors.pink : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Music Anthem',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasMusic)
            AudiusPlayer(
              trackId: _posterProfile!['audiusTrackId'],
              title: _posterProfile!['trackTitle'],
              artistName: _posterProfile!['artistName'],
              artwork: widget.meme.trackArtwork,
            )
          else
            Center(
              child: Text(
                'No music anthem set',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLike() async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    setState(() => _isLiked = true);
    try {
      await _memeService.likeMeme(widget.meme.id, currentUser.uid);
      _showLikeAnimation();
    } catch (e) {
      setState(() => _isLiked = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking meme: $e')),
        );
      }
    }
  }

  Future<void> _handlePass() async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    setState(() => _isPassed = true);
    try {
      await _memeService.passMeme(widget.meme.id, currentUser.uid);
    } catch (e) {
      setState(() => _isPassed = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error passing meme: $e')),
        );
      }
    }
  }

  void _showLikeAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Icon(
              Icons.favorite,
              color: Colors.pink,
              size: 150 * value,
            ),
          );
        },
        onEnd: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _navigateToChat() async {
    if (_posterProfile == null) return;

    final userProfile = UserProfile(
      userId: widget.meme.userId,
      name: widget.meme.userName,
      age: _posterProfile!['age'] ?? 0,
      moodBoard: List<String>.from(_posterProfile!['moodBoardImages'] ?? []),
      artistName: _posterProfile!['artistName'] ?? '',
      hasLikedMe: true,
      canMessage: true,
      profileImage: widget.meme.userProfileImage,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(profile: userProfile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isLargeScreen = size.width > 1200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
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
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share, color: Colors.white),
              ),
              onPressed: () {
                // Implement share functionality
              },
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.more_vert, color: Colors.white),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => _buildOptionsSheet(),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : Container(
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
                child: isLargeScreen
                    ? _buildLargeScreenLayout()
                    : _buildResponsiveLayout(isSmallScreen),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading meme details...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMemeSection(true),
                  const SizedBox(height: 32),
                  _buildMusicAnthemSection(),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  _buildUserProfile(true),
                  const SizedBox(height: 32),
                  _buildUserStats(true),
                  const SizedBox(height: 32),
                  if (_userMemes != null && _userMemes!.isNotEmpty)
                    _buildMoreMemes(true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveLayout(bool isSmallScreen) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMemeSection(isSmallScreen),
            const SizedBox(height: 24),
            _buildMusicAnthemSection(),
            const SizedBox(height: 24),
            _buildUserProfile(isSmallScreen),
            const SizedBox(height: 24),
            _buildUserStats(isSmallScreen),
            const SizedBox(height: 24),
            if (_userMemes != null && _userMemes!.isNotEmpty)
              _buildMoreMemes(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildMemeSection(bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: 'meme_${widget.meme.id}',
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: isWideScreen ? 600 : 400,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.meme.memeUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.black12,
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
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.meme.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    label: 'Like',
                    count: widget.meme.likedByUsers.length,
                    color: _isLiked ? Colors.pink : Colors.white,
                    onTap: _isLiked ? null : _handleLike,
                  ),
                  _buildActionButton(
                    icon: _isPassed ? Icons.close : Icons.close_outlined,
                    label: 'Pass',
                    count: widget.meme.passedByUsers.length,
                    color: _isPassed ? Colors.red : Colors.white,
                    onTap: _isPassed ? null : _handlePass,
                  ),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    color: Colors.blue,
                    onTap: _navigateToChat,
                  ),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: Colors.green,
                    onTap: () {
                      // Implement share functionality
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    int? count,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            if (count != null) ...[
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile(bool isWideScreen) {
    if (_posterProfile == null) return const SizedBox();

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
            children: [
              CircleAvatar(
                radius: isWideScreen ? 40 : 30,
                backgroundImage: widget.meme.userProfileImage != null
                    ? NetworkImage(widget.meme.userProfileImage!)
                    : null,
                child: widget.meme.userProfileImage == null
                    ? Text(
                        widget.meme.userName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: isWideScreen ? 32 : 24,
                          color: Colors.white,
                        ),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWideScreen ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_posterProfile!['bio'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _posterProfile!['bio'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: isWideScreen ? 16 : 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_posterProfile!['interests'] != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<String>.from(_posterProfile!['interests'])
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWideScreen ? 14 : 12,
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

  Widget _buildUserStats(bool isWideScreen) {
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
          Text(
            'Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWideScreen ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
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
              if (_streakInfo != null)
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  value: _streakInfo!['streak'].toString(),
                  label: 'Streak',
                  color: Colors.orange,
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
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMoreMemes(bool isWideScreen) {
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
            'More Memes',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWideScreen ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWideScreen ? 2 : 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _userMemes!.length.clamp(0, 6),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.report_outlined, color: Colors.orange),
            title: const Text(
              'Report Meme',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              // Implement report functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined, color: Colors.red),
            title: const Text(
              'Block User',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              // Implement block functionality
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
