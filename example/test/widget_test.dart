import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a destination moves the page', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Home 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.book_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Books 1'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
  });
}
