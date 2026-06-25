import 'package:get/get.dart';
import '../controllers/pose_estimation_controller.dart';

class PoseEstimationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PoseEstimationController>(
      () => PoseEstimationController(),
    );
  }
}
