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
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
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
