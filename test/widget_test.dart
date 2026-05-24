import 'package:flutter_test/flutter_test.dart';
import 'package:smartpay_ai/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Cek apakah app jalan (tidak crash)
    expect(find.byType(MyApp), findsOneWidget);
  });
}