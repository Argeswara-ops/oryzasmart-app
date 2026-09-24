import 'package:flutter/material.dart';

enum NurseryStatus { normal, warning, critical }

extension NurseryStatusText on NurseryStatus {
  String get label {
    switch (this) {
      case NurseryStatus.normal:
        return 'NORMAL';
      case NurseryStatus.warning:
        return 'WARNING';
      case NurseryStatus.critical:
        return 'CRITICAL';
    }
  }

  Color color(ColorScheme scheme) {
    switch (this) {
      case NurseryStatus.normal:
        return scheme.primary;
      case NurseryStatus.warning:
        return const Color(0xFFE0A100);
      case NurseryStatus.critical:
        return scheme.error;
    }
  }
}
