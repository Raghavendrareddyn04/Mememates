import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoadingAnimation extends StatefulWidget {
  final String? message;

  const LoadingAnimation({
    super.key,
    this.message,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _floatingController;
  late Animation<double> _heartScale;
  late Animation<double> _heartBeat;

  final List<Widget> _floatingHearts = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Heart beat animation
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _heartScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _heartController,
        curve: Curves.easeInOut,
      ),
    );

    _heartBeat = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _heartController,
        curve: Curves.easeInOut,
      ),
    );

    // Floating animation
    _floatingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Generate floating hearts
    _generateFloatingHearts();
  }

  void _generateFloatingHearts() {
    for (int i = 0; i < 6; i++) {
      final startX = _random.nextDouble() * 300 - 150;
      final endX = startX + (_random.nextDouble() * 100 - 50);
      final duration = Duration(milliseconds: 1500 + _random.nextInt(1000));
      final size = 20.0 + _random.nextDouble() * 20;

      _floatingHearts.add(
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: duration,
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(
                startX + (endX - startX) * value,
                -200 * value,
              ),
              child: Opacity(
                opacity: 1.0 - value,
                child: Icon(
                  Icons.favorite,
                  color: Colors.pink.withOpacity(0.6),
                  size: size,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ..._floatingHearts,
                AnimatedBuilder(
                  animation: _heartController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _heartScale.value,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.pink.withOpacity(_heartBeat.value),
                        size: 64,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            Text(
              widget.message!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    _floatingController.dispose();
    super.dispose();
  }
}
