import 'package:flutter/services.dart';

import '../../features/raphael/raphael_state.dart';
import 'overlay_service.dart';

class AndroidOverlayService implements OverlayService {
  const AndroidOverlayService();

  static const _channel = MethodChannel('great_sage_mobile/overlay');

  @override
  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> showRaphael() async {
    await _channel.invokeMethod<void>('show');
  }

  @override
  Future<void> hideRaphael() async {
    await _channel.invokeMethod<void>('hide');
  }

  Future<void> setMood(RaphaelMood mood) async {
    await _channel.invokeMethod<void>('setMood', mood.name);
  }
}
