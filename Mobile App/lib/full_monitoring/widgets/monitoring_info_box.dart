import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/full_monitoring_controller.dart';

/// A widget that displays real-time statistics about the monitoring session.
/// Shows detections count, alarm status, and camera stream status in a compact box.
class MonitoringInfoBox extends GetView<FullMonitoringController> {
  const MonitoringInfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Number of poses detected in the current frame
            Text(
              '👤 Poses: ${controller.poses.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            // Number of contour points currently loaded from the API
            Text(
              '📍 Contours: ${controller.contour.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            // Indicates if the alarm sound is currently active
            Text(
              '🔊 Alarm: ${controller.isAlarmPlaying.value ? "Playing" : "Silent"}',
              style: TextStyle(
                color: controller.isAlarmPlaying.value ? Colors.red : Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            // Indicates if the camera stream is currently active or paused
            Text(
              '📹 Stream: ${controller.isStreamActive.value ? "Active" : "Stopped"}',
              style: TextStyle(
                color: controller.isStreamActive.value ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        )),
      ),
    );
  }
}
