import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../services/cry_detection_service.dart';

class PoseEstimationController extends GetxController {
  // --- Observables ---
  final Rx<CameraController?> cameraController = Rx<CameraController?>(null);
  final RxBool isInitializing = true.obs;
  final RxList<Pose> poses = <Pose>[].obs;

  // --- ML Kit Components ---
  late PoseDetector _poseDetector;
  bool _isBusy = false;

  // --- Image Metadata (for coordinate translation) ---
  Size? absoluteImageSize;
  InputImageRotation? rotation;

  // --- Baby Cry Detection ---
  final CryDetectionService _cryService = CryDetectionService(
    baseUrl: "https://deployv2-ddexa6ctbpfae9af.italynorth-01.azurewebsites.net",
  );
  final AudioRecorder _audioRecorder = AudioRecorder();
  final RxBool isApiReady = false.obs;
  final RxBool isApiChecking = true.obs;
  final RxBool isRecording = false.obs;
  final RxBool isProcessingAudio = false.obs;
  final cryResult = RxMap<String, dynamic>({});
  final RxBool hasCryResult = false.obs;
  bool _disposed = false;
  int _healthCheckRetries = 0;
  static const int _maxHealthCheckRetries = 60;

  @override
  void onInit() {
    super.onInit();
    _initializePoseDetector();
    _initializeCamera();
    _checkApiHealth();
  }

  /// Polls the Baby Cry Detection API health endpoint until both models are loaded.
  Future<void> _checkApiHealth() async {
    if (_disposed) return;
    isApiChecking.value = true;
    debugPrint('Cry Detection - Checking API health...');
    final health = await _cryService.checkHealth();
    if (health != null &&
        health['stage1_loaded'] == true &&
        health['stage2_loaded'] == true) {
      debugPrint('Cry Detection - ✅ Both models loaded and ready');
      isApiReady.value = true;
      isApiChecking.value = false;
    } else {
      _healthCheckRetries++;
      if (_healthCheckRetries >= _maxHealthCheckRetries) {
        debugPrint('Cry Detection - ❌ Max retries reached, giving up');
        isApiReady.value = false;
        isApiChecking.value = false;
        return;
      }
      debugPrint('Cry Detection - ⚠️ Models not ready yet (retry $_healthCheckRetries/$_maxHealthCheckRetries), retrying in 5s...');
      isApiChecking.value = true;
      Future.delayed(const Duration(seconds: 5), _checkApiHealth);
    }
  }

  /// Starts recording audio for cry detection.
  /// Records to a temp file, then sends to the API for analysis.
  Future<void> startCryDetection() async {
    if (isRecording.value || isProcessingAudio.value) return;

    // Request microphone permission
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      debugPrint('Cry Detection - ❌ Microphone permission denied');
      Get.snackbar(
        'Permission Denied',
        'Microphone access is required for cry detection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withAlpha(200),
        colorText: Colors.white,
      );
      return;
    }

    if (!isApiReady.value) {
      Get.snackbar(
        'Still Loading',
        'Cry detection model is still loading. Please wait...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withAlpha(200),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isRecording.value = true;
      hasCryResult.value = false;
      cryResult.clear();

      // Create a temp file for the recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/cry_detection_$timestamp.m4a';

      // Start recording (AAC format for good quality/size balance)
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      debugPrint('Cry Detection - 🎤 Recording started...');
    } catch (e) {
      debugPrint('Cry Detection - ❌ Failed to start recording: $e');
      isRecording.value = false;
    }
  }

