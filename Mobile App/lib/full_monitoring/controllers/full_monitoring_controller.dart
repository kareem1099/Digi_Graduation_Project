import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kaiten/full_monitoring/services/detecting_edges_service.dart';
import '../Helpers/posemonitor.dart';

class FullMonitoringController extends GetxController {
  final Rx<CameraController?> cameraController = Rx<CameraController?>(null);
  final RxBool isInitializing = true.obs;
  final RxBool isRecording = false.obs;
  final RxBool isAlarmPlaying = false.obs;
  final RxBool isStreamActive = false.obs;
  final RxList<Pose> poses = <Pose>[].obs;
  final List<Offset> contour = <Offset>[].obs;
  final List<Offset> corners = <Offset>[].obs;

  late PoseDetector _poseDetector;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ContourService _contourService = ContourService(
    baseUrl:
        "https://deployv1-guh6g3d9fxejb3gd.italynorth-01.azurewebsites.net");
  late PostureMonitor _postureMonitor;

  int? sensorOrientation;
  double displayWidth = 0;
  double displayHeight = 0;
  double offsetX = 0;
  double offsetY = 0;
  double actualCameraWidth = 0;
  double actualCameraHeight = 0;
  double yAdjustment = 0;
  double cameraImageWidth = 0;
  double cameraImageHeight = 0;

  int _frameCount = 0;
  static const int _skipFrames = 1;
  DateTime? _lastProcessTime;
  static const int _minProcessIntervalMs = 50;

  bool _isBusy = false;
  bool _isWarmedUp = false;

  @override
  void onInit() {
    super.onInit();
    _initializePoseDetector();
    _initializePostureMonitor();
    _setupAudioPlayer();
    _initializeCamera();
    _checkApiHealth();
  }

  /// Polls the API health endpoint to verify the model is loaded and ready.
  Future<void> _checkApiHealth() async {
    debugPrint('Checking API health...');
    final health = await _contourService.checkHealth();
    if (health != null && health['model_loaded'] == true) {
      debugPrint('✅ API model is loaded and ready');
    } else {
      debugPrint('⚠️ API not ready yet, will retry...');
      // Retry after 5 seconds if model isn't loaded
      Future.delayed(const Duration(seconds: 5), _checkApiHealth);
    }
  }

