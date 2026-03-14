import 'package:flutter/material.dart';
import 'package:minasgo_frontend/features/map/presentation/screens/map_screen.dart';

class ExploreFab extends StatelessWidget {
  final VoidCallback? onTap;

  const ExploreFab({super.key, this.onTap});

  static const Color _secondaryMain = Color(0xFF37C8BE);
  static const Color _secondaryDark = Color(0xFF25B7AB);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MapScreen()),
            );
          },
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_secondaryMain, _secondaryDark],
          ),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: _secondaryDark.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.my_location_rounded, color: Colors.white, size: 24),
            SizedBox(height: 2),
            Text(
              'Explorar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
