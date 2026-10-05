import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PoiImageGallery extends StatefulWidget {
  final List<String> imagesUrls;
  final double? height;
  final BorderRadius borderRadius;
  final bool locked;
  final bool showIndicators;
  final bool enableCarousel;
  final Color? lockedOverlayColor;
  final double lockedGrayOpacity;

  const PoiImageGallery({
    super.key,
    required this.imagesUrls,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.locked = false,
    this.showIndicators = true,
    this.enableCarousel = true,
    this.lockedOverlayColor,
    this.lockedGrayOpacity = 0.78,
  });

  @override
  State<PoiImageGallery> createState() => _PoiImageGalleryState();
}

class _PoiImageGalleryState extends State<PoiImageGallery> {
  int _currentIndex = 0;

  List<String> get _images => widget.imagesUrls
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final images = _images;

    Widget content;
    if (images.isEmpty) {
      content = _placeholder();
    } else if (images.length == 1 || !widget.enableCarousel) {
      content = _imageFor(images.first);
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() => _currentIndex = index);
            },
            itemBuilder: (_, index) => _imageFor(images[index]),
          ),
          if (widget.showIndicators)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: index == _currentIndex ? 18 : 6,
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: widget.height == null
          ? Stack(
              fit: StackFit.expand,
              children: [
                content,
                if (widget.locked)
                  ColoredBox(
                    color: (widget.lockedOverlayColor ?? Colors.black)
                        .withValues(alpha: widget.lockedGrayOpacity),
                  ),
              ],
            )
          : SizedBox(
              height: widget.height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  content,
                  if (widget.locked)
                    ColoredBox(
                      color: (widget.lockedOverlayColor ?? Colors.black)
                          .withValues(alpha: widget.lockedGrayOpacity),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _imageFor(String url) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => const _ShimmerBox(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }

    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCED1DB), Color(0xFFE7E8EE)],
        ),
      ),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF6A7587)),
      ),
    );
  }
}

/// Shimmer placeholder shown while a network image loads.
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFFE0E3EA),
              Color(0xFFF4F6FA),
              Color(0xFFE0E3EA),
            ],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
