import 'package:flutter/material.dart';

/// 应用颜色常量
class AppColors {
  AppColors._();

  // Primary brand color
  static const Color primary = Color(0xFFE94560);
  static const Color primaryLight = Color(0xFFFF6B6B);

  // Background colors
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF16213E);
  static const Color surfaceLight = Color(0xFF1A1A2E);

  // Status colors
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;

  // Quality indicator colors
  static const Color qualityOptimal = Color(0xFF00E676);
  static const Color qualityExcellent = Colors.green;
  static const Color qualityGood = Colors.lightGreen;
  static const Color qualityFair = Colors.yellow;
  static const Color qualityNoisy = Colors.orange;
  static const Color qualityVeryNoisy = Colors.red;

  // Scene colors
  static const Color sceneSunny = Colors.orange;
  static const Color sceneCloudy = Colors.blueGrey;
  static const Color sceneOvercast = Colors.grey;
  static const Color sceneIndoorSunny = Colors.amber;
  static const Color sceneIndoorLight = Colors.yellow;
  static const Color sceneDusk = Colors.deepOrange;
  static const Color sceneDark = Colors.indigo;
}