  void _initializePoseDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );
    _warmUpPoseDetector();
  }

  void _initializePostureMonitor() {
    _postureMonitor = PostureMonitor(
      onAlarmTriggered: () => _triggerAlarm(),
    );
  }

  Future<void> _setupAudioPlayer() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    } catch (e) {
      debugPrint("❌ Audio Player setup error: $e");
    }
  }

  Future<void> _warmUpPoseDetector() async {
    try {
      final dummyImage = InputImage.fromBytes(
        bytes: Uint8List(100),
        metadata: InputImageMetadata(
          size: const Size(10, 10),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 10,
        ),
      );
      await _poseDetector.processImage(dummyImage);
      _isWarmedUp = true;
    } catch (e) {
      _isWarmedUp = true;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      sensorOrientation = backCamera.sensorOrientation;
      cameraController.value = controller;
      
      _startImageStream();
      isInitializing.value = false;
    } catch (e) {
      debugPrint("❌ Camera initialization error: $e");
    }
  }

  void _startImageStream() {
    if (cameraController.value != null &&
        cameraController.value!.value.isInitialized &&
        !isStreamActive.value) {
      isStreamActive.value = true;
      cameraController.value!.startImageStream((CameraImage image) async {
        if (!_isWarmedUp) return;

        _frameCount++;
        if (_frameCount % (_skipFrames + 1) != 0) return;

        final now = DateTime.now();
        if (_lastProcessTime != null) {
          final diff = now.difference(_lastProcessTime!).inMilliseconds;
          if (diff < _minProcessIntervalMs) return;
        }

        if (_isBusy) return;
        _isBusy = true;
        _lastProcessTime = now;

        if (cameraImageWidth == 0) {
          cameraImageWidth = image.width.toDouble();
          cameraImageHeight = image.height.toDouble();
        }

        try {
          final inputImage = _convertCameraImageToInputImage(image);
          final detectedPoses = await _poseDetector.processImage(inputImage);
          poses.assignAll(detectedPoses);
          _checkPostures(detectedPoses);
        } catch (e) {
          debugPrint("⚠️ Pose detection error: $e");
        } finally {
          _isBusy = false;
        }
      });
    }
  }

  Future<void> stopImageStream() async {
    if (cameraController.value != null &&
        cameraController.value!.value.isStreamingImages &&
        isStreamActive.value) {
      await cameraController.value!.stopImageStream();
      isStreamActive.value = false;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  InputImage _convertCameraImageToInputImage(CameraImage image) {
    final camera = cameraController.value!.description;
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _checkPostures(List<Pose> detectedPoses) {
    if (detectedPoses.isEmpty) {
      _stopAlarm();
      _postureMonitor.clearWarning();
      return;
    }

    for (final pose in detectedPoses) {
      _postureMonitor.checkWSitting(pose);
      _postureMonitor.checkHeadDown(pose);
      _postureMonitor.checkBackBending(pose);
    }

    if (contour.isNotEmpty && cameraImageWidth > 0 && cameraImageHeight > 0) {
      final isPortrait = sensorOrientation == 90 || sensorOrientation == 270;
      final imageWidth = isPortrait ? cameraImageHeight : cameraImageWidth;
      final imageHeight = isPortrait ? cameraImageWidth : cameraImageHeight;

      final scaleX = actualCameraWidth / imageWidth;
      final scaleY = actualCameraHeight / imageHeight;

      final List<Pose> scaledPoses = detectedPoses.map((pose) {
        final Map<PoseLandmarkType, PoseLandmark> scaledLandmarks = {};
        pose.landmarks.forEach((type, landmark) {
          final x = landmark.x * scaleX;
          final y = (landmark.y * scaleY) - yAdjustment;
          scaledLandmarks[type] = PoseLandmark(
            type: type,
            x: x,
            y: y,
            z: landmark.z,
            likelihood: landmark.likelihood,
          );
        });
        return Pose(landmarks: scaledLandmarks);
      }).toList();

      _postureMonitor.checkKeypointsNearContour(contour, scaledPoses);
    }
  }

  Future<void> _triggerAlarm() async {
    if (!isAlarmPlaying.value) {
      isAlarmPlaying.value = true;
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(
          AssetSource('scotland-eas-alarm-2024-loud-333886.mp3'),
          volume: 1.0,
        );
      } catch (e) {
        isAlarmPlaying.value = false;
      }
    }
  }

  Future<void> _stopAlarm() async {
    if (isAlarmPlaying.value) {
      try {
        await _audioPlayer.stop();
        isAlarmPlaying.value = false;
      } catch (e) {
        debugPrint("❌ Error stopping alarm: $e");
      }
    }
  }

  Future<void> startRecordingAndSend() async {
    if (isRecording.value) return;

    isRecording.value = true;
    _isBusy = true;

    try {
      await stopImageStream();
      await cameraController.value!.startVideoRecording();
      await Future.delayed(const Duration(seconds: 3));
      final file = await cameraController.value!.stopVideoRecording();
      final videoFile = File(file.path);

      updateCameraLayout();

      final response = await _contourService.sendVideo(videoFile);

      if (response != null) {
        // Parse contour using normalized coordinates from the API
        final rawContour = _contourService.parseContour(
          response['contour'],
          actualCameraWidth,
          actualCameraHeight,
        );

        contour.assignAll(rawContour.map((point) {
          return Offset(point.dx, point.dy - yAdjustment);
        }).toList());

        // Parse corners as well (the new API returns these)
        final rawCorners = _contourService.parseCorners(
          response['corners'],
          actualCameraWidth,
          actualCameraHeight,
        );

        corners.assignAll(rawCorners.map((point) {
          return Offset(point.dx, point.dy - yAdjustment);
        }).toList());
      }
    } catch (e) {
      debugPrint("❌ Recording or upload failed: $e");
    } finally {
      _isBusy = false;
      isRecording.value = false;
      _startImageStream();
    }
  }

  void updateCameraLayout() {
    if (cameraController.value != null && cameraController.value!.value.isInitialized) {
      final previewSize = cameraController.value!.value.previewSize!;
      final isPortrait = sensorOrientation == 90 || sensorOrientation == 270;

      final cameraAspectRatio = isPortrait
          ? previewSize.height / previewSize.width
          : previewSize.width / previewSize.height;

      final screenAspectRatio = displayWidth / displayHeight;

      if (screenAspectRatio > cameraAspectRatio) {
        actualCameraWidth = displayHeight * cameraAspectRatio;
        actualCameraHeight = displayHeight;
        offsetX = (displayWidth - actualCameraWidth) / 2;
        offsetY = 0;
      } else {
        actualCameraWidth = displayWidth;
        actualCameraHeight = displayWidth / cameraAspectRatio;
        offsetX = 0;
        offsetY = (displayHeight - actualCameraHeight) / 2;
      }
      yAdjustment = (displayHeight - actualCameraHeight) / 2;
    }
  }

  @override
  void onClose() {
    stopImageStream();
    cameraController.value?.dispose();
    _poseDetector.close();
    _audioPlayer.dispose();
    _postureMonitor.dispose();
    super.onClose();
  }

  ValueListenable<String> get warningText => _postureMonitor.warningText;
}
