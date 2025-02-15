import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
import '../services/auth_service.dart';
import 'mood_board_editor_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<MoodBoardPost> _moodBoards = [];
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  String _selectedFilter = 'All';
  bool _showFilters = false;

  final List<String> _filters = [
    'All',
    'Popular',
    'Recent',
    'Following',
    'Music',
    'Art',
    'Gaming',
    'Travel'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMoodBoards();
    _scrollController.addListener(_onScroll);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationController.forward();
  }

  void _onScroll() {
    setState(() {
      _showFilters = _scrollController.offset <= 10;
    });
  }

  Future<void> _loadMoodBoards() async {
    setState(() => _isLoading = true);
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final currentUser = _authService.currentUser;

      final boards = <MoodBoardPost>[];
      for (var doc in usersSnapshot.docs) {
        if (doc.id == currentUser?.uid) continue;

        final data = doc.data();
        final moodBoardImages =
            List<String>.from(data['moodBoardImages'] ?? []);
        if (moodBoardImages.isNotEmpty) {
          final likesDoc =
              await _firestore.collection('moodboard_likes').doc(doc.id).get();
          final commentsSnapshot = await _firestore
              .collection('moodboard_comments')
              .doc(doc.id)
              .collection('comments')
              .get();

          boards.add(MoodBoardPost(
            userId: doc.id,
            userName: data['name'] ?? 'Anonymous',
            userProfileImage: data['profileImage'],
            images: moodBoardImages,
            likes: List<String>.from(likesDoc.data()?['likedBy'] ?? []),
            comments: commentsSnapshot.docs
                .map((comment) => Comment(
                      id: comment.id,
                      userId: comment.data()['userId'],
                      userName: comment.data()['userName'],
                      content: comment.data()['content'],
                      timestamp:
                          (comment.data()['timestamp'] as Timestamp).toDate(),
                    ))
                .toList(),
          ));
        }
      }

      setState(() {
        _moodBoards = boards;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading mood boards: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToMoodBoardEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoodBoardEditorScreen(
          initialImages: const [],
          onSave: (images) async {
            try {
              final currentUser = _authService.currentUser;
              if (currentUser != null) {
                await _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .update({
                  'moodBoardImages': images,
                });
                await _loadMoodBoards(); // Reload mood boards after saving
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving mood board: $e')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleLike(MoodBoardPost post) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      final likeRef = _firestore.collection('moodboard_likes').doc(post.userId);
      await _firestore.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);
        if (!likeDoc.exists) {
          transaction.set(likeRef, {
            'likedBy': [currentUser.uid]
          });
        } else {
          List<String> likedBy =
              List<String>.from(likeDoc.data()?['likedBy'] ?? []);
          if (!likedBy.contains(currentUser.uid)) {
            likedBy.add(currentUser.uid);
            transaction.update(likeRef, {'likedBy': likedBy});
          }
        }
      });

      // Refresh the mood boards to show updated likes
      await _loadMoodBoards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking mood board: $e')),
        );
      }
    }
  }

  Future<void> _handleComment(MoodBoardPost post, String comment) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('moodboard_comments')
          .doc(post.userId)
          .collection('comments')
          .add({
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous',
        'content': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Refresh the mood boards to show updated comments
      await _loadMoodBoards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1200;
    final isLargeScreen = size.width >= 1200;

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
            ? const Center(
                child: LoadingAnimation(
                  message: "Discovering amazing mood boards...",
                ),
              )
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildAppBar(isSmallScreen),
                  if (_showFilters) _buildFiltersBar(isSmallScreen),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 24,
                      vertical: isSmallScreen ? 16 : 24,
                    ),
                    sliver: _moodBoards.isEmpty
                        ? SliverFillRemaining(
                            child: _buildEmptyState(isSmallScreen))
                        : isLargeScreen
                            ? _buildLargeScreenGrid()
                            : isMediumScreen
                                ? _buildMediumScreenGrid()
                                : _buildSmallScreenGrid(),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToMoodBoardEditor,
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Create'),
      ),
    );
  }

  Widget _buildAppBar(bool isSmallScreen) {
    return SliverAppBar(
      expandedHeight: isSmallScreen ? 120 : 160,
      floating: true,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade900.withOpacity(0.9),
                Colors.purple.shade900.withOpacity(0.9),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.pink.withOpacity(0.2),
                          Colors.purple.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: isSmallScreen ? 16 : 24,
                left: isSmallScreen ? 16 : 24,
                right: isSmallScreen ? 16 : 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 28 : 36,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore amazing mood boards from the community',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isSmallScreen ? 14 : 16,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersBar(bool isSmallScreen) {
    return SliverToBoxAdapter(
      child: Container(
        height: isSmallScreen ? 48 : 56,
        margin: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 8 : 16,
          horizontal: isSmallScreen ? 16 : 24,
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                },
                backgroundColor: Colors.white.withOpacity(0.1),
                selectedColor: Colors.pink,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 8 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.pink : Colors.white24,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLargeScreenGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildMoodBoardCard(_moodBoards[index], true),
        childCount: _moodBoards.length,
      ),
    );
  }

  Widget _buildMediumScreenGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildMoodBoardCard(_moodBoards[index], true),
        childCount: _moodBoards.length,
      ),
    );
  }

  Widget _buildSmallScreenGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildMoodBoardCard(_moodBoards[index], false),
        childCount: _moodBoards.length,
      ),
    );
  }

  Widget _buildMoodBoardCard(MoodBoardPost post, bool isWideScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserHeader(post),
                Expanded(child: _buildMoodBoardImages(post)),
                _buildCardFooter(post, isWideScreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(MoodBoardPost post) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: post.userProfileImage != null
                ? NetworkImage(post.userProfileImage!)
                : null,
            child: post.userProfileImage == null
                ? Text(
                    post.userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${post.images.length} images',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showOptionsMenu(post),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBoardImages(MoodBoardPost post) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: post.images.length.clamp(0, 4),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(post.images[index]),
              fit: BoxFit.cover,
            ),
          ),
          child: index == 3 && post.images.length > 4
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Text(
                      '+${post.images.length - 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildCardFooter(MoodBoardPost post, bool isWideScreen) {
    final currentUser = _authService.currentUser;
    final hasLiked =
        currentUser != null && post.likes.contains(currentUser.uid);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: hasLiked ? Icons.favorite : Icons.favorite_border,
            label: post.likes.length.toString(),
            color: hasLiked ? Colors.pink : Colors.white,
            onTap: () => _handleLike(post),
          ),
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: post.comments.length.toString(),
            color: Colors.blue,
            onTap: () => _showComments(post),
          ),
          if (isWideScreen)
            _buildActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              color: Colors.green,
              onTap: () => _handleShare(post),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mood_bad_outlined,
            size: isSmallScreen ? 64 : 96,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No mood boards found',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your mood board!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToMoodBoardEditor,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Create Mood Board'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 32,
                vertical: isSmallScreen ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(MoodBoardPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                'Report',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Handle report
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
                // Handle block
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showComments(MoodBoardPost post) {
    final commentController = TextEditingController();

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
        child: Column(
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: post.comments.length,
                itemBuilder: (context, index) {
                  final comment = post.comments[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              comment.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(comment.timestamp),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comment.content,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pink),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        _handleComment(post, commentController.text);
                        commentController.clear();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleShare(MoodBoardPost post) {
    // Implement share functionality
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

class MoodBoardPost {
  final String userId;
  final String userName;
  final String? userProfileImage;
  final List<String> images;
  final List<String> likes;
  final List<Comment> comments;

  MoodBoardPost({
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.images,
    required this.likes,
    required this.comments,
  });
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.timestamp,
  });
}
