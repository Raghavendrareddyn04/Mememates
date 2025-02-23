import 'package:flutter/material.dart';
import 'package:flutter_auth/models/meme_post.dart';
import 'package:flutter_auth/services/meme_service.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
import 'package:flutter_auth/screens/meme_detail_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _memeService = MemeService();
  bool _isLoading = true;
  List<MemePost> _topMemes = [];

  @override
  void initState() {
    super.initState();
    _loadTopMemes();
  }

  Future<void> _loadTopMemes() async {
    try {
      final memes = await _memeService.getTopMemes();
      setState(() {
        _topMemes = memes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboard: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMobileLayout(BuildContext context, List<MemePost> memes) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: memes.length,
      itemBuilder: (context, index) =>
          _buildMemeCard(context, memes[index], index),
    );
  }

  Widget _buildTabletLayout(BuildContext context, List<MemePost> memes) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: memes.length,
      itemBuilder: (context, index) =>
          _buildMemeCard(context, memes[index], index),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, List<MemePost> memes) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: memes.length,
      itemBuilder: (context, index) =>
          _buildMemeCard(context, memes[index], index),
    );
  }

  Widget _buildMemeCard(BuildContext context, MemePost meme, int index) {
    final isTopThree = index < 3;
    final medalColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];
    final medalIcons = ['👑', '🥈', '🥉'];
    final rankColors = [
      [Colors.amber.shade300, Colors.orange.shade900],
      [Colors.grey.shade300, Colors.grey.shade700],
      [Colors.orange.shade300, Colors.brown.shade700],
    ];

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemeDetailScreen(meme: meme),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: isTopThree
              ? Border.all(
                  color: medalColors[index],
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        // Add constraints to the container
        constraints: const BoxConstraints(
          minHeight: 300, // Minimum height for the card
          maxHeight: 400, // Maximum height for the card
        ),
        child: Stack(
          children: [
            // Meme Image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  meme.memeUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Overlay gradient for text visibility
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),

            // User info and caption
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        backgroundImage: meme.userProfileImage != null
                            ? NetworkImage(meme.userProfileImage!)
                            : null,
                        child: meme.userProfileImage == null
                            ? Text(
                                meme.userName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meme.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              meme.timestamp,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.pink,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              meme.likedByUsers.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (meme.caption.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      meme.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Rank badge for top 3
            if (isTopThree)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: rankColors[index],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        medalIcons[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade900,
              Colors.deepPurple.shade900,
              Colors.indigo.shade900,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: LoadingAnimation(
                    message: "Loading top memes...",
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverAppBar(
                      expandedHeight: 60,
                      floating: true,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '🔥 Top Memes 🔥',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
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
                  ],
                  body: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 1200) {
                        return _buildDesktopLayout(context, _topMemes);
                      } else if (constraints.maxWidth >= 600) {
                        return _buildTabletLayout(context, _topMemes);
                      } else {
                        return _buildMobileLayout(context, _topMemes);
                      }
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
