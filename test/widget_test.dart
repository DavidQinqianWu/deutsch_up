// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_deutsch_up/main.dart';
import 'package:flutter_deutsch_up/providers/learning_provider.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LearningProvider(),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return const SplashScreen();
            },
          ),
        ),
      ),
    );

    expect(find.text('Deutsch Up'), findsOneWidget);
  });
}
