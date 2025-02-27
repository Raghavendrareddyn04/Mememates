import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../widgets/loading_animation.dart';
import 'dart:ui';

class MoodBoardUploadScreen extends StatefulWidget {
  final List<String> initialImages;
  final Function(List<String>) onSave;

  const MoodBoardUploadScreen({
    super.key,
    required this.initialImages,
    required this.onSave,
  });

  @override
  State<MoodBoardUploadScreen> createState() => _MoodBoardUploadScreenState();
}

class _MoodBoardUploadScreenState extends State<MoodBoardUploadScreen>
    with SingleTickerProviderStateMixin {
  final _cloudinaryService = CloudinaryService();
  final _imagePicker = ImagePicker();
  final List<String> _selectedImages = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedImages.addAll(widget.initialImages);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 4 images allowed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Pick multiple images
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() => _isLoading = true);

        // Calculate how many images we can add
        final int remainingSlots = 4 - _selectedImages.length;
        final List<XFile> imagesToUpload = images.length <= remainingSlots
            ? images
            : images.sublist(0, remainingSlots);

        // Show a message if we're limiting the number of images
        if (images.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Only adding ${imagesToUpload.length} images to stay within the limit of 4'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Upload each image
        for (final image in imagesToUpload) {
          final url = await _cloudinaryService.uploadImage(image.path);
          setState(() {
            _selectedImages.add(url);
          });
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveMoodBoard() async {
    if (_selectedImages.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 4 images'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onSave(_selectedImages);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isLargeScreen = size.width >= 1200;

    return Scaffold(
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
        title: const Text('Create Mood Board'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveMoodBoard,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
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
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: LoadingAnimation(
                    message: "Creating your mood board...",
                  ),
                )
              : isLargeScreen
                  ? _buildLargeScreenLayout()
                  : _buildResponsiveLayout(isSmallScreen),
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildImageGrid(true),
        ),
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border(
              left: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          child: _buildInstructions(true),
        ),
      ],
    );
  }

  Widget _buildResponsiveLayout(bool isSmallScreen) {
    return Column(
      children: [
        _buildInstructions(isSmallScreen),
        Expanded(
          child: _buildImageGrid(isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildInstructions(bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            isWideScreen ? Colors.transparent : Colors.white.withOpacity(0.1),
        borderRadius: isWideScreen ? null : BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Your Mood Board',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWideScreen ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add 4 images that represent your vibe and personality',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isWideScreen ? 16 : 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressIndicator(),
          const SizedBox(height: 24),
          _buildUploadButton(isWideScreen),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_selectedImages.length}/4',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _selectedImages.length / 4,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton(bool isWideScreen) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(
          'Add Images',
          style: TextStyle(
            fontSize: isWideScreen ? 16 : 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: isWideScreen ? 16 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid(bool isWideScreen) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GridView.builder(
          padding: EdgeInsets.all(isWideScreen ? 24 : 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWideScreen ? 2 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            if (index < _selectedImages.length) {
              return _buildImageTile(
                  _selectedImages[index], index, isWideScreen);
            } else {
              return _buildEmptyTile(isWideScreen);
            }
          },
        ),
      ),
    );
  }

  Widget _buildImageTile(String imageUrl, int index, bool isWideScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.white.withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.pink),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => _removeImage(index),
                  iconSize: isWideScreen ? 24 : 20,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Image ${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWideScreen ? 14 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTile(bool isWideScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: isWideScreen ? 48 : 32,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Image',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isWideScreen ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
