import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// MENGGUNAKAN RELATIVE IMPORT (Pasti terbaca!)
import 'package:uang_ku/main.dart';

void main() {
  testWidgets('App run test', (WidgetTester tester) async {
    // WAJIB dibungkus ProviderScope karena kita menggunakan Riverpod
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
