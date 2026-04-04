import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../../map/presentation/screens/map_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'home_view.dart';

class HomeShellView extends StatefulWidget {
  const HomeShellView({super.key});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onTabSelected(int index) async {
    if (_currentIndex == index) return;

    if (index == 1) {
      final canAccessLocation = await _canAccessLocation();
      if (!canAccessLocation) {
        if (!mounted) return;
        await _showLocationPermissionDialog();
        return;
      }
    }

    setState(() => _currentIndex = index);
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
          }
        },
        children: const [
          HomeView(),
          MapScreen(),
          _ChallengesPlaceholderView(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }

  Future<bool> _canAccessLocation() async {
    final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await geo.Geolocator.checkPermission();
    return permission == geo.LocationPermission.whileInUse ||
        permission == geo.LocationPermission.always;
  }

  Future<void> _showLocationPermissionDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permiso requerido'),
          content: const Text(
            'Debes otorgar permisos de ubicación a la aplicación para poder acceder al mapa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await geo.Geolocator.openAppSettings();
              },
              child: const Text('Ir a ajustes'),
            ),
          ],
        );
      },
    );
  }
}

class _ChallengesPlaceholderView extends StatelessWidget {
  const _ChallengesPlaceholderView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retos')),
      body: const Center(
        child: Text('Próximamente'),
      ),
    );
  }
}
