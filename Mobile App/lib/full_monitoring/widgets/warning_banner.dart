import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/full_monitoring_controller.dart';

/// A widget that displays posture warnings based on the monitor's state.
/// It uses [ValueListenableBuilder] to listen for real-time warning text.
class WarningBanner extends GetView<FullMonitoringController> {
  const WarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: ValueListenableBuilder<String>(
        valueListenable: controller.warningText,
        builder: (context, warning, child) {
          // Hide building if there's no warning
          if (warning.isEmpty) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Using red with slight transparency for a modern alert look
              color: Colors.red.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    warning,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
