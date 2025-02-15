import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/unsplash_service.dart';
import '../widgets/loading_animation.dart';
import 'dart:ui';

class MoodBoardEditorScreen extends StatefulWidget {
  final List<String> initialImages;
  final Function(List<String>) onSave;

  const MoodBoardEditorScreen({
    super.key,
    required this.initialImages,
    required this.onSave,
  });

  @override
  State<MoodBoardEditorScreen> createState() => _MoodBoardEditorScreenState();
}

class _MoodBoardEditorScreenState extends State<MoodBoardEditorScreen>
    with SingleTickerProviderStateMixin {
  final _unsplashService = UnsplashService();
  final _cloudinaryService = CloudinaryService();
  final _imagePicker = ImagePicker();
  final _searchController = TextEditingController();
  final List<MoodBoardElement> _elements = [];
  bool _isLoading = false;
  List<UnsplashImage> _searchResults = [];
  Color _backgroundColor = Colors.black;
  bool _showUnsplashSearch = false;
  bool _showColorPicker = false;
  bool _showToolbar = true;
  double _toolbarOpacity = 1.0;
  late AnimationController _animationController;

  final List<Color> _colorPalette = [
    Colors.black,
    Colors.white,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.amber,
    Colors.orange,
    Colors.red,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _initializeElements();
    _initializeAnimations();
  }

  void _initializeElements() {
    _elements.addAll(
      widget.initialImages.map(
        (url) => MoodBoardElement(
          type: ElementType.image,
          content: url,
          position: const Offset(0, 0),
          size: const Size(150, 150),
          rotation: 0,
          scale: 1.0,
        ),
      ),
    );
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationController.forward();
  }

  Future<void> _pickImage() async {
    if (_elements.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 9 images allowed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        final url = await _cloudinaryService.uploadImage(image.path);
        setState(() {
          _elements.add(
            MoodBoardElement(
              type: ElementType.image,
              content: url,
              position: const Offset(50, 50),
              size: const Size(150, 150),
              rotation: 0,
              scale: 1.0,
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _searchImages(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final results = await _unsplashService.searchImages(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching images: $e')),
        );
      }
    }
  }

  Future<void> _addUnsplashImage(UnsplashImage image) async {
    if (_elements.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 9 images allowed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final processedUrl = await _cloudinaryService.processImage(
        image.url,
        width: 300,
        height: 300,
        crop: 'fill',
      );

      setState(() {
        _elements.add(
          MoodBoardElement(
            type: ElementType.image,
            content: processedUrl,
            position: const Offset(50, 50),
            size: const Size(150, 150),
            rotation: 0,
            scale: 1.0,
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding image: $e')),
        );
      }
    }
  }

  void _addText() {
    if (_elements.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 9 elements allowed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        Color selectedColor = Colors.white;
        double selectedSize = 20;
        String selectedFont = 'Arial';

        return AlertDialog(
          backgroundColor: Colors.deepPurple.shade900,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Add Text',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter text',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.white,
                    Colors.pink,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => selectedColor = color,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        Text(
                          'Font Size: ${selectedSize.round()}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Slider(
                          value: selectedSize,
                          min: 12,
                          max: 48,
                          divisions: 36,
                          label: selectedSize.round().toString(),
                          onChanged: (value) =>
                              setState(() => selectedSize = value),
                          activeColor: Colors.pink,
                          inactiveColor: Colors.white.withOpacity(0.3),
                        ),
                        DropdownButtonFormField<String>(
                          value: selectedFont,
                          dropdownColor: Colors.deepPurple.shade900,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Font Family',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            'Arial',
                            'Helvetica',
                            'Times New Roman',
                            'Courier',
                            'Impact',
                          ].map((font) {
                            return DropdownMenuItem(
                              value: font,
                              child: Text(font),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedFont = value);
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  setState(() {
                    _elements.add(
                      MoodBoardElement(
                        type: ElementType.text,
                        content: textController.text,
                        position: const Offset(50, 50),
                        size: Size(selectedSize * 5, selectedSize * 2),
                        style: TextStyle(
                          fontSize: selectedSize,
                          color: selectedColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: selectedFont,
                        ),
                        rotation: 0,
                        scale: 1.0,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveMoodBoard() async {
    if (_elements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one element'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final urls = await Future.wait(
        _elements.map((element) async {
          if (element.type == ElementType.image) {
            return element.content;
          } else {
            return await _cloudinaryService.addOverlay(
              '',
              text: element.type == ElementType.text ? element.content : null,
              overlay:
                  element.type == ElementType.sticker ? element.content : null,
              position: element.position,
            );
          }
        }),
      );

      final finalMoodBoard = await _cloudinaryService.generateMoodBoard(
        _backgroundColor.value.toRadixString(16).substring(2),
        urls,
      );

      widget.onSave([finalMoodBoard]);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving mood board: $e')),
        );
      }
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
        title: const Text('Mood Board Editor'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveMoodBoard,
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
          child: Stack(
            children: [
              if (isLargeScreen)
                _buildLargeScreenLayout()
              else if (!isSmallScreen)
                _buildMediumScreenLayout()
              else
                _buildSmallScreenLayout(),
              if (_showColorPicker) _buildColorPicker(),
              if (_isLoading)
                const LoadingAnimation(
                  message: "Creating your mood board...",
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _toolbarOpacity,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: () {
            setState(() => _showToolbar = !_showToolbar);
          },
          backgroundColor: Colors.pink,
          child: Icon(
            _showToolbar ? Icons.close : Icons.edit,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
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

  Widget _buildMediumScreenLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMemePreview(true),
          const SizedBox(height: 24),
          _buildControlPanel(true),
        ],
      ),
    );
  }

  Widget _buildSmallScreenLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMemePreview(false),
          const SizedBox(height: 16),
          _buildControlPanel(false),
        ],
      ),
    );
  }

  Widget _buildMemePreview(bool isWideScreen) {
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
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _elements.isEmpty
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
                            'Add elements to create your mood board',
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
                      children: _elements.asMap().entries.map((entry) {
                        final index = entry.key;
                        final element = entry.value;
                        return Positioned(
                          left: element.position.dx,
                          top: element.position.dy,
                          child: Transform.rotate(
                            angle: element.rotation,
                            child: Transform.scale(
                              scale: element.scale,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    _elements[index] = element.copyWith(
                                      position:
                                          element.position + details.delta,
                                    );
                                  });
                                },
                                child: _buildElement(element),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(bool isWideScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tools',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWideScreen ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildToolButton(
                icon: Icons.image,
                label: 'Add Image',
                onPressed: _pickImage,
                color: Colors.blue,
              ),
              _buildToolButton(
                icon: Icons.search,
                label: 'Search',
                onPressed: () {
                  setState(() => _showUnsplashSearch = !_showUnsplashSearch);
                },
                color: Colors.green,
              ),
              _buildToolButton(
                icon: Icons.text_fields,
                label: 'Add Text',
                onPressed: _addText,
                color: Colors.orange,
              ),
              _buildToolButton(
                icon: Icons.color_lens,
                label: 'Background',
                onPressed: () {
                  setState(() => _showColorPicker = !_showColorPicker);
                },
                color: Colors.purple,
              ),
            ],
          ),
          if (_showUnsplashSearch) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search Unsplash...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => _searchImages(_searchController.text),
                ),
              ),
              onSubmitted: _searchImages,
            ),
            if (_searchResults.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final image = _searchResults[index];
                    return GestureDetector(
                      onTap: () => _addUnsplashImage(image),
                      child: Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(image.thumbUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {
          setState(() => _showColorPicker = false);
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade900,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Choose Background Color',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colorPalette.map((color) {
                      final isSelected = color == _backgroundColor;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _backgroundColor = color;
                            _showColorPicker = false;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.pink : Colors.white,
                              width: isSelected ? 3 : 1,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElement(MoodBoardElement element) {
    switch (element.type) {
      case ElementType.image:
        return Container(
          width: element.size.width,
          height: element.size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(element.content),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        );
      case ElementType.text:
        return Text(
          element.content,
          style: element.style,
        );
      case ElementType.sticker:
        return Image.network(
          element.content,
          width: element.size.width,
          height: element.size.height,
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

enum ElementType { image, text, sticker }

class MoodBoardElement {
  final ElementType type;
  final String content;
  final Offset position;
  final Size size;
  final TextStyle? style;
  final double rotation;
  final double scale;

  MoodBoardElement({
    required this.type,
    required this.content,
    required this.position,
    required this.size,
    this.style,
    required this.rotation,
    required this.scale,
  });

  MoodBoardElement copyWith({
    ElementType? type,
    String? content,
    Offset? position,
    Size? size,
    TextStyle? style,
    double? rotation,
    double? scale,
  }) {
    return MoodBoardElement(
      type: type ?? this.type,
      content: content ?? this.content,
      position: position ?? this.position,
      size: size ?? this.size,
      style: style ?? this.style,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }
}
