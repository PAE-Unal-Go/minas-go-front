import 'package:flutter/foundation.dart';

/// Campus currently selected by the user, shared by home and map.
/// `null` means "all campuses".
class CampusSelection extends ChangeNotifier {
  CampusSelection._();
  static final CampusSelection instance = CampusSelection._();

  /// For tests.
  @visibleForTesting
  factory CampusSelection.test() = CampusSelection._;

  String? _selected;
  String? get selected => _selected;

  void select(String? campus) {
    if (campus == _selected) return;
    _selected = campus;
    notifyListeners();
  }

  void clear() => select(null);
}
