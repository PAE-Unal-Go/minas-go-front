import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

const Map<String, String> categoryIconAssets = {
  'arte_cultura': 'assets/images/map_points/arteIcon.png',
  'deporte_salud': 'assets/images/map_points/deporteIcon.png',
  'museos_laboratorios': 'assets/images/map_points/labsIcon.png',
  'academico': 'assets/images/map_points/academiaIcon.png',
  'medio_ambiente': 'assets/images/map_points/naturalezaIcon.png',
  'servicios': 'assets/images/map_points/serviciosIcon.png',
  'default': 'assets/images/marker.png',
};

const int _iconSize = 100;

final Map<String, Uint8List> _cachedPng = {};
final Map<String, Uint8List> _cachedGrayPng = {};

Future<void> preloadIconBytes() async {
  _cachedPng.clear();
  _cachedGrayPng.clear();
  for (final entry in categoryIconAssets.entries) {
    try {
      _cachedPng[entry.key] = await _loadResizedPng(entry.value);
      _cachedGrayPng[entry.key] = await _loadResizedPng(
        entry.value,
        grayscale: true,
      );
    } catch (_) {
    }
  }
}

/// Mapbox's addStyleImage expects encoded image bytes (PNG/JPG), not raw RGBA.
Future<void> registerMapIcons(MapboxMap mapboxMap) async {
  if (_cachedPng.isEmpty || _cachedGrayPng.isEmpty) await preloadIconBytes();

  for (final entry in _cachedPng.entries) {
    try {
      await mapboxMap.style.addStyleImage(
        'icon-${entry.key}',
        1.0,
        MbxImage(width: _iconSize, height: _iconSize, data: entry.value),
        false,
        [],
        [],
        null,
      );

      final gray = _cachedGrayPng[entry.key];
      if (gray != null) {
        await mapboxMap.style.addStyleImage(
          'icon-${entry.key}-gray',
          1.0,
          MbxImage(width: _iconSize, height: _iconSize, data: gray),
          false,
          [],
          [],
          null,
        );
      }
    } catch (_) {
    }
  }
}

// ─────────────────────────────── internal ────────────────────────────────────

Future<Uint8List> _loadResizedPng(String assetPath,
    {bool grayscale = false}) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: _iconSize,
    targetHeight: _iconSize,
  );
  final frame = await codec.getNextFrame();
  ui.Image output = frame.image;

  if (grayscale) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final grayPaint = ui.Paint()
      ..colorFilter = const ui.ColorFilter.matrix([
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    canvas.drawImage(frame.image, ui.Offset.zero, grayPaint);

    // Dark overlay to ensure even white areas look "locked".
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, _iconSize.toDouble(), _iconSize.toDouble()),
      ui.Paint()
        ..color = const ui.Color(0x66000000)
        ..blendMode = ui.BlendMode.srcATop,
    );

    output = await recorder.endRecording().toImage(_iconSize, _iconSize);
  }

  final bd = await output.toByteData(format: ui.ImageByteFormat.png);
  return bd!.buffer.asUint8List();
}
