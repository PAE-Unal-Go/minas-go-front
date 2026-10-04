import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../features/map/domain/entities/punto_de_interes.dart';
import 'location_tracker.dart';
import '../../../features/map/data/repositories/map_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service that monitors user proximity to POIs globally.
class ProximityService extends ChangeNotifier {
  static final ProximityService _instance = ProximityService._internal();
  factory ProximityService() => _instance;
  ProximityService._internal();

  final _repo = MapRepositoryImpl();
  late final LocationTracker _tracker = LocationTracker(
    settings: _buildLocationSettings(),
    onPosition: _onPosition,
  );
  Timer? _refreshRetry;
  int _refreshAttempts = 0;

  List<PuntoDeInteres> _allPuntos = [];
  geo.Position? _currentPosition;
  PuntoDeInteres? _nearPOI;

  final Set<int> _notifiedIds = {};
  bool _isInitialized = false;

  geo.Position? get currentPosition => _currentPosition;
  PuntoDeInteres? get nearPOI => _nearPOI;
  List<PuntoDeInteres> get allPuntos => _allPuntos;
  bool get isInitialized => _isInitialized;

  /// Loads POIs and starts the location stream.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Location must not depend on the POIs request: a flaky network at startup
    // used to leave the app without position until it was reopened.
    unawaited(_tracker.start());
    await _loadPuntosWithRetry();
    notifyListeners();
  }

  Future<void> _loadPuntosWithRetry() async {
    try {
      await refreshPuntos();
      _refreshAttempts = 0;
    } catch (_) {
      if (!_isInitialized || _refreshAttempts >= 5) return;
      _refreshAttempts++;
      _refreshRetry?.cancel();
      _refreshRetry = Timer(
        Duration(seconds: 3 * _refreshAttempts),
        _loadPuntosWithRetry,
      );
    }
  }

  Future<void> refreshPuntos() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _allPuntos = await _repo.getPuntosConVisita(userId);
    _checkProximity();
    notifyListeners();
  }

  void _onPosition(geo.Position? pos) {
    _currentPosition = pos;
    if (pos == null) {
      _nearPOI = null;
    } else {
      _checkProximity();
    }
    notifyListeners();
  }

  /// Call when the app returns to the foreground: the user may have granted
  /// the permission or toggled the GPS from the system settings meanwhile.
  Future<void> onAppResumed() async {
    if (!_isInitialized) return;
    if (_currentPosition == null || !_tracker.hasRecentFix()) {
      await _tracker.restart(requestPermission: false);
    }
  }

  /// Forces a fresh connection (asking for permission when needed) and returns
  /// the current position, or null when it is not available.
  Future<geo.Position?> restartLocation() async {
    await _tracker.restart(requestPermission: true);
    return _currentPosition;
  }

  /// Stops tracking and clears state, e.g. on logout. The singleton stays
  /// usable so `init()` works again on the next login.
  Future<void> stop() async {
    _isInitialized = false;
    _refreshRetry?.cancel();
    await _tracker.stop();
    _allPuntos = [];
    _currentPosition = null;
    _nearPOI = null;
    notifyListeners();
  }

  geo.LocationSettings _buildLocationSettings() {
    const accuracy = geo.LocationAccuracy.bestForNavigation;
    const distanceFilter = 0;

    if (kIsWeb) {
      return const geo.LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return geo.AndroidSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          intervalDuration: const Duration(seconds: 1),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return geo.AppleSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          activityType: geo.ActivityType.otherNavigation,
          pauseLocationUpdatesAutomatically: false,
        );
      default:
        return const geo.LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        );
    }
  }

  void _checkProximity() {
    if (_currentPosition == null || _allPuntos.isEmpty) return;

    PuntoDeInteres? bestNear;
    double minDistance = double.infinity;

    for (final p in _allPuntos) {
      if (p.visitado) continue;

      final dist = geo.Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        p.latitud,
        p.longitud,
      );

      if (dist <= 8.0) {
        // 8m: matches POI unlock proximity
        if (dist < minDistance) {
          minDistance = dist;
          bestNear = p;
        }
      }
    }

    if (bestNear != _nearPOI) {
      _nearPOI = bestNear;
    }
  }

  void markAsNotified(int id) {
    _notifiedIds.add(id);
  }
}
