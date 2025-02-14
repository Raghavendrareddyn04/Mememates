import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isYearlySelected = true;

  final List<Map<String, dynamic>> _premiumFeatures = [
    {
      'icon': Icons.rocket_launch,
      'title': 'Unlimited Matches',
      'description': 'Connect with as many people as you want',
      'color': Colors.blue,
    },
    {
      'icon': Icons.visibility,
      'title': 'See Who Likes You',
      'description': 'Know your admirers before matching',
      'color': Colors.pink,
    },
    {
      'icon': Icons.star,
      'title': 'Priority Profile',
      'description': 'Get more visibility in the feed',
      'color': Colors.amber,
    },
    {
      'icon': Icons.undo,
      'title': 'Unlimited Rewinds',
      'description': 'Change your mind? No problem!',
      'color': Colors.green,
    },
    {
      'icon': Icons.location_on,
      'title': 'Global Access',
      'description': 'Match with people worldwide',
      'color': Colors.purple,
    },
    {
      'icon': Icons.verified,
      'title': 'Verified Badge',
      'description': 'Stand out with a verified profile',
      'color': Colors.teal,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    children: [
                      _buildHeader(isSmallScreen),
                      const SizedBox(height: 32),
                      if (isLargeScreen)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildPricingSection(false),
                                  const SizedBox(height: 32),
                                  _buildFeatureComparison(false),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildFeatureHighlights(false),
                                  const SizedBox(height: 32),
                                  _buildTestimonials(false),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildPricingSection(isSmallScreen),
                        const SizedBox(height: 32),
                        _buildFeatureHighlights(isSmallScreen),
                        const SizedBox(height: 32),
                        _buildFeatureComparison(isSmallScreen),
                        const SizedBox(height: 32),
                        _buildTestimonials(isSmallScreen),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.pink.shade400,
              Colors.purple.shade400,
            ],
          ).createShader(bounds),
          child: Text(
            'Upgrade to Premium',
            style: TextStyle(
              fontSize: isSmallScreen ? 32 : 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Unlock all features and enhance your experience',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 20,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPricingSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlanToggleButton(
                  'Monthly',
                  !_isYearlySelected,
                  isSmallScreen,
                ),
                _buildPlanToggleButton(
                  'Yearly',
                  _isYearlySelected,
                  isSmallScreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _isYearlySelected ? '\$49' : '\$4',
                style: TextStyle(
                  fontSize: isSmallScreen ? 48 : 64,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '.99',
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _isYearlySelected ? '/year' : '/month',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (_isYearlySelected) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Save 17%',
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handle subscription
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 16 : 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Get Premium',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanToggleButton(
      String label, bool isSelected, bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isYearlySelected = label == 'Yearly';
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: isSmallScreen ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights(bool isSmallScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        final aspectRatio = constraints.maxWidth > 600 ? 1.5 : 1.3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: _premiumFeatures.length,
          itemBuilder: (context, index) {
            final feature = _premiumFeatures[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: feature['color'].withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      feature['icon'],
                      color: feature['color'],
                      size: isSmallScreen ? 24 : 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['description'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureComparison(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feature Comparison',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader('Feature', isSmallScreen),
                  _buildTableHeader('Free', isSmallScreen),
                  _buildTableHeader('Premium', isSmallScreen),
                ],
              ),
              _buildTableRow('Daily Likes', '10', 'Unlimited', isSmallScreen),
              _buildTableRow('See Who Likes You', 'No', 'Yes', isSmallScreen),
              _buildTableRow('Priority Profile', 'No', 'Yes', isSmallScreen),
              _buildTableRow('Rewind Last Swipe', 'No', 'Yes', isSmallScreen),
              _buildTableRow('Global Access', 'No', 'Yes', isSmallScreen),
              _buildTableRow('Ad-Free Experience', 'No', 'Yes', isSmallScreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 14 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  TableRow _buildTableRow(
      String feature, String free, String premium, bool isSmallScreen) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            feature,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            free,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                premium,
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (premium == 'Yes')
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.pink,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonials(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Our Users Say',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildTestimonialCard(
            'Sarah, 28',
            '"Premium is totally worth it! I found my perfect meme match in just a week!"',
            isSmallScreen,
          ),
          const SizedBox(height: 16),
          _buildTestimonialCard(
            'Mike, 32',
            '"The global access feature is amazing. I\'ve connected with people worldwide!"',
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(String name, String text, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isSmallScreen ? 14 : 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              color: Colors.pink,
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
