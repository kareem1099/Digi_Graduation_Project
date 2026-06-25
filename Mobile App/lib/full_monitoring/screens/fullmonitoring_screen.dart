import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Helpers/pose _contour_overlay.dart';
import '../controllers/full_monitoring_controller.dart';
import '../widgets/monitoring_info_box.dart';
import '../widgets/record_action_button.dart';
import '../widgets/warning_banner.dart';

/// The main entry point for the real-time monitoring feature.
/// This screen provides a live camera feed with an overlay of detected poses
/// and alerts the user to posture issues based on the active detection logic.
class CameraScreen extends GetView<FullMonitoringController> {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading screen while camera or controller is initializing
      if (controller.isInitializing.value ||
          controller.cameraController.value == null ||
          !controller.cameraController.value!.value.isInitialized) {
        return _buildLoadingScreen();
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Real-Time Posture Monitoring'),
          backgroundColor: Colors.deepPurple,
          elevation: 4,
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Full-screen camera preview layer
                  _buildCameraPreview(),

                  // AI detection overlays (poses, contours, and corners)
                  _buildDetectionOverlay(),

                  // Posture warning notification banner
                  const WarningBanner(),

                  // Session status and metadata box
                  const MonitoringInfoBox(),
                ],
              ),
            ),
          ],
        ),
        // Primary action button to trigger recording and area analysis
        floatingActionButton: const RecordActionButton(),
      );
    });
  }

  /// Displays a simple loading state while subsystems prepare.
  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing Camera...'),
          ],
        ),
      ),
    );
  }

  /// Calculates the camera layout and renders the preview frame.
  Widget _buildCameraPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sync display dimensions to the controller for accurate coordinate mapping
        controller.displayWidth = constraints.maxWidth;
        controller.displayHeight = constraints.maxHeight;
        controller.updateCameraLayout();
        
        return CameraPreview(controller.cameraController.value!);
      },
    );
  }

  /// Renders a transparent overlay that draws pose landmarks and detected areas.
  Widget _buildDetectionOverlay() {
    return Positioned(
      left: controller.offsetX,
      top: controller.offsetY,
      width: controller.actualCameraWidth,
      height: controller.actualCameraHeight,
      child: Obx(() => PoseContourOverlay(
        poses: controller.poses,
        contour: controller.contour,
        corners: controller.corners,
        cameraController: controller.cameraController.value!,
        sensorOrientation: controller.sensorOrientation,
        displayWidth: controller.actualCameraWidth,
        displayHeight: controller.actualCameraHeight,
        yAdjustment: controller.yAdjustment,
        cameraImageWidth: controller.cameraImageWidth,
        cameraImageHeight: controller.cameraImageHeight,
      )),
    );
  }
}