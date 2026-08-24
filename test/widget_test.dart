import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/main.dart';
import 'package:aesthetic_way/core/widgets/app_brand_logo.dart';
import 'package:aesthetic_way/features/navigation/main_nav_screen.dart';

void main() {
  testWidgets('AestheticWayApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AestheticWayApp(homeScreen: MainNavScreen()));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AppBrandLogo), findsWidgets);
    expect(find.text('الرئيسية'), findsOneWidget);
  });
}
