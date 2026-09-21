import 'package:flutter/foundation.dart';

enum RaphaelMood { neutral, listening, thinking, speaking, happy }

class RaphaelState extends ChangeNotifier {
  RaphaelMood _mood = RaphaelMood.neutral;
  bool _isFloating = false;

  RaphaelMood get mood => _mood;
  bool get isFloating => _isFloating;

  void setMood(RaphaelMood mood) {
    if (_mood == mood) return;
    _mood = mood;
    notifyListeners();
  }

  void setFloating(bool value) {
    if (_isFloating == value) return;
    _isFloating = value;
    notifyListeners();
  }
}
