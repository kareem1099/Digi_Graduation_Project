import 'package:get/get.dart';
import 'package:kaiten/app_routes.dart';

class HomeController extends GetxController {
  // Observable selected index for the bottom navigation bar
  var selectedIndex = 0.obs;

  // Observable baby age for settings screen
  var babyAge = "6 Months".obs;

  // Navigation Methods
  void goToPoseEstimation() {
    Get.toNamed(AppRoutes.poseEstimation);
  }

  void goToFullMonitoring() {
    Get.toNamed(AppRoutes.fullMonitoring);
  }

  void goToFoodGuide() {
    Get.toNamed(AppRoutes.aiAssistant);
  }

  void goToCerebralPalsy() {
    Get.toNamed(AppRoutes.cerebralPalsy);
  }

  void onBottomNavItemTapped(int index) {
    selectedIndex.value = index;
  }
}
