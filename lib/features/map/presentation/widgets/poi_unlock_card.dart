import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../domain/entities/punto_de_interes.dart';
import '../../domain/entities/categoria.dart';
import '../../../../core/theme/app_design_system.dart';

class PoiUnlockCard extends StatefulWidget {
  final PuntoDeInteres punto;
  final VoidCallback onClose;

  const PoiUnlockCard({
    super.key,
    required this.punto,
    required this.onClose,
  });

  @override
  State<PoiUnlockCard> createState() => _PoiUnlockCardState();
}

class _PoiUnlockCardState extends State<PoiUnlockCard>
    with TickerProviderStateMixin {
  late final AnimationController _flashController;
  late final AnimationController _flipController;
  late final AnimationController _shimmerController;
  late final AudioPlayer _audioPlayer;

  late final Animation<double> _flashOpacity;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _shimmerAnim;
  late final Animation<double> _badgeScale;

  bool _showCard = false;
  bool _showBadge = false;

  @override
  void initState() {
    super.initState();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));

    _cardScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.4, end: 1.05)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 70),
      TweenSequenceItem(
          tween: Tween(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(_flipController);

    _cardOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _flipController, curve: const Interval(0, 0.3)));

    _shimmerAnim = Tween(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _flipController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _audioPlayer = AudioPlayer();
    _runAnimation();
  }

  Future<void> _runAnimation() async {
    await _flashController.forward();
    if (mounted) {
      setState(() => _showCard = true);
      _audioPlayer.play(AssetSource('sounds/capture.mp3')).catchError((e) => debugPrint('Error playing capture: $e'));
    }
    await _flipController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _showBadge = true);
  }

  @override
  void dispose() {
    _flashController.dispose();
    _flipController.dispose();
    _shimmerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background radial glow
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF1C2AD8),
                  Color(0xFF0A0F5A),
                  Colors.black,
                ],
              ),
            ),
          ),

          if (_showCard) _buildShimmerParticles(),

          AnimatedBuilder(
            animation: _flashOpacity,
            builder: (_, __) => IgnorePointer(
              child: Container(
                color: Colors.white.withValues(alpha: _flashOpacity.value),
              ),
            ),
          ),

          // Main card
          if (_showCard)
            Center(
              child: AnimatedBuilder(
                animation: _flipController,
                builder: (_, child) => Transform.scale(
                  scale: _cardScale.value,
                  child: Opacity(
                    opacity: _cardOpacity.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
                child: _buildCard(),
              ),
            ),

          // Top label
          if (_showCard)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _flipController,
                builder: (_, __) => Opacity(
                  opacity: _cardOpacity.value.clamp(0.0, 1.0),
                  child: const Column(
                    children: [
                      Text(
                        '¡LUGAR DESCUBIERTO!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerParticles() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        return CustomPaint(
          painter: _RadialRayPainter(_shimmerController.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  Widget _buildCard() {
    final punto = widget.punto;
    final hasImage = punto.mainImageUrl != null && punto.mainImageUrl!.isNotEmpty;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2AD8), Color(0xFF0E147A)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withValues(alpha: 0.7),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image hero section
            Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: hasImage
                      ? Image.network(
                          punto.mainImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0E147A).withValues(alpha: 0.85),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // Category badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryMain.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Categoria.humanNombre(punto.categoria),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Unlock badge
                if (_showBadge)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ScaleTransition(
                      scale: _badgeScale,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _shimmerAnim,
                    builder: (_, child) => ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Colors.white,
                          Color(0xFF99F6E4),
                          Colors.white,
                        ],
                        stops: [
                          (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                          _shimmerAnim.value.clamp(0.0, 1.0),
                          (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ).createShader(rect),
                      child: child!,
                    ),
                    child: Text(
                      punto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.secondaryMain, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${punto.campus} · ${punto.universidad}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (punto.descripcion != null && punto.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        punto.descripcion!,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Close button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryMain,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '¡Genial! 🎉',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C2AD8), Color(0xFF2DD4BF)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.place_rounded, color: Colors.white54, size: 64),
      ),
    );
  }
}

class _RadialRayPainter extends CustomPainter {
  final double progress;
  _RadialRayPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const rays = 12;
    final angleStep = (2 * math.pi) / rays;
    final rotation = progress * 2 * math.pi;

    for (int i = 0; i < rays; i++) {
      final rayAngle = i * angleStep + rotation;
      final path = Path();
      path.moveTo(center.dx, center.dy);
      
      // Calculate a large enough radius to cover the screen
      final r = size.longestSide * 2;
      final x1 = center.dx + r * math.cos(rayAngle - 0.12);
      final y1 = center.dy + r * math.sin(rayAngle - 0.12);
      final x2 = center.dx + r * math.cos(rayAngle + 0.12);
      final y2 = math.sin(rayAngle + 0.12) * r + center.dy;
      
      path.lineTo(x1, y1);
      path.lineTo(x2, y2);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RadialRayPainter old) => true;
}


