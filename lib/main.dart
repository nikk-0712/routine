import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: RoutineAssistantApp(),
    ),
  );
}

class RoutineAssistantApp extends StatelessWidget {
  const RoutineAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Routine Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF540CC3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF020004),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF34195B),
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF34195B),
          indicatorColor: const Color(0xFF540CC3),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: Color(0xFFA7A1AB));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Colors.white, fontSize: 12);
            }
            return const TextStyle(color: Color(0xFFA7A1AB), fontSize: 12);
          }),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
