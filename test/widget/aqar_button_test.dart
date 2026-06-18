import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar/core/widgets/aqar_button.dart';

void main() {
  testWidgets('AqarButton displays text and responds to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AqarButton(
            text: 'Sign In',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);
    await tester.tap(find.text('Sign In'));
    expect(tapped, true);
  });

  testWidgets('AqarButton shows loading indicator when isLoading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AqarButton(
            text: 'Sign In',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
  });

  testWidgets('AqarButton shows suffix icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AqarButton(
            text: 'Continue',
            suffix: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });
}
