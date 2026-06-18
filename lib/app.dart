import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/mobile_router.dart';

class ApiTesterApp extends StatelessWidget {
  const ApiTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'API Tester',
        theme: AppTheme.lightTheme,
        routerConfig: mobileRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
