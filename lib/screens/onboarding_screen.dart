import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Meme Mates',
      description:
          'Find your perfect match through shared humor and music taste',
      icon: Icons.emoji_emotions,
      color: Colors.pink,
    ),
    OnboardingPage(
      title: 'Mood Boards',
      description:
          'Create and share your mood boards to express your personality',
      icon: Icons.dashboard,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'Meme & Music',
      description: 'Connect through shared memes and music preferences',
      icon: Icons.music_note,
      color: Colors.deepPurple,
    ),
    OnboardingPage(
      title: 'Vibe Curation',
      description: 'Our unique algorithm matches you based on your vibe',
      icon: Icons.favorite,
      color: Colors.red,
    ),
  ];

  void _submitForm() {
    Navigator.pushReplacementNamed(context, '/profile-setup');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isLargeScreen = size.width > 1200;

    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        if (isLargeScreen) {
                          return _buildLargeScreenPage(_pages[index]);
                        } else if (!isSmallScreen) {
                          return _buildMediumScreenPage(_pages[index]);
                        } else {
                          return _buildSmallScreenPage(_pages[index]);
                        }
                      },
                    );
                  },
                ),
              ),
              _buildNavigationSection(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallScreenPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedIcon(page, 60),
          const SizedBox(height: 32),
          _buildTitle(page, 28),
          const SizedBox(height: 16),
          _buildDescription(page, 16),
        ],
      ),
    );
  }

  Widget _buildMediumScreenPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedIcon(page, 80),
          const SizedBox(height: 48),
          _buildTitle(page, 36),
          const SizedBox(height: 24),
          _buildDescription(page, 20),
        ],
      ),
    );
  }

  Widget _buildLargeScreenPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Row(
        children: [
          Expanded(
            child: _buildAnimatedIcon(page, 120),
          ),
          const SizedBox(width: 60),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(page, 48),
                const SizedBox(height: 32),
                _buildDescription(page, 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(OnboardingPage page, double size) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size * 2,
            height: size * 2,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: size,
              color: page.color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(OnboardingPage page, double fontSize) {
    return Text(
      page.title,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            color: page.color.withOpacity(0.5),
            blurRadius: 10,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(OnboardingPage page, double fontSize) {
    return Text(
      page.description,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.white.withOpacity(0.8),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildNavigationSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 32 : 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? _pages[index].color
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_currentPage > 0)
                _buildNavigationButton(
                  'Previous',
                  Icons.arrow_back,
                  () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  isSmallScreen,
                ),
              _buildNavigationButton(
                _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                _currentPage < _pages.length - 1
                    ? Icons.arrow_forward
                    : Icons.check_circle,
                () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _submitForm();
                  }
                },
                isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(
      String text, IconData icon, VoidCallback onPressed, bool isSmallScreen) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 24 : 32,
          vertical: isSmallScreen ? 16 : 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 20 : 24),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
