import 'package:flutter/material.dart';

/// Application color system following UI_DESIGN.md
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF60A5FA);

  // Semantic colors - light
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF6366F1);

  // Semantic colors - dark
  static const Color successDark = Color(0xFF34D399);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color errorDark = Color(0xFFF87171);
  static const Color infoDark = Color(0xFF818CF8);

  // Background hierarchy - light
  static const Color bgBase = Color(0xFFFFFFFF);
  static const Color bgSurface = Color(0xFFF8FAFC);
  static const Color bgElevated = Color(0xFFF1F5F9);

  // Background hierarchy - dark
  static const Color bgBaseDark = Color(0xFF0F172A);
  static const Color bgSurfaceDark = Color(0xFF1E293B);
  static const Color bgElevatedDark = Color(0xFF334155);

  // HTTP method colors
  static const Color methodGet = Color(0xFF10B981);
  static const Color methodPost = Color(0xFFF59E0B);
  static const Color methodPut = Color(0xFF3B82F6);
  static const Color methodDelete = Color(0xFFEF4444);
  static const Color methodPatch = Color(0xFF8B5CF6);
  static const Color methodHead = Color(0xFF6B7280);
  static const Color methodOptions = Color(0xFF6B7280);

  /// Get color for HTTP method
  static Color forMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return methodGet;
      case 'POST':
        return methodPost;
      case 'PUT':
        return methodPut;
      case 'DELETE':
        return methodDelete;
      case 'PATCH':
        return methodPatch;
      case 'HEAD':
        return methodHead;
      case 'OPTIONS':
        return methodOptions;
      default:
        return methodHead;
    }
  }

  /// Get color for status code
  static Color forStatusCode(int? status) {
    if (status == null) return Colors.grey;
    if (status >= 200 && status < 300) return success;
    if (status >= 300 && status < 400) return warning;
    if (status >= 400 && status < 500) return error;
    if (status >= 500) return error;
    return Colors.grey;
  }
}
