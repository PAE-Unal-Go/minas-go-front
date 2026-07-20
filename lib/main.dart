import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'core/theme/app_design_system.dart';
import 'features/home/presentation/screens/home_shell_view.dart';
import 'features/login/presentation/screens/login_view.dart';
import 'core/services/proximity_service.dart';
import 'features/map/domain/entities/punto_de_interes.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

const _mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On web, the token is set via mapboxgl.accessToken in index.html.
  // Calling this on web crashes DDC because mapbox_maps_flutter uses
  // bool.fromEnvironment non-const internally.
  if (!kIsWeb) {
    MapboxOptions.setAccessToken(_mapboxToken);
  }


  // Validate that variables are loaded from the environment.
  // Keep silent in production builds.

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        // Initialize proximity service only if not already done
        ProximityService().init();
        
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeShellView()),
          (_) => false,
        );
      } else if (event == AuthChangeEvent.signedOut) {
        ProximityService().dispose(); // Stop monitoring on logout
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (_) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if there is an existing session on startup
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (child != null) child,
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _ProximityNotificationOverlay(),
            ),
          ],
        );
      },
      home: session != null ? const _HomeWrapper() : const LoginView(),
    );
  }
}

class _HomeWrapper extends StatefulWidget {
  const _HomeWrapper();

  @override
  State<_HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<_HomeWrapper> {
  @override
  void initState() {
    super.initState();
    ProximityService().init();
  }

  @override
  Widget build(BuildContext context) => const HomeShellView();
}

class _ProximityNotificationOverlay extends StatefulWidget {
  const _ProximityNotificationOverlay();

  @override
  State<_ProximityNotificationOverlay> createState() =>
      _ProximityNotificationOverlayState();
}

class _ProximityNotificationOverlayState
    extends State<_ProximityNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final AudioPlayer _audioPlayer;

  PuntoDeInteres? _nearPOI;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _audioPlayer = AudioPlayer();
    ProximityService().addListener(_onProximityChange);
  }

  @override
  void dispose() {
    ProximityService().removeListener(_onProximityChange);
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onProximityChange() {
    final near = ProximityService().nearPOI;

    // Only react when the nearby POI changes identity
    if (near?.id == _nearPOI?.id) return;

    _nearPOI = near;

    if (near != null) {
      if (!_isVisible) setState(() => _isVisible = true);
      _controller.forward(from: 0);
      _audioPlayer
          .play(AssetSource('sounds/princess.mp3'))
          .catchError((_) {});
    } else {
      _controller.reverse().then((_) {
        if (mounted) setState(() => _isVisible = false);
      });
    }
  }

  void _dismiss() => _controller.reverse().then((_) {
        if (mounted) setState(() => _isVisible = false);
      });

  void _navigateToMap() {
    _dismiss();
    HomeShellView.onNavigateToMap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_isVisible,
      child: SlideTransition(
        position: _slideAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: GestureDetector(
              onTap: _navigateToMap,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(16),
                color: AppColors.secondaryMain,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Colors.white, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡LUGAR CERCANO!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _nearPOI?.nombre ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Tap-hint arrow
                      const Icon(Icons.explore_rounded,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: _dismiss,
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

