import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'dart:ui';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
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
            const SnackBar(
              content: Text('Settings saved successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMediumScreen = size.width >= 600 && size.width < 1200;
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
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveSettings,
            icon: const Icon(Icons.save, color: Colors.white),
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
      body: _isLoading
          ? _buildLoadingState()
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
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: isLargeScreen
                        ? _buildLargeScreenLayout()
                        : isMediumScreen
                            ? _buildMediumScreenLayout()
                            : _buildSmallScreenLayout(),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading your preferences...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSection(
                  title: 'Discovery Preferences',
                  icon: Icons.explore,
                  children: [
                    _buildAgeRangeSlider(),
                    const SizedBox(height: 24),
                    _buildGenderPreference(),
                    const SizedBox(height: 24),
                    _buildDistanceSlider(),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          color: Colors.white.withOpacity(0.1),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSection(
                  title: 'App Preferences',
                  icon: Icons.settings,
                  children: _buildAppPreferences(),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Meme Categories',
                  icon: Icons.category,
                  children: [
                    _buildMemeCategories(),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          color: Colors.white.withOpacity(0.1),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSection(
                  title: 'Account',
                  icon: Icons.person,
                  children: [
                    _buildAccountOptions(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediumScreenLayout() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSection(
                  title: 'Discovery Preferences',
                  icon: Icons.explore,
                  children: [
                    _buildAgeRangeSlider(),
                    const SizedBox(height: 24),
                    _buildGenderPreference(),
                    const SizedBox(height: 24),
                    _buildDistanceSlider(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'App Preferences',
                  icon: Icons.settings,
                  children: _buildAppPreferences(),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          color: Colors.white.withOpacity(0.1),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSection(
                  title: 'Meme Categories',
                  icon: Icons.category,
                  children: [
                    _buildMemeCategories(),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Account',
                  icon: Icons.person,
                  children: [
                    _buildAccountOptions(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection(
            title: 'Discovery Preferences',
            icon: Icons.explore,
            children: [
              _buildAgeRangeSlider(),
              const SizedBox(height: 24),
              _buildGenderPreference(),
              const SizedBox(height: 24),
              _buildDistanceSlider(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'App Preferences',
            icon: Icons.settings,
            children: _buildAppPreferences(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Meme Categories',
            icon: Icons.category,
            children: [
              _buildMemeCategories(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Account',
            icon: Icons.person,
            children: [
              _buildAccountOptions(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.pink),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAppPreferences() {
    return [
      _buildSwitchTile(
        title: 'Autoplay Music',
        subtitle: 'Play music automatically in profiles',
        icon: Icons.music_note,
        value: _autoplayMusic,
        onChanged: (value) => setState(() => _autoplayMusic = value),
      ),
      _buildSwitchTile(
        title: 'Show Age',
        subtitle: 'Display your age on your profile',
        icon: Icons.cake,
        value: _showAge,
        onChanged: (value) => setState(() => _showAge = value),
      ),
      _buildSwitchTile(
        title: 'Private Mood Board',
        subtitle: 'Only matches can see your mood board',
        icon: Icons.lock,
        value: _privateMoodBoard,
        onChanged: (value) => setState(() => _privateMoodBoard = value),
      ),
      _buildSwitchTile(
        title: 'Show Online Status',
        subtitle: 'Let others see when you are active',
        icon: Icons.visibility,
        value: _showOnlineStatus,
        onChanged: (value) => setState(() => _showOnlineStatus = value),
      ),
      _buildSwitchTile(
        title: 'Receive Notifications',
        subtitle: 'Get notified about new matches and messages',
        icon: Icons.notifications,
        value: _receiveNotifications,
        onChanged: (value) => setState(() => _receiveNotifications = value),
      ),
    ];
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.pink.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.pink),
        ),
        activeColor: Colors.pink,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _buildAgeRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Age Range',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.pink,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.pink.withOpacity(0.3),
            valueIndicatorColor: Colors.pink,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
          ),
          child: RangeSlider(
            values: _ageRange,
            min: 18,
            max: 100,
            divisions: 82,
            labels: RangeLabels(
              _ageRange.start.round().toString(),
              _ageRange.end.round().toString(),
            ),
            onChanged: (values) => setState(() => _ageRange = values),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPreference() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show Me',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _preferredGender,
            style: const TextStyle(color: Colors.white),
            dropdownColor: Colors.deepPurple.shade900,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: ['All', 'Male', 'Female', 'Non-binary']
                .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _preferredGender = value),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Maximum Distance',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_maxDistance.round()} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.pink,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.pink.withOpacity(0.3),
            valueIndicatorColor: Colors.pink,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
          ),
          child: Slider(
            value: _maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            label: '${_maxDistance.round()} km',
            onChanged: (value) => setState(() => _maxDistance = value),
          ),
        ),
      ],
    );
  }

  Widget _buildMemeCategories() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _memeCategories.map((category) {
        final isSelected = _selectedCategories.contains(category);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedCategories.add(category);
                } else {
                  _selectedCategories.remove(category);
                }
              });
            },
            backgroundColor: Colors.white.withOpacity(0.1),
            selectedColor: Colors.pink,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? Colors.pink : Colors.white24,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccountOptions() {
    return Column(
      children: [
        _buildAccountOption(
          title: 'Privacy Policy',
          icon: Icons.privacy_tip,
          onTap: () {
            // Navigate to privacy policy
          },
        ),
        _buildAccountOption(
          title: 'Terms of Service',
          icon: Icons.description,
          onTap: () {
            // Navigate to terms of service
          },
        ),
        _buildAccountOption(
          title: 'Logout',
          icon: Icons.logout,
          onTap: () => _showLogoutDialog(),
          isDestructive: true,
        ),
        _buildAccountOption(
          title: 'Deactivate Account',
          icon: Icons.delete_forever,
          onTap: () => _showDeactivateDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildAccountOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDestructive ? Colors.red : Colors.pink).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Colors.pink,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white54,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
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
            onPressed: () async {
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
        backgroundColor: Colors.deepPurple.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Deactivate Account',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to deactivate your account? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
