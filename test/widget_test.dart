import 'package:flutter_test/flutter_test.dart';
import 'package:quadro_master/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QuadroMasterApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(QuadroMasterApp), findsOneWidget);
  });
}
