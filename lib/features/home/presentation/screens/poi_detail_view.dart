import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_system.dart';
import '../../../../core/utils/poi_rarity.dart';
import '../../../map/domain/entities/punto_de_interes.dart';

class PoiDetailView extends StatefulWidget {
  final PuntoDeInteres punto;
  final String categoryName;

  const PoiDetailView({
    super.key,
    required this.punto,
    required this.categoryName,
  });

  @override
  State<PoiDetailView> createState() => _PoiDetailViewState();
}

class _PoiDetailViewState extends State<PoiDetailView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  String? get _rarity =>
      widget.punto.visitado ? widget.punto.rarity : null;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: switch (_rarity?.toLowerCase()) {
        PoiRarity.legendary => const Duration(milliseconds: 1800),
        PoiRarity.important => const Duration(milliseconds: 2400),
        _ => const Duration(seconds: 2),
      },
    );
    if (_rarity == PoiRarity.important || _rarity == PoiRarity.legendary) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor(_rarity),
      body: Stack(
        children: [
          // Legendary animated background
          if (_rarity == PoiRarity.legendary)
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => CustomPaint(
                painter: _StarfieldPainter(_anim.value),
                child: const SizedBox.expand(),
              ),
            ),

          // Important radial glow bg
          if (_rarity == PoiRarity.important)
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.4,
                  colors: [Color(0xFF2D1A00), Color(0xFF0A0700)],
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                    child: Column(
                      children: [
                        _buildCard(),
                        if (widget.punto.descripcion != null &&
                            widget.punto.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildDescriptionBox(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    final useDark = _rarity != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: useDark ? Colors.white : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ── Background color ──────────────────────────────────────────────────────

  Color _bgColor(String? rarity) => switch (rarity?.toLowerCase()) {
        PoiRarity.basic => const Color(0xFFEDF9F8),
        PoiRarity.important => const Color(0xFF0A0700),
        PoiRarity.legendary => Colors.black,
        _ => const Color(0xFFE7E8EE),
      };

  // ── Card dispatcher ───────────────────────────────────────────────────────

  Widget _buildCard() => switch (_rarity?.toLowerCase()) {
        PoiRarity.legendary => _legendaryCard(),
        PoiRarity.important => _importantCard(),
        PoiRarity.basic => _basicCard(),
        _ => _lockedCard(),
      };

  // ─────────────────────────────────────────────────────────────────────────
  // LOCKED / plain card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _lockedCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [AppShadows.shadowMd],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _image(height: 240),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.categoryName,
                      style: const TextStyle(
                          color: Color(0xFF6A7587),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(widget.punto.nombre,
                      style: const TextStyle(
                          color: Color(0xFF091436),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BASIC ◆  — clean teal card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _basicCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF2DD4BF),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2DD4BF).withValues(alpha: 0.40),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _image(height: 250),
                  // Subtle diagonal sheen
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-1, -1),
                          end: const Alignment(1, 1),
                          colors: [
                            Colors.transparent,
                            const Color(0xFF2DD4BF).withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom fade
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.20),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rarityChip(
                      label: '◆  BÁSICO',
                      color: const Color(0xFF2DD4BF),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.punto.nombre,
                        style: const TextStyle(
                            color: Color(0xFF091436),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.2)),
                    const SizedBox(height: 4),
                    Text(widget.categoryName,
                        style: const TextStyle(
                            color: Color(0xFF6A7587),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IMPORTANT ◆◆  — dark card, animated gold border + shimmer
  // ─────────────────────────────────────────────────────────────────────────

  Widget _importantCard() {
    // Inner content built once (child of AnimatedBuilder)
    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFF1A0E00),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _image(height: 250),
                // Bottom dark fade into card bg
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF1A0E00).withValues(alpha: 0.75),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Animated gold shimmer sweep
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) {
                    final sweep = -2.0 + _anim.value * 4.0;
                    return Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(sweep - 0.5, -1),
                            end: Alignment(sweep + 0.5, 1),
                            colors: [
                              Colors.transparent,
                              const Color(0xFFF59E0B).withValues(alpha: 0.30),
                              Colors.white.withValues(alpha: 0.22),
                              const Color(0xFFFEF08A).withValues(alpha: 0.30),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rarityChip(
                    label: '◆◆  IMPORTANTE',
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  // Gold shimmer name
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [
                        Color(0xFFFCD34D),
                        Colors.white,
                        Color(0xFFFCD34D),
                      ],
                    ).createShader(rect),
                    child: Text(
                      widget.punto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.categoryName,
                      style: const TextStyle(
                          color: Color(0xFFFCD34D),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Animated gold border wrapper
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final t = _anim.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + t * 3, -1),
              end: Alignment(-0.5 + t * 3, 1),
              colors: const [
                Color(0xFF78350F),
                Color(0xFFF59E0B),
                Color(0xFFFEF08A),
                Color(0xFFF59E0B),
                Color(0xFF78350F),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                blurRadius: 36,
                spreadRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(2.5),
          child: child!,
        );
      },
      child: inner,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LEGENDARY ✦  — full-art card, rotating rainbow border, particles, blur
  // ─────────────────────────────────────────────────────────────────────────

  Widget _legendaryCard() {
    // Inner full-art stack — built once as child
    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 63 / 88, // Standard Pokémon card ratio
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-art image
            _image(height: double.infinity),

            // Rainbow shimmer diagonal sweep
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) {
                final sweep = -2.0 + _anim.value * 4.0;
                return Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(sweep - 0.7, -1),
                        end: Alignment(sweep + 0.7, 1),
                        colors: [
                          Colors.transparent,
                          const Color(0xFFE879F9).withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.28),
                          const Color(0xFF4D96FF).withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Second shimmer going opposite direction (depth feel)
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) {
                final sweep = 2.0 - _anim.value * 4.0;
                return Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(sweep - 0.5, 1),
                        end: Alignment(sweep + 0.5, -1),
                        colors: [
                          Colors.transparent,
                          const Color(0xFFFFD93D).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Sparkle particles
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => CustomPaint(
                painter: _SparklesPainter(_anim.value),
              ),
            ),

            // Bottom glassmorphism info overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _legendaryInfoOverlay(),
            ),

            // Top-right rarity badge
            Positioned(
              top: 14,
              right: 14,
              child: _legendaryRarityBadge(),
            ),
          ],
        ),
      ),
    );

    // Rotating rainbow border wrapper
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final t = _anim.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: SweepGradient(
              transform: GradientRotation(t * 2 * math.pi),
              colors: const [
                Color(0xFFFF6B6B),
                Color(0xFFFFD93D),
                Color(0xFF6BCB77),
                Color(0xFF4D96FF),
                Color(0xFFE879F9),
                Color(0xFFFF6B6B),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE879F9).withValues(
                    alpha: 0.45 + 0.20 * math.sin(t * 2 * math.pi)),
                blurRadius: 44 + 12 * math.sin(t * 2 * math.pi),
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFF4D96FF).withValues(alpha: 0.30),
                blurRadius: 64,
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: child!,
        );
      },
      child: inner,
    );
  }

  Widget _legendaryInfoOverlay() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✦  LEGENDARIO',
                style: TextStyle(
                  color: Color(0xFFE879F9),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 10),
              // Animated rainbow name
              AnimatedBuilder(
                animation: _anim,
                builder: (_, __) {
                  final t = _anim.value;
                  return ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        Color(0xFFE879F9),
                        Colors.white,
                        Color(0xFF4D96FF),
                        Colors.white,
                        Color(0xFFE879F9),
                      ],
                      stops: [
                        (t - 0.4).clamp(0.0, 1.0),
                        (t - 0.1).clamp(0.0, 1.0),
                        t.clamp(0.0, 1.0),
                        (t + 0.1).clamp(0.0, 1.0),
                        (t + 0.4).clamp(0.0, 1.0),
                      ],
                    ).createShader(rect),
                    child: Text(
                      widget.punto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 5),
              Text(
                widget.categoryName,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendaryRarityBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE879F9).withValues(alpha: 0.70),
              width: 1.5,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✦',
                  style: TextStyle(
                      color: Color(0xFFE879F9),
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
              SizedBox(width: 6),
              Text('LEGENDARIO',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _image({required double height}) {
    final url = widget.punto.mainImageUrl;
    Widget img;
    if (url != null && url.isNotEmpty) {
      img = url.startsWith('http')
          ? Image.network(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder())
          : Image.asset(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder());
    } else {
      img = _placeholder();
    }

    return height == double.infinity
        ? Positioned.fill(child: img)
        : SizedBox(height: height, width: double.infinity, child: img);
  }

  Widget _placeholder() {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.primary),
      child: Center(
        child: Icon(Icons.place_rounded, color: Colors.white54, size: 56),
      ),
    );
  }

  Widget _rarityChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ── Description section ───────────────────────────────────────────────────

  Widget _buildDescriptionBox() {
    final isDark =
        _rarity == PoiRarity.important || _rarity == PoiRarity.legendary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.12))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                ),
              ],
      ),
      child: Text(
        widget.punto.descripcion!,
        style: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.85)
              : const Color(0xFF091436),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.55,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

