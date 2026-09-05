import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Global route observer — subscribe pages to it so they reload on pop-back.
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() {
  runApp(const ProviderScope(child: EqubApp()));
}

class EqubApp extends StatelessWidget {
  const EqubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equb',
      theme: AppTheme.light,
      initialRoute: '/splash',
      onGenerateRoute: onGenerateAppRoute,
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
    );
  }
}
