import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pose_estimation_controller.dart';
import '../services/cry_detection_service.dart';
import '../widgets/pageboard.dart';
import '../widgets/pose_painter.dart';

/// The main view for the Pose Estimation feature.
/// It displays the live camera feed, overlays a skeleton in real-time,
/// and provides Baby Cry Detection via the connected backend API.
class PoseEstimationView extends GetView<PoseEstimationController> {
  const PoseEstimationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen Camera Preview
          Obx(() {
            final controllerVal = controller.cameraController.value;
            if (controller.isInitializing.value || controllerVal == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return AspectRatio(
                aspectRatio: controllerVal.value.aspectRatio,
                child: CameraPreview(controllerVal),
            );
          }),

          // 2. Real-time Skeleton Overlay
          Obx(() {
            final controllerVal = controller.cameraController.value;
            if (controllerVal == null || 
                !controllerVal.value.isInitialized || 
                controller.poses.isEmpty ||
                controller.absoluteImageSize == null ||
                controller.rotation == null) {
              return const SizedBox.shrink();
            }

            return CustomPaint(
              painter: PosePainter(
                controller.poses,
                controller.absoluteImageSize!,
                controller.rotation!,
              ),
            );
          }),

          // 3. Cry Detection Results Panel (shown when a result is available)
          Obx(() {
            if (!controller.hasCryResult.value || controller.cryResult.isEmpty) {
              return const SizedBox.shrink();
            }
            return _buildCryResultPanel();
          }),

          // 4. UI Decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: const Pageboard(),
          ),

          // 5. API Health Status Badge
          Positioned(
            top: 100,
            right: 16,
            child: Obx(() => _buildHealthBadge()),
          ),

          // 6. Instructional Text & Recording Status
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Obx(() {
              if (controller.isRecording.value) {
                return _buildRecordingIndicator();
              }
              if (controller.isProcessingAudio.value) {
                return _buildProcessingIndicator();
              }
              return const SizedBox.shrink();
            }),
          ),

          // 7. Mic Button (FAB)
          Positioned(
            bottom: 32,
            right: 24,
            child: _buildMicButton(),
          ),
        ],
      ),
    );
  }

  /// Builds the API health status badge showing if both models are loaded.
  Widget _buildHealthBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: controller.isApiReady.value
            ? Colors.green.withAlpha(180)
            : Colors.orange.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            controller.isApiReady.value
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            controller.isApiReady.value ? 'Cry AI Ready' : 'Loading...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the microphone floating action button.
  Widget _buildMicButton() {
    return Obx(() {
      // Show a loading indicator while processing
      if (controller.isProcessingAudio.value) {
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withAlpha(200),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ),
        );
      }

      return FloatingActionButton(
        onPressed: controller.isRecording.value
            ? () => controller.stopCryDetection()
            : () => controller.startCryDetection(),
        backgroundColor: controller.isRecording.value
            ? Colors.red
            : Colors.white,
        child: Icon(
          controller.isRecording.value
              ? Icons.stop_rounded
              : Icons.mic_rounded,
          color: controller.isRecording.value
              ? Colors.white
              : const Color(0XFF356668),
          size: 28,
        ),
      );
    });
  }

  /// Builds the recording indicator banner.
  Widget _buildRecordingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Recording... tap stop to analyze',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the processing indicator banner.
  Widget _buildProcessingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Analyzing audio...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a panel showing the cry detection results.
  Widget _buildCryResultPanel() {
    final result = controller.cryResult;
    if (result.isEmpty) return const SizedBox.shrink();

    final isCry = result['is_cry'] == true;
    final stage1 = result['stage1'] as Map<String, dynamic>?;
    final stage2 = result['stage2'] as Map<String, dynamic>?;
    final processingTime = result['processing_time_sec'] as num?;
    final duration = result['duration_sec'] as num?;

    String? cryType;
    double? cryConfidence;
    if (isCry && stage2 != null) {
      cryType = stage2['cry_type'] as String?;
      cryConfidence = (stage2['confidence'] as num?)?.toDouble();
    }

    final stage1Confidence = stage1 != null
        ? (stage1['confidence'] as num?)?.toDouble()
        : null;

    return Positioned(
      top: 150,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCry
                ? Colors.red.withAlpha(220)
                : Colors.green.withAlpha(220),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isCry ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCry ? 'Cry Detected!' : 'No Cry Detected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.hasCryResult.value = false,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Cry Type Info (only if cry detected)
              if (isCry && cryType != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CryDetectionService.cryTypeIcon(cryType),
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cryType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            CryDetectionService.cryTypeMessage(cryType),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Confidence info
              Text(
                'Detection confidence: ${stage1Confidence != null ? '${(stage1Confidence * 100).toStringAsFixed(0)}%' : 'N/A'}'
                '${isCry && cryConfidence != null ? '  |  Type confidence: ${(cryConfidence * 100).toStringAsFixed(0)}%' : ''}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              if (duration != null || processingTime != null)
                Text(
                  '${duration != null ? '${duration.toStringAsFixed(1)}s clip' : ''}'
                  '${duration != null && processingTime != null ? ' · ' : ''}'
                  '${processingTime != null ? 'Processed in ${processingTime.toStringAsFixed(2)}s' : ''}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