/// Starfield background for legendary screen
class _StarfieldPainter extends CustomPainter {
  final double t;
  _StarfieldPainter(this.t);

  static final _rng = math.Random(42);
  static final _stars = List.generate(
    50,
    (_) => _Star(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      phase: _rng.nextDouble(),
      radius: 0.8 + _rng.nextDouble() * 1.8,
      color: const [
        Color(0xFFE879F9),
        Color(0xFF4D96FF),
        Color(0xFFFFD93D),
        Colors.white,
        Color(0xFF6BCB77),
      ][_rng.nextInt(5)],
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final alpha =
          (0.25 + 0.75 * math.sin((t + s.phase) * 2 * math.pi)).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        Paint()..color = s.color.withValues(alpha: alpha * 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.t != t;
}

class _Star {
  final double x, y, phase, radius;
  final Color color;
  const _Star(
      {required this.x,
      required this.y,
      required this.phase,
      required this.radius,
      required this.color});
}

/// Cross-sparkles scattered over the legendary card image
class _SparklesPainter extends CustomPainter {
  final double t;
  _SparklesPainter(this.t);

  static final _rng = math.Random(7);
  static final _positions =
      List.generate(16, (_) => Offset(_rng.nextDouble(), _rng.nextDouble()));
  static final _phases =
      List.generate(16, (_) => _rng.nextDouble());
  static const _colors = [
    Color(0xFFFFD93D),
    Color(0xFFE879F9),
    Color(0xFF4D96FF),
    Colors.white,
    Color(0xFF6BCB77),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _positions.length; i++) {
      final alpha =
          math.sin((_phases[i] + t) * 2 * math.pi);
      if (alpha <= 0) continue;

      final pos = Offset(
          _positions[i].dx * size.width, _positions[i].dy * size.height);
      final r = 1.5 + alpha * 3.0;
      final color = _colors[i % _colors.length];

      // Glowing dot
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.90)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );

      // Cross lines
      final linePaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.65)
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round;
      final len = r * 2.8;
      canvas.drawLine(
          Offset(pos.dx - len, pos.dy), Offset(pos.dx + len, pos.dy), linePaint);
      canvas.drawLine(
          Offset(pos.dx, pos.dy - len), Offset(pos.dx, pos.dy + len), linePaint);
    }
  }

  @override
  bool shouldRepaint(_SparklesPainter old) => old.t != t;
}
