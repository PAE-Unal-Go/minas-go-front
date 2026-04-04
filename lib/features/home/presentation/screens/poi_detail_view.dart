import 'package:flutter/material.dart';

class PoiDetailView extends StatelessWidget {
  final String categoryName;
  final String pointName;
  final String pointDescription;
  final String? imageUrl;

  const PoiDetailView({
    super.key,
    required this.categoryName,
    required this.pointName,
    required this.pointDescription,
    this.imageUrl,
  });

  static const Color _neutralBackground = Color(0xFFE7E8EE);
  static const Color _neutralSurface = Color(0xFFF7F8FB);
  static const Color _neutralBorder = Color(0xFF091436);
  static const Color _neutralTextPrimary = Color(0xFF091436);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neutralBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: _neutralTextPrimary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _neutralSurface,
                      border: Border.all(color: _neutralBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: _buildImage(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryName,
                                style: const TextStyle(
                                  color: Color(0xFF6A7587),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pointName,
                                style: const TextStyle(
                                  color: _neutralTextPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                pointDescription,
                                style: const TextStyle(
                                  color: _neutralTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('http')) {
        return Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }

      return Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCED1DB), Color(0xFFE7E8EE)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF6A7587),
          size: 34,
        ),
      ),
    );
  }
}
