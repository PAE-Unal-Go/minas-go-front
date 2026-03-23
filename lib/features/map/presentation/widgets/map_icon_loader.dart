import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

const Map<String, String> categoryIconAssets = {
  'arte_cultura':        'assets/images/map_points/arteIcon.png',
  'deporte_salud':       'assets/images/map_points/deporteIcon.png',
  'museos_laboratorios': 'assets/images/map_points/labsIcon.png',
  'academico':           'assets/images/map_points/academiaIcon.png',
  'medio_ambiente':      'assets/images/map_points/naturalezaIcon.png',
  'servicios':           'assets/images/map_points/serviciosIcon.png',
};

const int _iconSize = 100;

final Map<String, Uint8List> _cachedRgba = {};

Future<void> preloadIconBytes() async {
  if (_cachedRgba.isNotEmpty) return;
  for (final entry in categoryIconAssets.entries) {
    try {
      _cachedRgba[entry.key] = await _loadRawRgba(entry.value);
      debugPrint('[MapIcons] 📦 Preloaded ${entry.key}');
    } catch (e) {
      debugPrint('[MapIcons] ❌ Preload failed for ${entry.key}: $e');
    }
  }
}

/// Phase 2 – register pre-decoded buffers into the Mapbox style.
/// All Mapbox calls happen back-to-back with no async gaps between them,
/// minimising the window for a style-reload race condition.
Future<void> registerMapIcons(MapboxMap mapboxMap) async {
  if (_cachedRgba.isEmpty) await preloadIconBytes();

  int registered = 0;
  for (final entry in _cachedRgba.entries) {
    try {
      await mapboxMap.style.addStyleImage(
        'icon-${entry.key}',
        1.0,
        MbxImage(width: _iconSize, height: _iconSize, data: entry.value),
        false, [], [], null,
      );
      registered++;
      debugPrint('[MapIcons] ✅ icon-${entry.key}');
    } catch (e) {
      debugPrint('[MapIcons] ❌ register icon-${entry.key}: $e');
    }
  }
  debugPrint('[MapIcons] Registered $registered/${_cachedRgba.length}');
}

// ─────────────────────────────── internal ────────────────────────────────────

Future<Uint8List> _loadRawRgba(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: _iconSize,
    targetHeight: _iconSize,
  );
  final frame = await codec.getNextFrame();
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImage(frame.image, ui.Offset.zero, ui.Paint());
  final img = await recorder.endRecording().toImage(_iconSize, _iconSize);
  final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  return bd!.buffer.asUint8List();
}