  /// Stops recording and sends the audio to the API for analysis.
  Future<void> stopCryDetection() async {
    if (!isRecording.value) return;

    try {
      isRecording.value = false;
      isProcessingAudio.value = true;

      final String? audioPath = await _audioRecorder.stop();
      debugPrint('Cry Detection - ⏹️ Recording stopped: $audioPath');

      if (audioPath == null) {
        debugPrint('Cry Detection - ❌ No audio recorded');
        isProcessingAudio.value = false;
        return;
      }

      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        debugPrint('Cry Detection - ❌ Audio file not found');
        isProcessingAudio.value = false;
        return;
      }

      debugPrint('Cry Detection - 📤 Sending audio for analysis (${audioFile.lengthSync()} bytes)...');

      // Send to the API
      final result = await _cryService.predict(audioFile);

      if (result != null) {
        cryResult.assignAll(result);
        hasCryResult.value = true;

        debugPrint('Cry Detection - ✅ Analysis complete');
        debugPrint('  is_cry: ${result['is_cry']}');
        debugPrint('  stage1: ${result['stage1']}');
        debugPrint('  stage2: ${result['stage2']}');

        // Show a snackbar with the result
        if (result['is_cry'] == true) {
          final stage2 = result['stage2'] as Map<String, dynamic>?;
          final cryType = stage2?['cry_type'] as String? ?? 'unknown';
          final message = CryDetectionService.cryTypeMessage(cryType);
          Get.snackbar(
            'Cry Detected 🍼',
            message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.withAlpha(200),
            colorText: Colors.white,
            duration: const Duration(seconds: 6),
          );
        } else {
          Get.snackbar(
            'No Cry Detected',
            'The audio does not appear to contain a baby cry.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withAlpha(200),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        Get.snackbar(
          'Analysis Failed',
          'Could not process the audio. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withAlpha(200),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Cry Detection - ❌ Error: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withAlpha(200),
        colorText: Colors.white,
      );
    } finally {
      isRecording.value = false;
      isProcessingAudio.value = false;
    }
  }

  /// Cancels the current recording without sending to the API.
  Future<void> cancelRecording() async {
    if (!isRecording.value) return;
    try {
      await _audioRecorder.stop();
      debugPrint('Cry Detection - ❌ Recording cancelled');
    } catch (e) {
      debugPrint('Cry Detection - Error cancelling: $e');
    }
    isRecording.value = false;
  }

  /// Initialize the Google ML Kit Pose Detector with the "accurate" model.
  void _initializePoseDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );
  }

  /// Locate the back camera and initialize the controller.
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      // Select the back-facing camera
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        // YUV420 format is required for ML Kit image stream
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      cameraController.value = controller;
      
      // Start processing frames from the camera
      _startImageStream();
      isInitializing.value = false;
    } catch (e) {
      debugPrint("❌ Camera initialization error: $e");
    }
  }

  /// Register the listener for each camera frame.
  void _startImageStream() {
    final controller = cameraController.value;
    if (controller != null && controller.value.isInitialized) {
      controller.startImageStream((CameraImage image) async {
        if (_isBusy) return;
        _isBusy = true;

        try {
          // Convert the raw camera frame to a format ML Kit understands
          final inputImage = _processCameraImage(image);
          if (inputImage == null) return;

          // Run the pose detection model
          final detectedPoses = await _poseDetector.processImage(inputImage);
          
          // Store metadata for the painter
          absoluteImageSize = inputImage.metadata?.size;
          rotation = inputImage.metadata?.rotation;
          
          // Update the observable list
          poses.assignAll(detectedPoses);
        } catch (e) {
          debugPrint("⚠️ Pose detection error: $e");
        } finally {
          _isBusy = false;
        }
      });
    }
  }

  /// Converts a [CameraImage] from the camera stream to an [InputImage] for ML Kit.
  InputImage? _processCameraImage(CameraImage image) {
    try {
      final controller = cameraController.value;
      if (controller == null) return null;

      final camera = controller.description;
      final sensorOrientation = camera.sensorOrientation;
      
      // Handle the physical orientation of the device sensor
      final inputImageRotation = InputImageRotationValue.fromRawValue(sensorOrientation) 
          ?? InputImageRotation.rotation90deg;

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) 
          ?? (Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888);

      final plane = image.planes.first;

      // Extract bytes from the image planes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: inputImageRotation,
          format: inputImageFormat,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint("❌ Error processing camera image: $e");
      return null;
    }
  }

  @override
  void onClose() {
    _disposed = true;
    // Clean up audio recording resources
    _audioRecorder.dispose();
    
    // Properly clean up camera and ML Kit resources
    cameraController.value?.dispose();
    _poseDetector.close();
    super.onClose();
  }
}
