import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final int? statusCode;
  final String? statusText;

  const StatusBadge({super.key, this.statusCode, this.statusText});

  @override
  Widget build(BuildContext context) {
    final code = statusCode ?? 0;
    final text = statusText ?? _defaultText(code);
    final color = AppColors.forStatusCode(code);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$code $text',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          color: color,
        ),
      ),
    );
  }

  String _defaultText(int code) {
    switch (code) {
      case 200: return 'OK';
      case 201: return 'Created';
      case 204: return 'No Content';
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 500: return 'Server Error';
      default: return '';
    }
  }
}
