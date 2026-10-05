import 'dart:math' as math;

import 'package:flutter/material.dart';

class SparkleStarBadge extends StatefulWidget {
  const SparkleStarBadge({super.key});

  @override
  State<SparkleStarBadge> createState() => _SparkleStarBadgeState();
}

class _SparkleStarBadgeState extends State<SparkleStarBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sparklePulse;
  late final Animation<double> _sparkleTwinkle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _sparklePulse = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _sparkleTwinkle = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final sparkleScale = 0.7 + (0.3 * math.sin(t * math.pi * 2).abs());

        return SizedBox(
          width: 20,
          height: 20,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -4,
                right: -5,
                child: Opacity(
                  opacity: _sparkleTwinkle.value,
                  child: Transform.scale(
                    scale: sparkleScale,
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 8,
                      color: Color(0xFFFFF59D),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -4,
                bottom: -4,
                child: Opacity(
                  opacity: 1 - (_sparkleTwinkle.value * 0.65),
                  child: Transform.scale(
                    scale: 1.1 - (sparkleScale - 0.7),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 6,
                      color: Color(0xFFFFF59D),
                    ),
                  ),
                ),
              ),
              ScaleTransition(
                scale: _sparklePulse,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE100),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
