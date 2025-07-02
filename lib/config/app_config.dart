import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'MoneyTrail';
  static const String appVersion = '1.0.0';
  static const String developerName = 'Zulfiqar Akram';
  static const String developerEmail = 'zulfiqar1152@hotmail.com';
  static const String whatsappNumber = '+923448127902';
  static const String appDescription = 'Personal expense tracking app with local storage';
  
  // App Logo
  static const String appLogo = 'assets/app-logo.png';
  
  // App Colors
  static const Color primaryColor = Color(0xFF149446); // Green
  static const Color secondaryColor = Color(0xFF202127); // Dark Gray
  
  // Color Scheme
  static ColorScheme get lightColorScheme => ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
  );
  
  static ColorScheme get darkColorScheme => ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
  );
} 