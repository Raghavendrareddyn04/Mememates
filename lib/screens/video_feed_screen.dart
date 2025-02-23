import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/meme_post.dart';
import '../services/meme_service.dart';
import '../services/auth_service.dart';
import '../widgets/loading_animation.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final _memeService = MemeService();
  final _authService = AuthService();
  final PageController _pageController = PageController();
  final Map<String, ChewieController> _chewieControllers = {};
  final Map<String, bool> _isVideoInitialized = {};
  List<MemePost> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _memeService.getMemesFeed(currentUser.uid).listen((memes) {
          if (mounted) {
            setState(() {
              _videos = memes
                  .where((meme) => meme.memeUrl.contains('/video/'))
                  .toList();
              _isLoading = false;
            });
            if (_videos.isNotEmpty) {
              _initializeVideo(_videos[0]);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading videos: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeVideo(MemePost video) async {
    if (_isVideoInitialized[video.id] == true) return;

    try {
      final videoPlayerController =
          VideoPlayerController.network(video.memeUrl);
      await videoPlayerController.initialize();

      final chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        looping: true,
        showControls: false,
        aspectRatio: videoPlayerController.value.aspectRatio,
      );

      setState(() {
        _chewieControllers[video.id] = chewieController;
        _isVideoInitialized[video.id] = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _onPageChanged(int index) {
    if (index < _videos.length) {
      _initializeVideo(_videos[index]);

      if (index > 0 && _chewieControllers[_videos[index - 1].id] != null) {
        _chewieControllers[_videos[index - 1].id]!.pause();
      }
      if (index < _videos.length - 1 &&
          _chewieControllers[_videos[index + 1].id] != null) {
        _chewieControllers[_videos[index + 1].id]!.pause();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _chewieControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleLike(MemePost video) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      setState(() {
        if (video.likedByUsers.contains(currentUser.uid)) {
          video.likedByUsers.remove(currentUser.uid);
        } else {
          video.likedByUsers.add(currentUser.uid);
        }
      });

      await _memeService.likeMeme(video.id, currentUser.uid);
    } catch (e) {
      setState(() {
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          if (video.likedByUsers.contains(currentUser.uid)) {
            video.likedByUsers.remove(currentUser.uid);
          } else {
            video.likedByUsers.add(currentUser.uid);
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error liking video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: LoadingAnimation(
          message: "Loading meme videos...",
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No videos yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share a video meme!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: _onPageChanged,
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _buildVideoItem(video, index);
      },
    );
  }

  Widget _buildVideoItem(MemePost video, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        VisibilityDetector(
          key: Key(video.id),
          onVisibilityChanged: (info) {
            if (info.visibleFraction > 0.5) {
              if (_chewieControllers[video.id] != null) {
                _chewieControllers[video.id]!.play();
              }
            } else {
              if (_chewieControllers[video.id] != null) {
                _chewieControllers[video.id]!.pause();
              }
            }
          },
          child: _chewieControllers[video.id] != null
              ? Chewie(controller: _chewieControllers[video.id]!)
              : const Center(child: CircularProgressIndicator()),
        ),
        _buildOverlay(video),
      ],
    );
  }

  Widget _buildOverlay(MemePost video) {
    final currentUser = _authService.currentUser;
    final isLiked = video.likedByUsers.contains(currentUser?.uid);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 50.0, right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.favorite,
                        label: video.likedByUsers.length.toString(),
                        onTap: () => _handleLike(video),
                        color: isLiked ? Colors.red : Colors.white,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        icon: Icons.close,
                        label: video.passedByUsers.length.toString(),
                        onTap: () => _memeService.passMeme(
                          video.id,
                          _authService.currentUser!.uid,
                        ),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: video.userProfileImage != null
                                  ? NetworkImage(video.userProfileImage!)
                                  : null,
                              child: video.userProfileImage == null
                                  ? Text(video.userName[0].toUpperCase())
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              video.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          video.caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
