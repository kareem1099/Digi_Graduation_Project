import 'package:get/get.dart';
import '../controllers/cerebral_palsy_controller.dart';

class CerebralPalsyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CerebralPalsyController>(
      () => CerebralPalsyController(),
    );
  }
}
