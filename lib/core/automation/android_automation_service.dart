import 'dart:convert';
import 'package:flutter/services.dart';

class AndroidAutomationService {
  const AndroidAutomationService();
  static const channel = MethodChannel('great_sage_mobile/overlay');

  Future<bool> isEnabled() async =>
      await channel.invokeMethod<bool>('automationEnabled') ?? false;

  Future<void> openSettings() => channel.invokeMethod<void>('openAccessibilitySettings');

  Future<bool> executePlan(String json) async =>
      await channel.invokeMethod<bool>('executeAutomation', jsonDecode(json)) ?? false;
}
