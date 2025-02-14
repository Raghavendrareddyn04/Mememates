import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;
  int _currentPage = 0;
  bool _isLastPage = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Meme Mates',
      description:
          'Find your perfect match through shared humor and music taste',
      icon: Icons.emoji_emotions,
      color: Colors.pink,
      lottieAsset: 'assets/animations/welcome.json',
    ),
    OnboardingPage(
      title: 'Express Your Vibe',
      description: 'Create stunning mood boards that showcase your personality',
      icon: Icons.dashboard,
      color: Colors.purple,
      lottieAsset: 'assets/animations/mood_board.json',
    ),
    OnboardingPage(
      title: 'Connect Through Memes',
      description: 'Share and discover memes that match your sense of humor',
      icon: Icons.sentiment_very_satisfied,
      color: Colors.deepPurple,
      lottieAsset: 'assets/animations/memes.json',
    ),
    OnboardingPage(
      title: 'Your Perfect Match Awaits',
      description: 'Our AI matches you with people who share your unique vibe',
      icon: Icons.favorite,
      color: Colors.red,
      lottieAsset: 'assets/animations/match.json',
    ),
  ];

  get Lottie => null;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _pageController.addListener(_handlePageChange);
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _cardScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));

    _cardOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeIn,
    ));

    _backgroundController.forward();
    _cardController.forward();
  }

  void _handlePageChange() {
    final page = _pageController.page ?? 0;
    setState(() {
      _currentPage = page.round();
      _isLastPage = page >= _pages.length - 1;
    });
  }

  void _nextPage() {
    if (_isLastPage) {
      _submitForm();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitForm() {
    Navigator.pushReplacementNamed(context, '/profile-setup');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isLargeScreen = size.width > 1200;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
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
                stops: [
                  0.0,
                  _backgroundAnimation.value * 0.5,
                  _backgroundAnimation.value,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(20, (index) {
                  final random = math.Random();
                  return Positioned(
                    left: random.nextDouble() * size.width,
                    top: random.nextDouble() * size.height,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(seconds: 2 + random.nextInt(3)),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(
                            math.sin(value * math.pi * 2) * 20,
                            math.cos(value * math.pi * 2) * 20,
                          ),
                          child: Opacity(
                            opacity: 0.3,
                            child: Container(
                              width: 4 + random.nextDouble() * 4,
                              height: 4 + random.nextDouble() * 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: isLargeScreen
                            ? _buildLargeScreenLayout()
                            : _buildResponsiveLayout(isSmallScreen),
                      ),
                      _buildNavigationSection(isSmallScreen),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pages[_currentPage].title,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn().slideX(),
                const SizedBox(height: 24),
                Text(
                  _pages[_currentPage].description,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ).animate().fadeIn().slideX(delay: 200.ms),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildPageView(true),
        ),
      ],
    );
  }

  Widget _buildResponsiveLayout(bool isSmallScreen) {
    return Column(
      children: [
        Expanded(
          child: _buildPageView(isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildPageView(bool isWideScreen) {
    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      onPageChanged: (int page) {
        setState(() {
          _currentPage = page;
          _isLastPage = page >= _pages.length - 1;
        });
        _cardController.forward(from: 0.0);
      },
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _cardController,
          builder: (context, child) {
            return Transform.scale(
              scale: _cardScale.value,
              child: Opacity(
                opacity: _cardOpacity.value,
                child: Padding(
                  padding: EdgeInsets.all(isWideScreen ? 48.0 : 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isWideScreen) ...[
                        Text(
                          _pages[index].title,
                          style: TextStyle(
                            fontSize: isWideScreen ? 40 : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn().slideY(),
                        const SizedBox(height: 16),
                      ],
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: _pages[index].color.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Lottie.asset(
                              _pages[index].lottieAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      if (!isWideScreen) ...[
                        const SizedBox(height: 24),
                        Text(
                          _pages[index].description,
                          style: TextStyle(
                            fontSize: isWideScreen ? 20 : 16,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn().slideY(delay: 200.ms),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavigationSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  boxShadow: _currentPage == index
                      ? [
                          BoxShadow(
                            color: _pages[index].color.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildNavigationButton(
                      'Back',
                      Icons.arrow_back,
                      () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      isSmallScreen,
                      isSecondary: true,
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: _currentPage > 0 ? 8 : 0),
                  child: _buildNavigationButton(
                    _isLastPage ? 'Get Started' : 'Next',
                    _isLastPage ? Icons.check_circle : Icons.arrow_forward,
                    _nextPage,
                    isSmallScreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
    bool isSmallScreen, {
    bool isSecondary = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSecondary ? Colors.white.withOpacity(0.2) : Colors.white,
        foregroundColor: isSecondary ? Colors.white : Colors.deepPurple,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 24 : 32,
          vertical: isSmallScreen ? 16 : 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        shadowColor:
            (isSecondary ? Colors.black : Colors.white).withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isSecondary) Icon(icon, size: isSmallScreen ? 20 : 24),
          if (!isSecondary) const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isSecondary) const SizedBox(width: 8),
          if (isSecondary) Icon(icon, size: isSmallScreen ? 20 : 24),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String lottieAsset;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.lottieAsset,
  });
}
