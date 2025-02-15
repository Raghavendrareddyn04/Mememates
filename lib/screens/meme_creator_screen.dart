import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/meme_service.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import '../widgets/loading_animation.dart';
import 'dart:ui';

class MemeCreatorScreen extends StatefulWidget {
  const MemeCreatorScreen({super.key});

  @override
  State<MemeCreatorScreen> createState() => _MemeCreatorScreenState();
}

class _MemeCreatorScreenState extends State<MemeCreatorScreen>
    with SingleTickerProviderStateMixin {
  final _memeService = MemeService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  final _captionController = TextEditingController();
  final _topTextController = TextEditingController();
  final _bottomTextController = TextEditingController();
  XFile? _selectedImageFile;
  Uint8List? _webImage;
  double _fontSize = 32;
  Color _textColor = Colors.white;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<Color> _textColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.green,
    Colors.pink,
    Colors.purple,
    Colors.orange,
  ];

  final List<String> _fontStyles = [
    'Impact',
    'Arial',
    'Comic Sans',
    'Helvetica',
    'Times New Roman',
  ];

  String _selectedFontStyle = 'Impact';

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _captionController.dispose();
    _topTextController.dispose();
    _bottomTextController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = image;
        });

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveMeme() async {
    if (_selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _memeService.postMeme(
          userId: currentUser.uid,
          userName: currentUser.displayName ?? 'Anonymous',
          imagePath: _selectedImageFile!.path,
          caption: _captionController.text,
          topText: _topTextController.text,
          bottomText: _bottomTextController.text,
          textColor: _textColor,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meme created and posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating meme: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
        title: const Text('Create Meme'),
        actions: [
          if (_selectedImageFile != null)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveMeme,
              icon: _isLoading
                  ? Container(
                      width: 20,
                      height: 20,
                      padding: const EdgeInsets.all(2),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
                    message: "Creating your meme...",
                  ),
                )
              : isLargeScreen
                  ? _buildLargeScreenLayout()
                  : _buildResponsiveLayout(isSmallScreen),
        ),
      ),
      floatingActionButton: _selectedImageFile == null
          ? FloatingActionButton.extended(
              onPressed: _selectImage,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Select Image'),
              backgroundColor: Colors.pink,
            )
          : null,
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildMemePreview(true),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildControlPanel(true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveLayout(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMemePreview(isSmallScreen),
          const SizedBox(height: 24),
          _buildControlPanel(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildMemePreview(bool isWideScreen) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWideScreen ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImageFile == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: isWideScreen ? 64 : 48,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Select an image to create your meme',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: isWideScreen ? 18 : 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.memory(
                                      _webImage!,
                                      fit: BoxFit.contain,
                                    )
                                  : Image.file(
                                      File(_selectedImageFile!.path),
                                      fit: BoxFit.contain,
                                    ),
                            ),
                            if (_topTextController.text.isNotEmpty)
                              Positioned(
                                top: 16,
                                left: 16,
                                right: 16,
                                child: Text(
                                  _topTextController.text,
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: _fontSize,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: _selectedFontStyle,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.8),
                                        blurRadius: 3,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (_bottomTextController.text.isNotEmpty)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Text(
                                  _bottomTextController.text,
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: _fontSize,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: _selectedFontStyle,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.8),
                                        blurRadius: 3,
                                        offset: const Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel(bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: isWideScreen ? null : BorderRadius.circular(20),
        border: isWideScreen
            ? null
            : Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize Your Meme',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWideScreen ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _topTextController,
            label: 'Top Text',
            icon: Icons.title,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _bottomTextController,
            label: 'Bottom Text',
            icon: Icons.title,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _captionController,
            label: 'Caption',
            icon: Icons.chat_bubble_outline,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Text Style',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWideScreen ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFontStyleSelector(),
          const SizedBox(height: 24),
          Text(
            'Font Size',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWideScreen ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFontSizeSlider(),
          const SizedBox(height: 24),
          Text(
            'Text Color',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWideScreen ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildColorPicker(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.pink),
        ),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildFontStyleSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _fontStyles.length,
        itemBuilder: (context, index) {
          final style = _fontStyles[index];
          final isSelected = style == _selectedFontStyle;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                style,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontFamily: style,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFontStyle = style);
                }
              },
              backgroundColor: Colors.transparent,
              selectedColor: Colors.pink,
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
    );
  }

  Widget _buildFontSizeSlider() {
    return Column(
      children: [
        Slider(
          value: _fontSize,
          min: 20,
          max: 60,
          divisions: 20,
          label: _fontSize.round().toString(),
          onChanged: (value) => setState(() => _fontSize = value),
          activeColor: Colors.pink,
          inactiveColor: Colors.white.withOpacity(0.3),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '20',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            Text(
              '60',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _textColors.map((color) {
        final isSelected = color == _textColor;
        return GestureDetector(
          onTap: () => setState(() => _textColor = color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.pink : Colors.white,
                width: 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
