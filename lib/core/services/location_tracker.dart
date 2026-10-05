import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;

/// Thin wrapper over Geolocator so the tracker can be tested without a device.
abstract class LocationProvider {
  Future<bool> isServiceEnabled();
  Future<geo.LocationPermission> checkPermission();
  Future<geo.LocationPermission> requestPermission();
  Stream<geo.Position> positionStream(geo.LocationSettings settings);
  Stream<geo.ServiceStatus> serviceStatusStream();
  Future<geo.Position> currentPosition();
}

class GeolocatorProvider implements LocationProvider {
  const GeolocatorProvider();

  @override
  Future<bool> isServiceEnabled() => geo.Geolocator.isLocationServiceEnabled();

  @override
  Future<geo.LocationPermission> checkPermission() =>
      geo.Geolocator.checkPermission();

  @override
  Future<geo.LocationPermission> requestPermission() =>
      geo.Geolocator.requestPermission();

  @override
  Stream<geo.Position> positionStream(geo.LocationSettings settings) =>
      geo.Geolocator.getPositionStream(locationSettings: settings);

  @override
  Stream<geo.ServiceStatus> serviceStatusStream() =>
      geo.Geolocator.getServiceStatusStream();

  @override
  Future<geo.Position> currentPosition() => geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
}

/// Keeps a live position stream running and recovers on its own when the
/// permission is granted late, the GPS is toggled, or the stream dies.
///
/// Before this existed a single early error (e.g. permission not granted yet)
/// left the app without position until it was fully closed and reopened.
class LocationTracker {
  final LocationProvider _provider;
  final geo.LocationSettings _settings;
  final void Function(geo.Position? position) _onPosition;
  final List<Duration> _retryDelays;

  LocationTracker({
    required geo.LocationSettings settings,
    required void Function(geo.Position? position) onPosition,
    LocationProvider provider = const GeolocatorProvider(),
    List<Duration> retryDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 30),
    ],
  })  : _provider = provider,
        _settings = settings,
        _onPosition = onPosition,
        _retryDelays = retryDelays;

  StreamSubscription<geo.Position>? _positionSub;
  StreamSubscription<geo.ServiceStatus>? _statusSub;
  Timer? _retryTimer;
  int _attempt = 0;
  int _generation = 0;
  bool _running = false;
  DateTime? _lastFix;

  bool get isRunning => _running;

  /// True when we have received a position recently.
  bool hasRecentFix({Duration within = const Duration(seconds: 20)}) {
    final last = _lastFix;
    return last != null && DateTime.now().difference(last) <= within;
  }

  /// Starts tracking. Asks for the permission when [requestPermission] is true.
  Future<void> start({bool requestPermission = true}) async {
    _running = true;
    _watchServiceStatus();
    await _connect(requestPermission: requestPermission);
  }

  /// Drops the current subscription and connects again from scratch.
  Future<void> restart({bool requestPermission = true}) async {
    if (!_running) {
      return start(requestPermission: requestPermission);
    }
    await _connect(requestPermission: requestPermission);
  }

  Future<void> stop() async {
    _running = false;
    _generation++;
    _retryTimer?.cancel();
    _retryTimer = null;
    await _positionSub?.cancel();
    _positionSub = null;
    await _statusSub?.cancel();
    _statusSub = null;
    _attempt = 0;
    _lastFix = null;
  }

  void _watchServiceStatus() {
    if (_statusSub != null) return;
    try {
      _statusSub = _provider.serviceStatusStream().listen(
        (status) {
          if (!_running) return;
          if (status == geo.ServiceStatus.enabled) {
            _attempt = 0;
            unawaited(_connect(requestPermission: false));
          } else {
            _dropSubscription();
            _lastFix = null;
            _onPosition(null);
          }
        },
        onError: (_) {},
      );
    } catch (_) {
      // Not supported on every platform (e.g. web); retries still cover it.
    }
  }

  Future<void> _dropSubscription() async {
    final sub = _positionSub;
    _positionSub = null;
    await sub?.cancel();
  }

  Future<void> _connect({required bool requestPermission}) async {
    final generation = ++_generation;
    _retryTimer?.cancel();
    await _dropSubscription();

    try {
      if (!await _provider.isServiceEnabled()) {
        return _fail(generation);
      }

      var permission = await _provider.checkPermission();
      if (permission == geo.LocationPermission.denied && requestPermission) {
        permission = await _provider.requestPermission();
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever ||
          permission == geo.LocationPermission.unableToDetermine) {
        return _fail(generation);
      }
    } catch (_) {
      return _fail(generation);
    }
    if (generation != _generation) return;

    _positionSub = _provider.positionStream(_settings).listen(
      (pos) {
        if (generation != _generation) return;
        _attempt = 0;
        _lastFix = DateTime.now();
        _onPosition(pos);
      },
      onError: (_) {
        if (generation == _generation) _fail(generation);
      },
      onDone: () {
        if (generation == _generation) _fail(generation);
      },
      cancelOnError: true,
    );

    // The stream can take a while to emit its first fix; seed it right away.
    unawaited(_seed(generation));
  }

  Future<void> _seed(int generation) async {
    try {
      final pos = await _provider.currentPosition();
      if (generation != _generation || !_running) return;
      if (_lastFix == null) {
        _lastFix = DateTime.now();
        _onPosition(pos);
      }
    } catch (_) {
      // The stream (or the next retry) will provide the position.
    }
  }

  void _fail(int generation) {
    if (generation != _generation || !_running) return;
    _lastFix = null;
    _onPosition(null);
    _dropSubscription();

    final delay = _retryDelays[_attempt.clamp(0, _retryDelays.length - 1)];
    _attempt++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (_running) unawaited(_connect(requestPermission: false));
    });
  }
}
