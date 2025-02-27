import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_auth/models/story.dart';
import 'package:flutter_auth/services/story_service.dart';
import 'package:flutter_auth/services/auth_service.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'dart:ui';

class StoryCreateScreen extends StatefulWidget {
  const StoryCreateScreen({super.key});

  @override
  State<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends State<StoryCreateScreen>
    with SingleTickerProviderStateMixin {
  final _storyService = StoryService();
  final _authService = AuthService();
  final _textController = TextEditingController();

  StoryType _selectedType = StoryType.image;
  XFile? _selectedMediaFile;
  Uint8List? _webImage;
  bool _isLoading = false;
  Color _textColor = Colors.white;
  Color _backgroundColor = Colors.black;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedMediaFile = pickedFile;
          _selectedType = StoryType.image;
        });

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (pickedFile != null) {
        setState(() {
          _selectedMediaFile = pickedFile;
          _selectedType = StoryType.video;
        });

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error picking video: $e');
    }
  }

  Future<void> _createStory() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('You must be logged in to create a story');
      return;
    }

    if (_selectedType == StoryType.text && _textController.text.isEmpty) {
      _showErrorSnackBar('Please enter some text for your story');
      return;
    }

    if ((_selectedType == StoryType.image ||
            _selectedType == StoryType.video) &&
        _selectedMediaFile == null) {
      _showErrorSnackBar('Please select media for your story');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String content;
      Map<String, dynamic>? metadata;

      if (_selectedType == StoryType.text) {
        content = _textController.text;
        metadata = {
          'textColor': _textColor.value.toString(),
          'backgroundColor': _backgroundColor.value.toString(),
        };
      } else {
        content = _selectedMediaFile!.path;
      }

      await _storyService.createStory(
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'Anonymous',
        content: content,
        type: _selectedType,
        userProfileImage: currentUser.photoURL,
        metadata: metadata,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to create story: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_selectedMediaFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedType == StoryType.image ? Icons.image : Icons.videocam,
              color: Colors.white.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedType == StoryType.image
                  ? 'Tap the Image button below to select an image'
                  : 'Tap the Video button below to select a video',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedType == StoryType.image) {
      return _buildImageWidget();
    } else if (_selectedType == StoryType.video) {
      return _buildVideoPreview();
    }

    return const SizedBox.shrink();
  }

  Widget _buildVideoPreview() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/video_placeholder.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            size: 64,
            color: Colors.white,
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Video selected: ${_selectedMediaFile!.path.split('/').last}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: kIsWeb
            ? (_webImage != null
                ? Image.memory(
                    _webImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Text(
                        'Image preview not available',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ))
            : Image.file(
                File(_selectedMediaFile!.path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
      ),
    );
  }

  Widget _buildTextStoryEditor() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: TextField(
                controller: _textController,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type your story...',
                  hintStyle: TextStyle(
                    color: _textColor.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorPicker(
                label: 'Text Color',
                color: _textColor,
                onColorChanged: (color) {
                  setState(() => _textColor = color);
                },
              ),
              _buildColorPicker(
                label: 'Background',
                color: _backgroundColor,
                onColorChanged: (color) {
                  setState(() => _backgroundColor = color);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker({
    required String label,
    required Color color,
    required Function(Color) onColorChanged,
  }) {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
    ];

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final isSelected = colors[index] == color;
              return GestureDetector(
                onTap: () => onColorChanged(colors[index]),
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _selectedType == StoryType.text
                ? _buildTextStoryEditor()
                : _buildMediaPreview(),
          ),
        ),
        _buildTypeSelector(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _selectedType == StoryType.text
                ? _buildTextStoryEditor()
                : _buildMediaPreview(),
          ),
        ),
        _buildTypeSelector(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: _selectedType == StoryType.text
                ? _buildTextStoryEditor()
                : _buildMediaPreview(),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.only(right: 32, top: 32, bottom: 32),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Story Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTypeButton(
                  icon: Icons.image,
                  label: 'Image Story',
                  type: StoryType.image,
                  onTap: _pickImage,
                ),
                const SizedBox(height: 16),
                _buildTypeButton(
                  icon: Icons.videocam,
                  label: 'Video Story',
                  type: StoryType.video,
                  onTap: _pickVideo,
                ),
                const SizedBox(height: 16),
                _buildTypeButton(
                  icon: Icons.text_fields,
                  label: 'Text Story',
                  type: StoryType.text,
                  onTap: () {
                    setState(() {
                      _selectedType = StoryType.text;
                    });
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createStory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Share Story',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * _slideAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTypeButton(
                      icon: Icons.image,
                      label: 'Image',
                      type: StoryType.image,
                      onTap: _pickImage,
                    ),
                    _buildTypeButton(
                      icon: Icons.videocam,
                      label: 'Video',
                      type: StoryType.video,
                      onTap: _pickVideo,
                    ),
                    _buildTypeButton(
                      icon: Icons.text_fields,
                      label: 'Text',
                      type: StoryType.text,
                      onTap: () {
                        setState(() {
                          _selectedType = StoryType.text;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createStory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Share Story',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeButton({
    required IconData icon,
    required String label,
    required StoryType type,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Colors.pink,
                    Colors.pinkAccent,
                  ],
                )
              : null,
          color: isSelected ? null : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Create Story',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black,
                Colors.grey.shade900.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey.shade900,
              Colors.black,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: LoadingAnimation(
                  message: "Creating your story...",
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 1200) {
                    return _buildDesktopLayout();
                  } else if (constraints.maxWidth >= 600) {
                    return _buildTabletLayout();
                  } else {
                    return _buildMobileLayout();
                  }
                },
              ),
      ),
    );
  }
}
