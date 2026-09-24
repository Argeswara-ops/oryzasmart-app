import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:padiapps/main.dart';

void main() {
  testWidgets('shows login then opens dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartRiceNurseryApp()));

    expect(find.text('Smart Rice Nursery'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Monitoring pembibitan padi realtime'), findsOneWidget);
  });
}
