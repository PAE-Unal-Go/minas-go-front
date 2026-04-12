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
          children: [
            if (child != null) child,
            const _ProximityNotificationOverlay(),
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
  State<_ProximityNotificationOverlay> createState() => _ProximityNotificationOverlayState();
}

class _ProximityNotificationOverlayState extends State<_ProximityNotificationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final AudioPlayer _audioPlayer;
  PuntoDeInteres? _lastNearPOI;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    
    _audioPlayer = AudioPlayer();

    ProximityService().addListener(_onProximityChange);
  }

  void _onProximityChange() {
    final near = ProximityService().nearPOI;
    if (near != _lastNearPOI) {
      if (near != null) {
        _controller.forward();
        _audioPlayer.play(AssetSource('sounds/princess.mp3')).catchError((_) {});
      } else {
        _controller.reverse();
      }
      _lastNearPOI = near;
    }
  }

  @override
  void dispose() {
    ProximityService().removeListener(_onProximityChange);
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: AppColors.secondaryMain,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                   const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text(
                           '¡LUGAR CERCANO!',
                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                         ),
                         Text(
                           _lastNearPOI?.nombre ?? '',
                           style: const TextStyle(color: Colors.white, fontSize: 15),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                       ],
                     ),
                   ),
                   IconButton(
                     onPressed: () => _controller.reverse(),
                     icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

