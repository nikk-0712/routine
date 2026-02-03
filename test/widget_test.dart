// Basic Flutter widget test for Routine Assistant

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:routine_assistant/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RoutineAssistantApp(),
      ),
    );

    // Verify that home screen is displayed.
    expect(find.text('Routine Assistant'), findsOneWidget);
    expect(find.text('Welcome to Routine Assistant'), findsOneWidget);
  });
}
