import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glassy_bottom_nav/glassy_bottom_nav.dart';

void main() {
  testWidgets('renders one icon and label per item', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: GlassyBottomNav(
            items: const [
              GlassyBottomNavItem(icon: Icon(Icons.home), label: 'Home'),
              GlassyBottomNavItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
