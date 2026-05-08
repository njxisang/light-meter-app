import 'package:flutter/material.dart';

/// 画质质量等级
enum ImageQuality {
  optimal,   // 最优
  excellent,  // 优秀
  good,       // 良好
  fair,       // 一般
  noisy,      // 噪点较多
  veryNoisy,  // 严重噪点
}

extension ImageQualityExtension on ImageQuality {
  String get label {
    switch (this) {
      case ImageQuality.optimal:
        return '最优';
      case ImageQuality.excellent:
        return '优秀';
      case ImageQuality.good:
        return '良好';
      case ImageQuality.fair:
        return '一般';
      case ImageQuality.noisy:
        return '噪点较多';
      case ImageQuality.veryNoisy:
        return '严重噪点';
    }
  }

  String get description {
    switch (this) {
      case ImageQuality.optimal:
        return '画质最佳，细节丰富，色彩纯净';
      case ImageQuality.excellent:
        return '画质优秀，轻微噪点但可接受';
      case ImageQuality.good:
        return '画质良好，噪点不易察觉';
      case ImageQuality.fair:
        return '画质一般，噪点可见但可接受';
      case ImageQuality.noisy:
        return '噪点明显，影响细节表现';
      case ImageQuality.veryNoisy:
        return '噪点严重，画质明显下降';
    }
  }

  Color get color {
    switch (this) {
      case ImageQuality.optimal:
        return const Color(0xFF00E676);
      case ImageQuality.excellent:
        return Colors.green;
      case ImageQuality.good:
        return Colors.lightGreen;
      case ImageQuality.fair:
        return Colors.yellow;
      case ImageQuality.noisy:
        return Colors.orange;
      case ImageQuality.veryNoisy:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ImageQuality.optimal:
        return Icons.stars;
      case ImageQuality.excellent:
        return Icons.check_circle;
      case ImageQuality.good:
        return Icons.thumb_up;
      case ImageQuality.fair:
        return Icons.warning;
      case ImageQuality.noisy:
        return Icons.noise_aware;
      case ImageQuality.veryNoisy:
        return Icons.noise_control_off;
    }
  }

  static ImageQuality fromIso(int iso) {
    if (iso <= 100) return ImageQuality.optimal;
    if (iso <= 200) return ImageQuality.excellent;
    if (iso <= 400) return ImageQuality.good;
    if (iso <= 800) return ImageQuality.fair;
    if (iso <= 1600) return ImageQuality.noisy;
    return ImageQuality.veryNoisy;
  }
}
