import 'package:flutter/foundation.dart';
import 'domain/entities/university_fact.dart';

/// Singleton ChangeNotifier that broadcasts newly unlocked university facts
/// to any listener in the widget tree (primarily HomeShellView).
class FactUnlockNotifier extends ChangeNotifier {
  FactUnlockNotifier._();
  static final FactUnlockNotifier instance = FactUnlockNotifier._();

  UniversityFact? _fact;
  UniversityFact? get pendingFact => _fact;

  void notify(UniversityFact fact) {
    _fact = fact;
    notifyListeners();
  }

  void consume() {
    _fact = null;
  }
}
