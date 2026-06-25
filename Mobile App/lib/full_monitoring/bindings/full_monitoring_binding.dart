import 'package:get/get.dart';
import '../controllers/full_monitoring_controller.dart';

class FullMonitoringBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FullMonitoringController>(
      () => FullMonitoringController(),
    );
  }
}
