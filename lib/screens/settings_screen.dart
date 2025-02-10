import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userService = UserService();
  final _authService = AuthService();
  bool _isLoading = true;

  // App Preferences
  bool _autoplayMusic = true;
  bool _showAge = true;
  bool _privateMoodBoard = false;
  bool _showOnlineStatus = true;
  bool _receiveNotifications = true;

  // Discovery Preferences
  RangeValues _ageRange = const RangeValues(18, 35);
  String? _preferredGender;
  double _maxDistance = 50;
  final List<String> _memeCategories = [
    'Funny',
    'Wholesome',
    'Gaming',
    'Music',
    'Movies',
    'Anime'
  ];
  final Set<String> _selectedCategories = {'Funny', 'Music'};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final settings = await _userService.getUserSettings(currentUser.uid);
        if (settings != null) {
          setState(() {
            _autoplayMusic = settings['autoplayMusic'] ?? true;
            _showAge = settings['showAge'] ?? true;
            _privateMoodBoard = settings['privateMoodBoard'] ?? false;
            _showOnlineStatus = settings['showOnlineStatus'] ?? true;
            _receiveNotifications = settings['receiveNotifications'] ?? true;
            _ageRange = RangeValues(
              (settings['minAge'] ?? 18).toDouble(),
              (settings['maxAge'] ?? 35).toDouble(),
            );
            _preferredGender = settings['preferredGender'];
            _maxDistance = (settings['maxDistance'] ?? 50).toDouble();
            _selectedCategories.clear();
            _selectedCategories.addAll(
              List<String>.from(
                  settings['selectedCategories'] ?? ['Funny', 'Music']),
            );
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _userService.updateUserSettings(
          userId: currentUser.uid,
          settings: {
            'autoplayMusic': _autoplayMusic,
            'showAge': _showAge,
            'privateMoodBoard': _privateMoodBoard,
            'showOnlineStatus': _showOnlineStatus,
            'receiveNotifications': _receiveNotifications,
            'minAge': _ageRange.start.round(),
            'maxAge': _ageRange.end.round(),
            'preferredGender': _preferredGender,
            'maxDistance': _maxDistance.round(),
            'selectedCategories': _selectedCategories.toList(),
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: const Text(
          'Are you sure you want to deactivate your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final currentUser = _authService.currentUser;
                if (currentUser != null) {
                  await _userService.deactivateAccount(currentUser.uid);
                  await _authService.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deactivating account: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.black),
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
              Colors.deepPurple.shade700,
              Colors.purple.shade500,
            ],
          ),
        ),
        child: ListView(
          children: [
            _buildSection(
              title: 'Discovery Preferences',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Age Range',
                        style: TextStyle(color: Colors.white),
                      ),
                      RangeSlider(
                        values: _ageRange,
                        min: 18,
                        max: 100,
                        divisions: 82,
                        labels: RangeLabels(
                          _ageRange.start.round().toString(),
                          _ageRange.end.round().toString(),
                        ),
                        onChanged: (values) =>
                            setState(() => _ageRange = values),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _preferredGender,
                        decoration: InputDecoration(
                          labelText: 'Interested In',
                          labelStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        dropdownColor: Colors.deepPurple,
                        style: const TextStyle(color: Colors.white),
                        items: ['Male', 'Female', 'Non-binary', 'Everyone']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _preferredGender = value),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Maximum Distance',
                        style: TextStyle(color: Colors.white),
                      ),
                      Slider(
                        value: _maxDistance,
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: '${_maxDistance.round()} km',
                        onChanged: (value) =>
                            setState(() => _maxDistance = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildSection(
              title: 'App Preferences',
              children: [
                SwitchListTile(
                  value: _autoplayMusic,
                  onChanged: (value) => setState(() => _autoplayMusic = value),
                  title: const Text(
                    'Autoplay Music',
                    style: TextStyle(color: Colors.white),
                  ),
                  secondary: const Icon(Icons.music_note, color: Colors.white),
                ),
                SwitchListTile(
                  value: _showAge,
                  onChanged: (value) => setState(() => _showAge = value),
                  title: const Text(
                    'Show Age',
                    style: TextStyle(color: Colors.white),
                  ),
                  secondary: const Icon(Icons.cake, color: Colors.white),
                ),
                SwitchListTile(
                  value: _privateMoodBoard,
                  onChanged: (value) =>
                      setState(() => _privateMoodBoard = value),
                  title: const Text(
                    'Private Mood Board',
                    style: TextStyle(color: Colors.white),
                  ),
                  secondary: const Icon(Icons.lock, color: Colors.white),
                ),
                SwitchListTile(
                  value: _showOnlineStatus,
                  onChanged: (value) =>
                      setState(() => _showOnlineStatus = value),
                  title: const Text(
                    'Show Online Status',
                    style: TextStyle(color: Colors.white),
                  ),
                  secondary: const Icon(Icons.visibility, color: Colors.white),
                ),
                SwitchListTile(
                  value: _receiveNotifications,
                  onChanged: (value) =>
                      setState(() => _receiveNotifications = value),
                  title: const Text(
                    'Receive Notifications',
                    style: TextStyle(color: Colors.white),
                  ),
                  secondary:
                      const Icon(Icons.notifications, color: Colors.white),
                ),
                ExpansionTile(
                  leading: const Icon(Icons.category, color: Colors.white),
                  title: const Text(
                    'Meme Categories',
                    style: TextStyle(color: Colors.white),
                  ),
                  children: _memeCategories.map((category) {
                    return CheckboxListTile(
                      value: _selectedCategories.contains(category),
                      onChanged: (selected) {
                        setState(() {
                          if (selected ?? false) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                      title: Text(
                        category,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            _buildSection(
              title: 'Account',
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.white),
                  title: const Text(
                    'Privacy Policy',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // Navigate to privacy policy
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.white),
                  title: const Text(
                    'Terms of Service',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // Navigate to terms of service
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: _showLogoutDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Deactivate Account',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: _showDeactivateDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ...children,
        const Divider(color: Colors.white24),
      ],
    );
  }
}
