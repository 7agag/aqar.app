import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar/core/widgets/aqar_text_field.dart';

void main() {
  testWidgets('AqarTextField displays label and hint', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AqarTextField(
            label: 'Email Address',
            hint: 'Enter your email',
            prefixIcon: const Icon(Icons.email_outlined),
            controller: controller,
          ),
        ),
      ),
    );

    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);

    controller.dispose();
  });

  testWidgets('AqarTextField accepts input', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AqarTextField(
            label: 'Name',
            hint: 'Enter name',
            prefixIcon: const Icon(Icons.person),
            controller: controller,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'John Doe');
    expect(controller.text, 'John Doe');

    controller.dispose();
  });

  testWidgets('AqarTextField validates input', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AqarTextField(
              label: 'Email',
              hint: 'Enter email',
              prefixIcon: const Icon(Icons.email),
              controller: controller,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
          ),
        ),
      ),
    );

    formKey.currentState?.validate();
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);

    controller.dispose();
  });
}
