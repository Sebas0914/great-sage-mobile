import 'package:flutter/material.dart';

import 'core/overlay/android_overlay_service.dart';
import 'features/home/home_page.dart';
import 'features/raphael/background_raphael_controller.dart';

class GreatSageMobileApp extends StatefulWidget {
  const GreatSageMobileApp({super.key});
  @override State<GreatSageMobileApp> createState() => _GreatSageMobileAppState();
}

class _GreatSageMobileAppState extends State<GreatSageMobileApp> {
  @override void initState() {
    super.initState();
    AndroidOverlayService.channel.setMethodCallHandler((call) async {
      if (call.method == 'overlayStartListening') { await BackgroundRaphaelController.instance.toggleListening(); return true; }
      return null;
    });
  }

  @override void dispose() { AndroidOverlayService.channel.setMethodCallHandler(null); super.dispose(); }

  @override Widget build(BuildContext context) => MaterialApp(title:'GREAT SAGE Mobile', debugShowCheckedModeBanner:false, theme:ThemeData(brightness:Brightness.dark,useMaterial3:true,scaffoldBackgroundColor:const Color(0xFF070A10),colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF6C63FF),brightness:Brightness.dark)), home:const HomePage());
}