import 'package:flutter/material.dart';
import '../services/cloudinary_service.dart';
import '../services/unsplash_service.dart';

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

class _MoodBoardEditorScreenState extends State<MoodBoardEditorScreen> {
  final _unsplashService = UnsplashService();
  final _cloudinaryService = CloudinaryService();
  final _searchController = TextEditingController();
  final List<MoodBoardElement> _elements = [];
  bool _isLoading = false;
  List<UnsplashImage> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeElements();
  }

  void _initializeElements() {
    _elements.addAll(
      widget.initialImages.map(
        (url) => MoodBoardElement(
          type: ElementType.image,
          content: url,
          position: const Offset(0, 0),
          size: const Size(150, 150),
        ),
      ),
    );
  }

  Future<void> _searchImages() async {
    if (_searchController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final results =
          await _unsplashService.searchImages(_searchController.text);
      setState(() => _searchResults = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching images: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addImage(UnsplashImage image) async {
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
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding image: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addText() {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Text'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(hintText: 'Enter text'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  setState(() {
                    _elements.add(
                      MoodBoardElement(
                        type: ElementType.text,
                        content: textController.text,
                        position: const Offset(50, 50),
                        size: const Size(100, 50),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addSticker() {
    // Show sticker picker
    showModalBottomSheet(
      context: context,
      builder: (context) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _stickers.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _elements.add(
                  MoodBoardElement(
                    type: ElementType.sticker,
                    content: _stickers[index],
                    position: const Offset(50, 50),
                    size: const Size(50, 50),
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: Image.network(_stickers[index]),
          );
        },
      ),
    );
  }

  Future<void> _saveMoodBoard() async {
    setState(() => _isLoading = true);
    try {
      final urls = await Future.wait(
        _elements.map((element) async {
          if (element.type == ElementType.image) {
            return element.content;
          } else {
            // Convert text and stickers to images using Cloudinary
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

      widget.onSave(List<String>.from(urls));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving mood board: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Mood Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMoodBoard,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Canvas
          Container(
            color: Colors.black87,
            child: Stack(
              children: _elements.map((element) {
                return Positioned(
                  left: element.position.dx,
                  top: element.position.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        final index = _elements.indexOf(element);
                        _elements[index] = element.copyWith(
                          position: element.position + details.delta,
                        );
                      });
                    },
                    child: _buildElement(element),
                  ),
                );
              }).toList(),
            ),
          ),
          // Tools panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search images...',
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.5)),
                            suffixIcon: IconButton(
                              icon:
                                  const Icon(Icons.search, color: Colors.white),
                              onPressed: _searchImages,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.text_fields, color: Colors.white),
                        onPressed: _addText,
                      ),
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions,
                            color: Colors.white),
                        onPressed: _addSticker,
                      ),
                    ],
                  ),
                  if (_searchResults.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final image = _searchResults[index];
                          return GestureDetector(
                            onTap: () => _addImage(image),
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
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
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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

  MoodBoardElement({
    required this.type,
    required this.content,
    required this.position,
    required this.size,
    this.style,
  });

  MoodBoardElement copyWith({
    ElementType? type,
    String? content,
    Offset? position,
    Size? size,
    TextStyle? style,
  }) {
    return MoodBoardElement(
      type: type ?? this.type,
      content: content ?? this.content,
      position: position ?? this.position,
      size: size ?? this.size,
      style: style ?? this.style,
    );
  }
}

final List<String> _stickers = [
  'https://res.cloudinary.com/demo/image/upload/e_art:audrey/w_100,h_100/sample.jpg',
  'https://res.cloudinary.com/demo/image/upload/e_art:athena/w_100,h_100/sample.jpg',
  'https://res.cloudinary.com/demo/image/upload/e_art:daguerre/w_100,h_100/sample.jpg',
  'https://res.cloudinary.com/demo/image/upload/e_art:eucalyptus/w_100,h_100/sample.jpg',
  'https://res.cloudinary.com/demo/image/upload/e_art:fes/w_100,h_100/sample.jpg',
  'https://res.cloudinary.com/demo/image/upload/e_art:frost/w_100,h_100/sample.jpg',
  'https://res.cloudinary.com/demo/image/upload/e_art:hairspray/w_100,h_100/sample.jpg',
  'https://res.cloudinary.com/demo/image/upload/e_art:hokusai/w_100,h_100/sample.jpg',
];
