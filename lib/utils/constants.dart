import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF667EEA);
  static const Color secondary = Color(0xFF764BA2);
  static const Color accent = Color(0xFFFF6B6B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF5F7FA), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static Color getLightGrey() => Colors.grey.shade100;
  static Color getGreyText() => Colors.grey.shade600;
}

class AppPadding {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppBorderRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 15;
  static const double xl = 20;
}

class AppShadows {
  static final BoxShadow small = BoxShadow(
    color: Colors.grey.shade200,
    blurRadius: 4,
    offset: const Offset(0, 2),
  );

  static final BoxShadow medium = BoxShadow(
    color: Colors.grey.shade300,
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  static final BoxShadow large = BoxShadow(
    color: Colors.grey.shade400,
    blurRadius: 15,
    offset: const Offset(0, 8),
  );
}

class AppDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration long = Duration(milliseconds: 800);
}
