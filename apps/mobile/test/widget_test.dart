import 'package:flutter_test/flutter_test.dart';
import 'package:khalashi/main.dart';

void main() {
  testWidgets('Khalashi splash shows brand', (WidgetTester tester) async {
    await tester.pumpWidget(const KhalashiApp());
    await tester.pump();
    expect(find.text('Khalashi'), findsOneWidget);
  });
}
