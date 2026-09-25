import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:padiapps/main.dart';

void main() {
  testWidgets('shows login then opens dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartRiceNurseryApp()));

    expect(find.text('ORYZA SMART'), findsOneWidget);
    expect(find.text('Masuk Akun'), findsOneWidget);

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Petani'), findsOneWidget);
  });
}
