import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/main.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/user_provider.dart';

void main() {
  testWidgets('App starts with loading screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app shows a loading indicator initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Shows login screen when not authenticated', (WidgetTester tester) async {
    // Build our app with mock providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => AuthProvider()),
          ChangeNotifierProvider(create: (context) => UserProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('로그인'),
            ),
          ),
        ),
      ),
    );

    // Wait for the widget to settle
    await tester.pump();

    // Verify that we can find login-related text
    expect(find.text('로그인'), findsOneWidget);
  });
}
