import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../../challenges/presentation/screens/challenges_view.dart';
import '../../../facts/fact_unlock_notifier.dart';
import '../../../facts/domain/entities/university_fact.dart';
import '../../../facts/presentation/screens/facts_view.dart';
import '../../../facts/presentation/widgets/fact_unlock_banner.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'home_view.dart';

class HomeShellView extends StatefulWidget {
  const HomeShellView({super.key});

  /// Called externally (e.g. from the proximity notification) to switch to
  /// the map tab, respecting location-permission checks.
  static VoidCallback? onNavigateToMap;

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  late final _homeNavigatorObserver = _HomeNavigatorObserver(
    onDepthChanged: _onHomeDepthChanged,
  );
  int _currentIndex = 0;
  int _challengesSeed = 0;
  bool _isInHomeDetail = false;
  UniversityFact? _bannerFact;
  Timer? _bannerTimer;

  void _onHomeDepthChanged(int depth) {
    if (!mounted) return;
    final inDetail = depth > 1;
    if (_isInHomeDetail != inDetail) {
      setState(() => _isInHomeDetail = inDetail);
    }
  }

  @override
  void initState() {
    super.initState();
    HomeShellView.onNavigateToMap = () => _onTabSelected(1);
    FactUnlockNotifier.instance.addListener(_onFactUnlocked);
  }

  @override
  void dispose() {
    HomeShellView.onNavigateToMap = null;
    FactUnlockNotifier.instance.removeListener(_onFactUnlocked);
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _onFactUnlocked() {
    final fact = FactUnlockNotifier.instance.pendingFact;
    if (fact == null || !mounted) return;
    FactUnlockNotifier.instance.consume();
    _bannerTimer?.cancel();
    setState(() => _bannerFact = fact);
    _bannerTimer = Timer(const Duration(seconds: 6), _dismissBanner);
  }

  void _dismissBanner() {
    if (mounted) setState(() => _bannerFact = null);
  }

  Future<void> _onTabSelected(int index) async {
    if (_currentIndex == index) {
      if (index == 0) {
        _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
      return;
    }

    if (index == 1) {
      final canAccessLocation = await _canAccessLocation();
      if (!canAccessLocation) {
        if (!mounted) return;
        await _showLocationPermissionDialog();
        return;
      }
    }

    if (index == 2) {
      setState(() {
        _challengesSeed++;
      });
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final selectedNavIndex =
        (_currentIndex == 0 && _isInHomeDetail) ? -1 : _currentIndex;

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navBarHeight = 68.0 + (bottomInset > 14 ? bottomInset - 14 : 4.0);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              Navigator(
                key: _homeNavigatorKey,
                observers: [_homeNavigatorObserver],
                onGenerateRoute: (_) {
                  return MaterialPageRoute(
                    builder: (_) => const HomeView(),
                  );
                },
              ),
              const MapScreen(),
              ChallengesView(
                key: ValueKey(_challengesSeed),
                onAnswerCompleted: () => _onTabSelected(0),
              ),
              const FactsView(),
            ],
          ),
          if (_bannerFact != null)
            Positioned(
              bottom: navBarHeight + 12,
              left: 0,
              right: 0,
              child: FactUnlockBanner(
                key: ValueKey(_bannerFact!.id),
                fact: _bannerFact!,
                onTap: () {
                  _dismissBanner();
                  _onTabSelected(3);
                },
                onDismiss: _dismissBanner,
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: selectedNavIndex,
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

class _HomeNavigatorObserver extends NavigatorObserver {
  final ValueChanged<int> onDepthChanged;
  int _depth = 1;

  _HomeNavigatorObserver({required this.onDepthChanged});

  void _notifyDepth() {
    onDepthChanged(_depth);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute == null) {
      _depth = 1;
    } else {
      _depth++;
    }
    _notifyDepth();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _depth = (_depth - 1).clamp(0, 9999);
    _notifyDepth();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _depth = (_depth - 1).clamp(0, 9999);
    _notifyDepth();
  }
}
