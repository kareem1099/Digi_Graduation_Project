import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/full_monitoring_controller.dart';

/// Interactive Floating Action Button for area detection.
/// Handles recording and API processing states with reactive UI updates.
class RecordActionButton extends GetView<FullMonitoringController> {
  const RecordActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isProcessing = controller.isRecording.value;

      return FloatingActionButton.extended(
        onPressed: controller.startRecordingAndSend,
        // Changes icon based on recording state
        icon: Icon(isProcessing ? Icons.stop : Icons.camera_alt),
        // Displays status text based on state
        label: Text(isProcessing ? 'Processing...' : 'Detect Area'),
        // Changes color when processing to warn the user
        backgroundColor: isProcessing ? Colors.red : Colors.deepPurple,
      );
    });
  }
}
