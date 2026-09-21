import 'package:flutter/foundation.dart';

import '../../core/overlay/android_overlay_service.dart';
import 'raphael_state.dart';

class RaphaelRuntime extends ChangeNotifier {
  RaphaelRuntime._();
  static final RaphaelRuntime instance = RaphaelRuntime._();

  RaphaelMood _mood = RaphaelMood.neutral;
  bool _floating = false;
  final AndroidOverlayService _overlay = const AndroidOverlayService();

  RaphaelMood get mood => _mood;
  bool get floating => _floating;

  Future<void> setMood(RaphaelMood mood) async {
    if (_mood == mood) return;
    _mood = mood;
    notifyListeners();
    if (_floating) {
      try {
        await _overlay.setMood(mood);
      } catch (_) {}
    }
  }

  Future<void> setFloating(bool value) async {
    if (_floating == value) return;
    _floating = value;
    notifyListeners();
    if (value) {
      try {
        await _overlay.showRaphael();
        await _overlay.setMood(_mood);
      } catch (_) {}
    } else {
      try {
        await _overlay.hideRaphael();
      } catch (_) {}
    }
  }
}
