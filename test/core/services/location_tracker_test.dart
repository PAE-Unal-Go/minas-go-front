import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:minasgo_frontend/core/services/location_tracker.dart';

geo.Position _pos(double lat) => geo.Position(
      latitude: lat,
      longitude: -75.57,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    );

class _FakeProvider implements LocationProvider {
  bool serviceEnabled = true;
  geo.LocationPermission permission = geo.LocationPermission.denied;
  geo.LocationPermission afterRequest = geo.LocationPermission.denied;
  int requests = 0;
  int streamsOpened = 0;
  Object? seedError = StateError('no seed');
  geo.Position? seed;

  StreamController<geo.Position>? _stream;
  final status = StreamController<geo.ServiceStatus>.broadcast();

  void emit(geo.Position p) => _stream!.add(p);
  void emitError() => _stream!.addError(StateError('boom'));

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<geo.LocationPermission> checkPermission() async => permission;

  @override
  Future<geo.LocationPermission> requestPermission() async {
    requests++;
    permission = afterRequest;
    return permission;
  }

  @override
  Stream<geo.Position> positionStream(geo.LocationSettings settings) {
    streamsOpened++;
    _stream = StreamController<geo.Position>();
    return _stream!.stream;
  }

  @override
  Stream<geo.ServiceStatus> serviceStatusStream() => status.stream;

  @override
  Future<geo.Position> currentPosition() async {
    if (seed != null) return seed!;
    throw seedError!;
  }
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  late _FakeProvider provider;
  late List<geo.Position?> received;
  late LocationTracker tracker;

  setUp(() {
    provider = _FakeProvider();
    received = [];
    tracker = LocationTracker(
      settings: const geo.LocationSettings(),
      onPosition: received.add,
      provider: provider,
      retryDelays: const [Duration(milliseconds: 15)],
    );
  });

  tearDown(() => tracker.stop());

  test('asks for the permission at start and streams positions once granted',
      () async {
    provider.afterRequest = geo.LocationPermission.whileInUse;

    await tracker.start();
    provider.emit(_pos(6.1));
    await _settle();

    expect(provider.requests, 1);
    expect(provider.streamsOpened, 1);
    expect(received.last?.latitude, 6.1);
  });

  test('recovers on its own when the permission is granted late', () async {
    // First launch: permission not granted and the user has not answered yet.
    await tracker.start(requestPermission: false);
    expect(provider.streamsOpened, 0);
    expect(received.last, isNull);

    // The user grants it (dialog / system settings) while the app is running.
    provider.permission = geo.LocationPermission.whileInUse;
    await _settle();

    expect(provider.streamsOpened, 1);
    provider.emit(_pos(6.2));
    await _settle();
    expect(received.last?.latitude, 6.2);
  });

  test('reconnects when the position stream dies with an error', () async {
    provider.permission = geo.LocationPermission.whileInUse;
    await tracker.start();
    provider.emit(_pos(6.3));
    await _settle();

    provider.emitError();
    await _settle();

    expect(provider.streamsOpened, 2);
    provider.emit(_pos(6.4));
    await _settle();
    expect(received.last?.latitude, 6.4);
  });

  test('reports null while the GPS is off and resumes when it turns on',
      () async {
    provider.permission = geo.LocationPermission.whileInUse;
    provider.serviceEnabled = false;

    await tracker.start();
    expect(received.last, isNull);
    expect(provider.streamsOpened, 0);

    provider.serviceEnabled = true;
    provider.status.add(geo.ServiceStatus.enabled);
    await _settle();

    expect(provider.streamsOpened, greaterThanOrEqualTo(1));
    provider.emit(_pos(6.5));
    await _settle();
    expect(received.last?.latitude, 6.5);
  });

  test('clears the position when the GPS is switched off while running',
      () async {
    provider.permission = geo.LocationPermission.whileInUse;
    await tracker.start();
    provider.emit(_pos(6.6));
    await _settle();
    expect(received.last, isNotNull);

    provider.status.add(geo.ServiceStatus.disabled);
    await _settle();

    expect(received.last, isNull);
    expect(tracker.hasRecentFix(), isFalse);
  });

  test('seeds the first position without waiting for the stream', () async {
    provider.permission = geo.LocationPermission.whileInUse;
    provider.seed = _pos(6.7);

    await tracker.start();
    await _settle();

    expect(received.last?.latitude, 6.7);
    expect(tracker.hasRecentFix(), isTrue);
  });

  test('never asks for the permission again on automatic retries', () async {
    await tracker.start(requestPermission: false);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(provider.requests, 0);
  });

  test('stop() cancels retries and ignores late events', () async {
    provider.permission = geo.LocationPermission.whileInUse;
    await tracker.start();
    await tracker.stop();
    final before = provider.streamsOpened;

    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(provider.streamsOpened, before);
    expect(tracker.isRunning, isFalse);
  });

  test('restart() can be used after stop() to start again', () async {
    provider.permission = geo.LocationPermission.whileInUse;
    await tracker.start();
    await tracker.stop();

    await tracker.restart();
    provider.emit(_pos(6.8));
    await _settle();

    expect(received.last?.latitude, 6.8);
  });
}
