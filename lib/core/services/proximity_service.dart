import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../features/map/domain/entities/punto_de_interes.dart';
import '../../../features/map/data/repositories/map_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service that monitors user proximity to POIs globally.
class ProximityService extends ChangeNotifier {
  static final ProximityService _instance = ProximityService._internal();
  factory ProximityService() => _instance;
  ProximityService._internal();

  final _repo = MapRepositoryImpl();
  StreamSubscription<geo.Position>? _positionSub;
  
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
    
    await refreshPuntos();
    _startLocationStream();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> refreshPuntos() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    
    _allPuntos = await _repo.getPuntosConVisita(userId);
    _checkProximity();
    notifyListeners();
  }

  void _startLocationStream() {
    _positionSub?.cancel();
    _positionSub = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 0, // No filter for max responsiveness
      ),
    ).listen((pos) {
      _currentPosition = pos;
      _checkProximity();
      notifyListeners();
    });
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

      if (dist <= 15.0) { // Match map unlock threshold 
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

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
