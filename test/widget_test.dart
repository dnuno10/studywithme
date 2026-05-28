import 'package:flutter_test/flutter_test.dart';

import 'package:studywithme/app/study_with_me_app.dart';

void main() {
  testWidgets('renders dashboard shell', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyWithMeApp());

    expect(find.text('STUDYWITHME'), findsOneWidget);
    expect(find.text('GENERAR MATERIAL'), findsOneWidget);
  });
}
