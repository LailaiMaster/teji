import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teji_app/src/app.dart';

void main() {
  testWidgets('renders the app shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TejiApp());
    await tester.pumpAndSettle();

    expect(find.text('连不上数据服务'), findsOneWidget);
    expect(find.text('配置数据服务'), findsOneWidget);
  });
}
