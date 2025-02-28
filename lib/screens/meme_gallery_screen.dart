import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_auth/models/meme_post.dart';
import 'package:flutter_auth/screens/meme_detail_screen.dart';
import 'package:flutter_auth/services/meme_gallery_service.dart';
import 'package:flutter_auth/services/user_service.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
import 'package:flutter_auth/widgets/meme_media.dart';

class MemeGalleryScreen extends StatefulWidget {
  final String userId;
  final String initialMemeId;

  const MemeGalleryScreen({
    Key? key,
    required this.userId,
    required this.initialMemeId,
  }) : super(key: key);

  @override
  State<MemeGalleryScreen> createState() => _MemeGalleryScreenState();
}

class _MemeGalleryScreenState extends State<MemeGalleryScreen> {
  final MemeGalleryService _memeGalleryService = MemeGalleryService();
  final UserService _userService = UserService();
  late PageController _pageController;
  List<MemePost> _memes = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _userName;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserInfo();
    _loadMemes();
  }

  Future<void> _loadUserInfo() async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        _isCurrentUser = currentUser.uid == widget.userId;
      }

      final userProfile = await _userService.getUserProfile(widget.userId);
      if (userProfile != null && mounted) {
        setState(() {
          _userName = userProfile.name;
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadMemes() async {
    setState(() => _isLoading = true);

    try {
      // Subscribe to the stream of memes
      _memeGalleryService.getUserMemeGallery(widget.userId).listen((memes) {
        if (mounted) {
          setState(() {
            _memes = memes;
            _isLoading = false;

            // Find the index of the initial meme
            if (widget.initialMemeId.isNotEmpty) {
              final initialIndex =
                  _memes.indexWhere((meme) => meme.id == widget.initialMemeId);
              if (initialIndex != -1) {
                _currentIndex = initialIndex;
                // Jump to the initial meme without animation
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(_currentIndex);
                  }
                });
              }
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading memes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
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
        title: Text(
          _isCurrentUser
              ? 'My Meme Gallery'
              : '${_userName ?? "User"}\'s Memes',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.grid_view, color: Colors.white),
            ),
            onPressed: () {
              _showGridView();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: LoadingAnimation(
                message: "Loading memes...",
              ),
            )
          : _memes.isEmpty
              ? _buildEmptyState()
              : _buildPageView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _isCurrentUser
                ? 'You haven\'t posted any memes yet'
                : 'This user hasn\'t posted any memes yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _memes.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final meme = _memes[index];
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
                color: Colors.black,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: MemeMedia(
                          url: meme.memeUrl,
                          isVideo: meme.isVideo,
                        ),
                      ),
                    ),
                    _buildMemeInfo(meme),
                  ],
                ),
              ),
            );
          },
        ),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildMemeInfo(MemePost meme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meme.caption,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                meme.timestamp,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.favorite,
                color: Colors.pink,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${meme.likedByUsers.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _memes.length,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentIndex == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  void _showGridView() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'All Memes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _memes.length,
                    itemBuilder: (context, index) {
                      final meme = _memes[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: meme.isVideo
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          meme.memeUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.error,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Image.network(
                                      meme.memeUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[800],
                                          child: const Icon(
                                            Icons.error,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      color: Colors.pink,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${meme.likedByUsers.length}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
