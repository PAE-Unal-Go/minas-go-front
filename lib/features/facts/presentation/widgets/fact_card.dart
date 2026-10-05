import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design_system.dart';
import '../../domain/entities/university_fact.dart';

class FactCard extends StatefulWidget {
  final UniversityFact fact;
  final int index;

  const FactCard({super.key, required this.fact, required this.index});

  @override
  State<FactCard> createState() => _FactCardState();
}

class _FactCardState extends State<FactCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  static const List<List<Color>> _gradients = [
    [Color(0xFF0E147A), Color(0xFF1C2AD8)],
    [Color(0xFF0F4C75), Color(0xFF1B6CA8)],
    [Color(0xFF0A3D62), Color(0xFF1E6FA7)],
    [Color(0xFF1B1464), Color(0xFF2C3E8C)],
    [Color(0xFF006266), Color(0xFF1289A7)],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  List<Color> get _gradient =>
      _gradients[widget.index % _gradients.length];

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final fact = widget.fact;
    final number = widget.index + 1;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [AppShadows.shadowMd],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            children: [
              _buildHeader(fact, number),
              _buildExpandableBody(fact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UniversityFact fact, int number) {
    return Stack(
      children: [
        if (fact.imageUrl != null && fact.imageUrl!.isNotEmpty)
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: fact.imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _GradientBackground(gradient: _gradient),
            ),
          )
        else
          SizedBox(
            height: 140,
            width: double.infinity,
            child: _GradientBackground(gradient: _gradient),
          ),
        // Overlay oscuro para legibilidad del texto
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.65),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
        ),
        // Badge de número
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '#$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.fontSizeXs,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expand icon
        Positioned(
          top: 12,
          right: 12,
          child: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        // Título y fecha abajo del header
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fact.desbloqueadoAt != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryMain.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Desbloqueado el ${_formatDate(fact.desbloqueadoAt)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: AppTypography.weightMedium,
                    ),
                  ),
                ),
              Text(
                fact.titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTypography.fontSizeMd,
                  fontWeight: AppTypography.weightBold,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black45),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableBody(UniversityFact fact) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: Container(
        width: double.infinity,
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Text(
          fact.descripcion,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTypography.fontSizeSm,
            height: AppTypography.lineHeightRelaxed,
          ),
        ),
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  final List<Color> gradient;
  const _GradientBackground({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.lightbulb_outline_rounded,
          color: Colors.white.withOpacity(0.25),
          size: 56,
        ),
      ),
    );
  }
}
