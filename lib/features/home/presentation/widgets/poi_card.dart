import 'package:flutter/material.dart';

class PoiCard extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final String? description;
  final bool discovered;
  final VoidCallback? onTap;

  const PoiCard({
    super.key,
    required this.name,
    this.imageUrl,
    this.description,
    this.discovered = false,
    this.onTap,
  });

  @override
  State<PoiCard> createState() => _PoiCardState();
}

class _PoiCardState extends State<PoiCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.discovered
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or placeholder
                _buildBackground(),

                // Gradient overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: widget.discovered
                          ? [
                              Colors.transparent,
                              const Color(0xCC1A1A2E),
                            ]
                          : [
                              const Color(0x88000000),
                              const Color(0xDD1A1A2E),
                            ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),

                // Lock overlay for undiscovered
                if (!widget.discovered)
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: widget.discovered
                                ? const Color(0xFF00D68F).withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.discovered
                                  ? const Color(0xFF00D68F)
                                  : Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.discovered
                                    ? Icons.check_circle_rounded
                                    : Icons.lock_rounded,
                                size: 14,
                                color: widget.discovered
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.discovered
                                    ? 'Descubierto'
                                    : 'Bloqueado',
                                style: TextStyle(
                                  color: widget.discovered
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Point name
                      Text(
                        widget.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(
                              alpha: widget.discovered ? 1.0 : 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),

                      if (widget.description != null &&
                          widget.discovered) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return ColorFiltered(
        colorFilter: widget.discovered
            ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
            : const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0, //
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0, 0, 0, 1, 0,
              ]),
        child: Image.network(
          widget.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.discovered
              ? [const Color(0xFF6C63FF), const Color(0xFF3F3D9E)]
              : [const Color(0xFF2A2A3E), const Color(0xFF1A1A2E)],
        ),
      ),
      child: Center(
        child: Icon(
          widget.discovered ? Icons.place_rounded : Icons.help_outline_rounded,
          size: 40,
          color: Colors.white.withValues(alpha: widget.discovered ? 0.4 : 0.15),
        ),
      ),
    );
  }
}
