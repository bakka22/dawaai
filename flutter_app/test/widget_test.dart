import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dawaai_app/main.dart';

void main() {
  testWidgets('App loads and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DawaaiApp()));
    expect(find.text('دواي'), findsOneWidget);
  });
}
