import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kaiten/cerebral_palsy/bindings/cerebral_palsy_binding.dart';
import 'package:kaiten/cerebral_palsy/views/cerebral_palsy_view.dart';

void main() {
  testWidgets('CerebralPalsyView builds and renders successfully', (WidgetTester tester) async {
    CerebralPalsyBinding().dependencies();

    await tester.pumpWidget(
      const GetMaterialApp(
        home: CerebralPalsyView(),
      ),
    );

    // Let the widget render
    await tester.pump();

    // Verify key instructional texts are displayed
    expect(find.text("Cerebral Palsy Screening"), findsWidgets);
    expect(find.text("Preparation Guidelines"), findsOneWidget);
    expect(find.text("Upload Baby's Video"), findsOneWidget);
  });
}
