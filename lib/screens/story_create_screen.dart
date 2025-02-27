import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_auth/models/story.dart';
import 'package:flutter_auth/services/story_service.dart';
import 'package:flutter_auth/services/auth_service.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

class StoryCreateScreen extends StatefulWidget {
  const StoryCreateScreen({super.key});

  @override
  State<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends State<StoryCreateScreen> {
  final _storyService = StoryService();
  final _authService = AuthService();
  final _textController = TextEditingController();

  StoryType _selectedType = StoryType.image;
  XFile? _selectedMediaFile;
  Uint8List? _webImage;
  bool _isLoading = false;
  Color _textColor = Colors.white;
  Color _backgroundColor = Colors.black;

  @override
  void dispose() {
    _textController.dispose();
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
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildMediaPreview() {
    if (_selectedMediaFile == null) {
      return const Center(
        child: Text(
          'No media selected',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    if (_selectedType == StoryType.image) {
      return _buildImageWidget();
    } else if (_selectedType == StoryType.video) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/video_placeholder.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          const Icon(
            Icons.play_circle_outline,
            size: 64,
            color: Colors.white,
          ),
          Positioned(
            bottom: 16,
            child: Text(
              'Video selected: ${_selectedMediaFile!.path.split('/').last}',
              style: const TextStyle(
                color: Colors.white,
                backgroundColor: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildImageWidget() {
    if (kIsWeb) {
      if (_webImage != null) {
        return Image.memory(
          _webImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Text(
            'Image preview not available',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    } else {
      return Image.file(
        File(_selectedMediaFile!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }

  Widget _buildTextStoryEditor() {
    return Container(
      color: _backgroundColor,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorPicker(
                label: 'Text',
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
          style: const TextStyle(color: Colors.white),
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
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Story'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createStory,
            child: const Text(
              'Share',
              style: TextStyle(
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: LoadingAnimation(
                message: "Creating your story...",
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _selectedType == StoryType.text
                      ? _buildTextStoryEditor()
                      : _buildMediaPreview(),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
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
                    ],
                  ),
                ),
              ],
            ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
