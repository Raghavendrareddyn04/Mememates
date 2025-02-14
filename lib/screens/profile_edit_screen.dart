import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../services/cloudinary_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;
  final VoidCallback onProfileUpdated;

  const ProfileEditScreen({
    super.key,
    this.initialProfile,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _userService = UserService();
  final _cloudinaryService = CloudinaryService();
  final _imagePicker = ImagePicker();

  List<String> _moodBoardImages = [];
  String? _selectedSong;
  String? _profileImageUrl;
  bool _isLoading = false;
  int? _age;
  String? _gender;
  String? _preferredGender;
  List<String> _interests = [];
  String? _artistName;
  String? _songTitle;

  final List<String> _genderOptions = ['Male', 'Female', 'Non-binary', 'Other'];
  final List<String> _preferredGenderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Other',
    'All'
  ];
  final List<String> _interestOptions = [
    'Memes',
    'Gaming',
    'Music',
    'Movies',
    'Travel',
    'Food',
    'Art',
    'Sports',
    'Technology',
    'Fashion',
    'Photography',
    'Reading'
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFields();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  void _initializeFields() {
    if (widget.initialProfile != null) {
      _nameController.text = widget.initialProfile!['name'] ?? '';
      _bioController.text = widget.initialProfile!['bio'] ?? '';
      _moodBoardImages =
          List<String>.from(widget.initialProfile!['moodBoardImages'] ?? []);
      _selectedSong = widget.initialProfile!['anthem'];
      _profileImageUrl = widget.initialProfile!['profileImage'];
      _age = widget.initialProfile!['age'];
      _gender = widget.initialProfile!['gender'];

      // Convert 'Both' to 'All' for backward compatibility
      final preferredGender = widget.initialProfile!['preferredGender'];
      _preferredGender = preferredGender == 'Both' ? 'All' : preferredGender;

      _interests = List<String>.from(widget.initialProfile!['interests'] ?? []);
      _artistName = widget.initialProfile!['artistName'];
      _songTitle = widget.initialProfile!['songTitle'];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() => _isLoading = true);
        final url = await _cloudinaryService.uploadImage(image.path);
        setState(() {
          _profileImageUrl = url;
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        await _userService.updateUserProfile(
          userId: currentUser.uid,
          name: _nameController.text,
          bio: _bioController.text,
          moodBoardImages: _moodBoardImages,
          anthem: _selectedSong,
          profileImage: _profileImageUrl,
          age: _age,
          gender: _gender,
          preferredGender: _preferredGender,
          artistName: _artistName,
          songTitle: _songTitle,
          interests: _interests,
        );

        if (!mounted) return;
        widget.onProfileUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveProfile,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : size.width * 0.1,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        _buildProfileImageSection(isSmallScreen),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Basic Information'),
                                const SizedBox(height: 16),
                                _buildBasicInfoFields(isSmallScreen),
                                const SizedBox(height: 32),
                                _buildSectionTitle('Interests'),
                                const SizedBox(height: 16),
                                _buildInterestsSection(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProfileImageSection(bool isSmallScreen) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: isSmallScreen ? 120 : 160,
            height: isSmallScreen ? 120 : 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child: _profileImageUrl == null
                  ? Icon(
                      Icons.person,
                      size: isSmallScreen ? 60 : 80,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showImagePickerOptions(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoFields(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration('Name', Icons.person),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _age?.toString() ?? '',
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration('Age', Icons.cake),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Age is required';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 18) {
                    return 'Must be at least 18';
                  }
                  return null;
                },
                onChanged: (value) =>
                    setState(() => _age = int.tryParse(value)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _gender,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.deepPurple,
                decoration: _buildInputDecoration('Gender', Icons.people),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _gender = value),
                validator: (value) =>
                    value == null ? 'Gender is required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _preferredGender,
          style: const TextStyle(color: Colors.white),
          dropdownColor: Colors.deepPurple,
          decoration: _buildInputDecoration('Interested In', Icons.favorite),
          items: _preferredGenderOptions.map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: (value) => setState(() => _preferredGender = value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: _buildInputDecoration('Bio', Icons.edit),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _interestOptions.map((interest) {
          final isSelected = _interests.contains(interest);
          return FilterChip(
            label: Text(interest),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _interests.add(interest);
                } else {
                  _interests.remove(interest);
                }
              });
            },
            backgroundColor: Colors.white.withOpacity(0.1),
            selectedColor: Colors.pink,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        }).toList(),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
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
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Picture',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImagePickerOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImagePickerOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.pink,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
