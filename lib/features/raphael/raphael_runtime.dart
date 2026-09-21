import 'package:flutter/foundation.dart';

import '../../core/overlay/android_overlay_service.dart';
import 'raphael_state.dart';

class RaphaelRuntime extends ChangeNotifier {
  RaphaelRuntime._();

  static final RaphaelRuntime instance = RaphaelRuntime._();

  RaphaelMood _mood = RaphaelMood.neutral;
  bool _floating = false;
  bool _busy = false;
  String? _error;

  final AndroidOverlayService _overlay = const AndroidOverlayService();

  RaphaelMood get mood => _mood;
  bool get floating => _floating;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> setMood(RaphaelMood mood) async {
    if (_mood == mood) return;

    _mood = mood;
    _error = null;
    notifyListeners();

    if (!_floating) return;

    try {
      await _overlay.setMood(mood);
    } catch (_) {
      _error = 'No se pudo actualizar el estado de Raphael flotante.';
      notifyListeners();
    }
  }

  Future<bool> refresh() async {
    if (_busy) return _floating;

    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final supported = await _overlay.isSupported();
      if (!supported) {
        _floating = false;
        _error = 'El overlay no está disponible en este dispositivo.';
        return false;
      }

      final permission = await _overlay.hasPermission();
      if (!permission) {
        _floating = false;
        return false;
      }

      // If Android still has the permission, recreate the service when the
      // runtime says Raphael should be floating.
      if (_floating) {
        await _overlay.showRaphael();
        await _overlay.setMood(_mood);
      }

      return _floating;
    } catch (_) {
      _floating = false;
      _error = 'No se pudo comprobar Raphael flotante.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> setFloating(bool value) async {
    if (_busy) return _floating;
    if (_floating == value) {
      if (value) await refresh();
      return _floating;
    }

    _busy = true;
    _error = null;
    notifyListeners();

    try {
      if (value) {
        final supported = await _overlay.isSupported();
        if (!supported) {
          _error = 'El overlay no está disponible en este dispositivo.';
          return false;
        }

        if (!await _overlay.hasPermission()) {
          _error = 'Concede el permiso de superposición en Android.';
          return false;
        }

        await _overlay.showRaphael();
        await _overlay.setMood(_mood);
        _floating = true;
      } else {
        await _overlay.hideRaphael();
        _floating = false;
      }

      return _floating;
    } catch (_) {
      _error = value
          ? 'No se pudo activar Raphael flotante.'
          : 'No se pudo desactivar Raphael flotante.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
