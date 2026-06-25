import 'dart:async';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class CerebralPalsyController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  
  // Observables for state management
  var videoPath = "".obs;
  var videoName = "".obs;
  var videoSizeMB = 0.0.obs;
  var videoDurationSec = 0.0.obs;
  
  VideoPlayerController? videoPlayerController;
  var isVideoInitialized = false.obs;
  var isPlaying = false.obs;
  
  // Analysis States
  var isAnalyzing = false.obs;
  var analysisProgress = 0.0.obs;
  var analysisStepIndex = 0.obs;
  var analysisStatusText = "Initializing frame extraction...".obs;
  
  // Result States: "" (none), "negative" (low risk), "positive" (high risk)
  var resultState = "".obs;

  final List<String> analysisSteps = [
    "Decoding video streams and extracting key frames...",
    "Running Spatio-Temporal Graph Convolutional Neural Networks (ST-GCN)...",
    "Measuring upper/lower limb asymmetry & movement range...",
    "Generating deep-learning motor screening indices...",
  ];

  /// Pick a video using ImagePicker (from Gallery or Camera)
  Future<void> pickVideo(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
      
      if (file != null) {
        // Reset old player first
        await _clearVideoPlayer();
        
        videoPath.value = file.path;
        videoName.value = file.name;
        
        // Read file size
        final bytes = await file.length();
        videoSizeMB.value = double.parse((bytes / (1024 * 1024)).toStringAsFixed(2));
        
        // Initialize video player
        videoPlayerController = VideoPlayerController.contentUri(Uri.parse(file.path))
          ..initialize().then((_) {
            videoDurationSec.value = videoPlayerController!.value.duration.inSeconds.toDouble();
            isVideoInitialized.value = true;
            isPlaying.value = false;
            update();
          }).catchError((error) {
            Get.snackbar(
              "Error",
              "Could not load or play the selected video file.",
              snackPosition: SnackPosition.BOTTOM,
            );
          });
      }
    } catch (e) {
      Get.snackbar(
        "Upload Failed",
        "An unexpected error occurred while picking the video.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle playback state of video preview
  void togglePlayPause() {
    if (videoPlayerController != null && isVideoInitialized.value) {
      if (videoPlayerController!.value.isPlaying) {
        videoPlayerController!.pause();
        isPlaying.value = false;
      } else {
        videoPlayerController!.play();
        isPlaying.value = true;
      }
    }
  }

  /// Remove selected video and clean up
  Future<void> removeVideo() async {
    await _clearVideoPlayer();
    videoPath.value = "";
    videoName.value = "";
    videoSizeMB.value = 0.0;
    videoDurationSec.value = 0.0;
    resultState.value = "";
  }

  /// Internal cleanup for video player instance
  Future<void> _clearVideoPlayer() async {
    if (videoPlayerController != null) {
      await videoPlayerController!.pause();
      await videoPlayerController!.dispose();
      videoPlayerController = null;
      isVideoInitialized.value = false;
      isPlaying.value = false;
    }
  }

  /// Launch the multi-step simulated movement analysis
  void startAnalysis() {
    if (videoPath.isEmpty) return;
    
    isAnalyzing.value = true;
    analysisProgress.value = 0.0;
    analysisStepIndex.value = 0;
    analysisStatusText.value = analysisSteps[0];
    resultState.value = "";
    
    // Smooth progress simulation using periodic Timer
    int tick = 0;
    const int totalTicks = 80; // 80 ticks of 100ms = 8 seconds total
    
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!isAnalyzing.value) {
        timer.cancel();
        return;
      }
      
      tick++;
      analysisProgress.value = tick / totalTicks;
      
      // Update step text based on progress intervals
      if (tick == 20) {
        analysisStepIndex.value = 1;
        analysisStatusText.value = analysisSteps[1];
      } else if (tick == 45) {
        analysisStepIndex.value = 2;
        analysisStatusText.value = analysisSteps[2];
      } else if (tick == 65) {
        analysisStepIndex.value = 3;
        analysisStatusText.value = analysisSteps[3];
      }
      
      if (tick >= totalTicks) {
        timer.cancel();
        isAnalyzing.value = false;
        analysisProgress.value = 1.0;
        
        // Randomly simulate typical or atypical movements for evaluation demonstration
        // 70% typical/low-risk, 30% further evaluation recommended (high risk)
        final randomVal = DateTime.now().millisecond % 10;
        if (randomVal < 7) {
          resultState.value = "negative"; // typical/low-risk
        } else {
          resultState.value = "positive"; // atypical/requires assessment
        }
      }
    });
  }

  /// Reset the full feature state
  Future<void> resetAll() async {
    await removeVideo();
    isAnalyzing.value = false;
    analysisProgress.value = 0.0;
    analysisStepIndex.value = 0;
    resultState.value = "";
  }

  @override
  void onClose() {
    _clearVideoPlayer();
    super.onClose();
  }
}
