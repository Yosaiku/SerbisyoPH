import 'package:flutter_test/flutter_test.dart';
import 'package:serbisyo_ph/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SerbisyoApp());
    expect(find.byType(SerbisyoApp), findsOneWidget);
  });
}
