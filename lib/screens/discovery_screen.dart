import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
import '../services/auth_service.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<MoodBoardPost> _moodBoards = [];

  @override
  void initState() {
    super.initState();
    _loadMoodBoards();
  }

  Future<void> _loadMoodBoards() async {
    setState(() => _isLoading = true);
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final currentUser = _authService.currentUser;

      final boards = <MoodBoardPost>[];
      for (var doc in usersSnapshot.docs) {
        if (doc.id == currentUser?.uid) continue; // Skip current user

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

  Future<void> _likeMoodBoard(String userId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final likeRef = _firestore.collection('moodboard_likes').doc(userId);
      final doc = await likeRef.get();

      if (doc.exists) {
        final likes = List<String>.from(doc.data()?['likedBy'] ?? []);
        if (likes.contains(currentUser.uid)) {
          await likeRef.update({
            'likedBy': FieldValue.arrayRemove([currentUser.uid])
          });
        } else {
          await likeRef.update({
            'likedBy': FieldValue.arrayUnion([currentUser.uid])
          });
        }
      } else {
        await likeRef.set({
          'likedBy': [currentUser.uid]
        });
      }

      await _loadMoodBoards();
    } catch (e) {
      print('Error liking mood board: $e');
    }
  }

  Future<void> _addComment(String userId, String comment) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('moodboard_comments')
          .doc(userId)
          .collection('comments')
          .add({
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous',
        'content': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _loadMoodBoards();
    } catch (e) {
      print('Error adding comment: $e');
    }
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
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pink),
                    onPressed: () {
                      if (commentController.text.trim().isNotEmpty) {
                        _addComment(post.userId, commentController.text.trim());
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: const LoadingAnimation(
              message: "Finding your perfect meme match..."));
    }

    return RefreshIndicator(
      onRefresh: _loadMoodBoards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _moodBoards.length,
        itemBuilder: (context, index) {
          final post = _moodBoards[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: post.userProfileImage != null
                        ? NetworkImage(post.userProfileImage!)
                        : null,
                    child: post.userProfileImage == null
                        ? Text(post.userName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(
                    post.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: post.images.length,
                    itemBuilder: (context, imageIndex) {
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(post.images[imageIndex]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: post.likes.contains(_authService.currentUser?.uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.pink,
                        label: post.likes.length.toString(),
                        onPressed: () => _likeMoodBoard(post.userId),
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        icon: Icons.comment,
                        color: Colors.blue,
                        label: post.comments.length.toString(),
                        onPressed: () => _showComments(post),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        children: [
          Icon(icon, color: color),
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
