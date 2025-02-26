import 'package:flutter/material.dart';
import 'package:flutter_auth/models/story.dart';
import 'package:flutter_auth/services/story_service.dart';
import 'package:flutter_auth/services/auth_service.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;
  final String userId;

  const StoryViewScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.userId,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  final AuthService _authService = AuthService();

  late PageController _pageController;
  late AnimationController _animationController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
        _nextStory();
      }
    });

    _loadStory(widget.stories[_currentIndex]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory(Story story) {
    _animationController.reset();

    // Mark story as viewed
    final currentUser = _authService.currentUser;
    if (currentUser != null && !story.viewedBy.contains(currentUser.uid)) {
      _storyService.markStoryAsViewed(story.id, currentUser.uid);
    }

    if (story.type == StoryType.video) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(story.content)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController!.play();
            _videoController!.addListener(() {
              if (_videoController!.value.position >=
                  _videoController!.value.duration) {
                _nextStory();
              }
            });
          }
        });
    } else {
      _animationController.forward();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > 2 * screenWidth / 3) {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.stories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _loadStory(widget.stories[index]);
              },
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return _StoryItem(
                  story: story,
                  animationController: _animationController,
                  videoController:
                      story.type == StoryType.video && index == _currentIndex
                          ? _videoController
                          : null,
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
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
                child: Row(
                  children: [
                    _StoryProgressIndicator(
                      animationController: _animationController,
                      position: _currentIndex,
                      length: widget.stories.length,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: widget
                                  .stories[_currentIndex].userProfileImage !=
                              null
                          ? NetworkImage(
                              widget.stories[_currentIndex].userProfileImage!)
                          : null,
                      child:
                          widget.stories[_currentIndex].userProfileImage == null
                              ? Text(
                                  widget.stories[_currentIndex].userName[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.stories[_currentIndex].userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getTimeAgo(widget.stories[_currentIndex].createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (widget.stories[_currentIndex].userId ==
                        _authService.currentUser?.uid)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () {
                          _storyService.deleteStory(
                            widget.stories[_currentIndex].id,
                            widget.stories[_currentIndex].userId,
                          );
                          Navigator.pop(context);
                        },
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

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _StoryItem extends StatelessWidget {
  final Story story;
  final AnimationController animationController;
  final VideoPlayerController? videoController;

  const _StoryItem({
    required this.story,
    required this.animationController,
    this.videoController,
  });

  @override
  Widget build(BuildContext context) {
    if (story.type == StoryType.image) {
      return CachedNetworkImage(
        imageUrl: story.content,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.error, color: Colors.white),
          ),
        ),
      );
    } else if (story.type == StoryType.video) {
      if (videoController != null && videoController!.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: videoController!.value.size.width,
            height: videoController!.value.size.height,
            child: VideoPlayer(videoController!),
          ),
        );
      } else {
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }
    } else if (story.type == StoryType.text) {
      // Parse colors from metadata
      Color textColor = Colors.white;
      Color backgroundColor = Colors.black;

      if (story.metadata != null) {
        if (story.metadata!.containsKey('textColor')) {
          final colorValue = int.tryParse(
            story.metadata!['textColor']
                .toString()
                .replaceAll('Color(', '')
                .replaceAll(')', ''),
          );
          if (colorValue != null) {
            textColor = Color(colorValue);
          }
        }

        if (story.metadata!.containsKey('backgroundColor')) {
          final colorValue = int.tryParse(
            story.metadata!['backgroundColor']
                .toString()
                .replaceAll('Color(', '')
                .replaceAll(')', ''),
          );
          if (colorValue != null) {
            backgroundColor = Color(colorValue);
          }
        }
      }

      return Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            story.content,
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(color: Colors.black);
  }
}

class _StoryProgressIndicator extends StatelessWidget {
  final AnimationController animationController;
  final int position;
  final int length;

  const _StoryProgressIndicator({
    required this.animationController,
    required this.position,
    required this.length,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: List.generate(
          length,
          (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: LinearProgressIndicator(
                  value: index < position
                      ? 1.0
                      : index == position
                          ? animationController.value
                          : 0.0,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
