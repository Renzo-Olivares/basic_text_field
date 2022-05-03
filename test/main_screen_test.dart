// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deltaclientguide/basic_text_input_client.dart';
import 'package:deltaclientguide/main.dart';

void main() {
  testWidgets('Default main page shows all components',
          (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());

        // Elements on Style ToggleButton Toolbar.
        expect(find.widgetWithIcon(ToggleButtons, Icons.format_bold),
            findsOneWidget);
        expect(find.widgetWithIcon(ToggleButtons, Icons.format_italic), findsOneWidget);
        expect(
            find.widgetWithIcon(ToggleButtons, Icons.format_underline), findsOneWidget);

        // Elements on the main screen
        // Delta labels.
        expect(find.byTooltip('The text that is being inserted or deleted'), findsOneWidget);
        expect(
            find.widgetWithText(Tooltip, "Delta Type"), findsOneWidget);
        expect(find.widgetWithText(Tooltip, "Delta Text"), findsOneWidget);
        expect(
            find.widgetWithText(Tooltip, "Delta Offset"),
            findsOneWidget);
        expect(
            find.widgetWithText(Tooltip, "New Selection"), findsOneWidget);
        expect(find.widgetWithText(Tooltip, "New Composing"), findsOneWidget);

        // Selection delta is generated and delta history is visible.
        await tester.tap(find.byType(BasicTextInputClient));
        await tester.pumpAndSettle();
        expect(
            find.widgetWithText(TextEditingDeltaView, "NonTextUpdate"), findsOneWidget);
        // // FABs
        // expect(
        //     find.widgetWithIcon(FloatingActionButton, Icons.add),
        //     findsNWidgets(4));
        // expect(find.widgetWithText(FloatingActionButton, "Create"),
        //     findsOneWidget);
        //
        // // Cards
        // expect(find.widgetWithText(Card, "Elevated"), findsOneWidget);
        // expect(find.widgetWithText(Card, "Filled"), findsOneWidget);
        // expect(find.widgetWithText(Card, "Outlined"), findsOneWidget);
        //
        // // Alert Dialog
        // Finder dialogExample = find.widgetWithText(TextButton, "Open Dialog");
        // await tester.scrollUntilVisible(
        //   dialogExample,
        //   500.0,
        // );
        // expect(dialogExample, findsOneWidget);
      });
}
