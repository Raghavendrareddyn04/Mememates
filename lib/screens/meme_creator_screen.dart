import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/meme_service.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

class MemeCreatorScreen extends StatefulWidget {
  const MemeCreatorScreen({super.key});

  @override
  State<MemeCreatorScreen> createState() => _MemeCreatorScreenState();
}

class _MemeCreatorScreenState extends State<MemeCreatorScreen> {
  final _memeService = MemeService();
  final _authService = AuthService();
  final _captionController = TextEditingController();
  final _topTextController = TextEditingController();
  final _bottomTextController = TextEditingController();
  XFile? _selectedImageFile;
  Uint8List? _webImage;
  double _fontSize = 32;
  Color _textColor = Colors.white;
  bool _isLoading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _topTextController.dispose();
    _bottomTextController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

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
          SnackBar(
            content: Text('Error creating meme: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImageFile == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: IconButton(
            icon: const Icon(Icons.add_photo_alternate,
                size: 64, color: Colors.white),
            onPressed: _selectImage,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: kIsWeb
              ? _webImage != null
                  ? Image.memory(_webImage!)
                  : const CircularProgressIndicator()
              : Image.file(File(_selectedImageFile!.path)),
        ),
        Positioned(
          top: 16,
          child: Text(
            _topTextController.text,
            style: TextStyle(
              color: _textColor,
              fontSize: _fontSize,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Positioned(
          bottom: 16,
          child: Text(
            _bottomTextController.text,
            style: TextStyle(
              color: _textColor,
              fontSize: _fontSize,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meme'),
        actions: [
          if (_selectedImageFile != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveMeme,
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildImagePreview(),
                const SizedBox(height: 24),
                if (_selectedImageFile != null) ...[
                  TextField(
                    controller: _topTextController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Top Text',
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bottomTextController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Bottom Text',
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Caption',
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Font Size:',
                        style: TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 20,
                          max: 60,
                          divisions: 20,
                          label: _fontSize.round().toString(),
                          onChanged: (value) =>
                              setState(() => _fontSize = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Text Color:',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          Colors.white,
                          Colors.black,
                          Colors.red,
                          Colors.blue,
                          Colors.yellow,
                        ]
                            .map((color) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _textColor = color),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _textColor == color
                                            ? Colors.pink
                                            : Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedImageFile == null
          ? FloatingActionButton(
              onPressed: _selectImage,
              backgroundColor: Colors.pink,
              child: const Icon(Icons.add_photo_alternate),
            )
          : null,
    );
  }
}
