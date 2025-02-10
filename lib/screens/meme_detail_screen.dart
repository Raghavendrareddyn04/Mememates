import 'package:flutter/material.dart';
import '../models/meme_post.dart';
import '../services/user_service.dart';

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
  Map<String, dynamic>? _posterProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosterProfile();
  }

  Future<void> _loadPosterProfile() async {
    try {
      final profile = await _userService.getUserProfile(widget.meme.userId);
      setState(() {
        _posterProfile = profile;
        _isLoading = false;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meme Details'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meme Image
                    Hero(
                      tag: 'meme_${widget.meme.id}',
                      child: Image.network(
                        widget.meme.memeUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster Info
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage:
                                    widget.meme.userProfileImage != null
                                        ? NetworkImage(
                                            widget.meme.userProfileImage!)
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_posterProfile != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Age: ${_posterProfile!['age']}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Caption
                          Text(
                            widget.meme.caption,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Mood Board
                          if (_posterProfile != null &&
                              _posterProfile!['moodBoardImages'] != null) ...[
                            const Text(
                              'Mood Board',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    (_posterProfile!['moodBoardImages'] as List)
                                        .length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          _posterProfile!['moodBoardImages']
                                              [index],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          // Anthem
                          if (_posterProfile != null &&
                              _posterProfile!['anthem'] != null) ...[
                            const Text(
                              'Anthem',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              tileColor: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              leading: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                              ),
                              title: Text(
                                _posterProfile!['anthem'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: _posterProfile!['artistName'] != null
                                  ? Text(
                                      _posterProfile!['artistName'],
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    )
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
