// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

// TODO: Actually write some tests
void main() {
  test("Testing nothing", () => true);

  /// Make sure that we can query for a specific user
  // testWidgets("API specific author test", (WidgetTester tester) async {
  //   await tester.pumpWidget(MyApp());
  //   final testUser = Author(id: "6687542291974308869", uniqueId: "memezar");
  //   print("YEET");
  //   final testUserInfo = await API.getAuthorInfo(testUser);
  //   print("MEAT");

  //   // Make sure that we got back the same user
  //   expect(testUserInfo.user.id, testUser.id);
  //   expect(testUserInfo.user.uniqueId, testUser.uniqueId);
  // }, timeout: Timeout(Duration(seconds: 10)));
  // testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await tester.pumpWidget(MyApp());

  //   // Verify that our counter starts at 0.
  //   expect(find.text('0'), findsOneWidget);
  //   expect(find.text('1'), findsNothing);

  //   // Tap the '+' icon and trigger a frame.
  //   await tester.tap(find.byIcon(Icons.add));
  //   await tester.pump();

  //   // Verify that our counter has incremented.
  //   expect(find.text('0'), findsNothing);
  //   expect(find.text('1'), findsOneWidget);
  // });
}
