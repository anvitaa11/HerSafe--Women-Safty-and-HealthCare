import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:women_safety_health_app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {

    await tester.pumpWidget(const HerSafeApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}