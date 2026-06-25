import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:kaiten/contants/colors.dart';
import '../controllers/cerebral_palsy_controller.dart';

class CerebralPalsyView extends StatelessWidget {
  const CerebralPalsyView({super.key});

  CerebralPalsyController get controller {
    if (!Get.isRegistered<CerebralPalsyController>()) {
      Get.put(CerebralPalsyController());
    }
    return Get.find<CerebralPalsyController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: myColors.textDark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Cerebral Palsy Screening",
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: myColors.textDark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0XFFEFEEE3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          // 1. If currently performing analysis, render full screen interactive loader
          if (controller.isAnalyzing.value) {
            return _buildAnalysisLoaderOverlay();
          }

          // 2. If result is available, render screening results directly
          if (controller.resultState.value.isNotEmpty) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: _buildResultsLayout(),
            );
          }

          // 3. Default state: Guidelines & Video Pick/Preview Section
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Guidelines Card
                _buildGuidelinesCard(),
                const SizedBox(height: 24),
                
                // Video Pick/Preview Section
                _buildVideoSection(context),
                const SizedBox(height: 32),
                
                // Start Button
                if (controller.videoPath.value.isNotEmpty) _buildAnalyzeButton(),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ------------------------------------------------------------------
  // GUIDELINES / INSTRUCTIONS CARD
  // ------------------------------------------------------------------
  Widget _buildGuidelinesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0XFFE4E3D7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: myColors.limeAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Color(0XFF575C40),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Preparation Guidelines",
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: myColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStepRow("1", "Flat Surface", "Lay your baby safely on a stable, flat surface (e.g. mattress or play mat)."),
          const SizedBox(height: 12),
          _buildStepRow("2", "Full Body Visibility", "Ensure the camera captures the entire body of the baby from head to toe."),
          const SizedBox(height: 12),
          _buildStepRow("3", "Optimal Environment", "Record in a brightly lit room. Keep loose toys, blankets, and bulky clothes out of the view."),
          const SizedBox(height: 12),
          _buildStepRow("4", "Stable 1-Min Video", "Keep the camera steady. Capture about 1 minute of spontaneous, natural body movements."),
        ],
      ),
    );
  }

  Widget _buildStepRow(String number, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0XFFF4F3E8),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: myColors.tealSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: myColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: myColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // VIDEO SELECTOR & PREVIEW AREA
  // ------------------------------------------------------------------
  Widget _buildVideoSection(BuildContext context) {
    if (controller.videoPath.value.isEmpty) {
      return _buildUploadPickerArea();
    }
    return _buildVideoPreviewArea();
  }

  Widget _buildUploadPickerArea() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0XFFC0C8C8).withValues(alpha: 0.5),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.video_library_rounded,
            color: myColors.tealSecondary,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            "Upload Baby's Video",
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: myColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Avg duration: ~1 minute. Recommended file size: < 100MB",
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: myColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.pickVideo(ImageSource.camera),
                  icon: const Icon(Icons.videocam_rounded, size: 18),
                  label: Text(
                    "Camera",
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: myColors.tealSecondary,
                    side: const BorderSide(color: Color(0XFFE4E3D7)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => controller.pickVideo(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: Text(
                    "Gallery",
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: myColors.tealPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVideoPreviewArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0XFFE4E3D7), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.videoName.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: myColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${controller.videoSizeMB.value} MB • ${controller.videoDurationSec.value.toInt()} sec",
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: myColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => controller.removeVideo(),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Video Player Container
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 200,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (controller.isVideoInitialized.value)
                    GestureDetector(
                      onTap: () => controller.togglePlayPause(),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: controller.videoPlayerController!.value.aspectRatio,
                          child: VideoPlayer(controller.videoPlayerController!),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  
                  // Semi-transparent play button overlay
                  if (controller.isVideoInitialized.value && !controller.isPlaying.value)
                    GestureDetector(
                      onTap: () => controller.togglePlayPause(),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // START ANALYSIS BUTTON
  // ------------------------------------------------------------------
  Widget _buildAnalyzeButton() {
    return ElevatedButton(
      onPressed: () => controller.startAnalysis(),
      style: ElevatedButton.styleFrom(
        backgroundColor: myColors.tealPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: myColors.tealPrimary.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        "Start Motor Assessment",
        style: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // SIMULATED LOADING & ASSESSMENT INTERACTIVE OVERLAY
  // ------------------------------------------------------------------
  Widget _buildAnalysisLoaderOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rotating Progress Indicator
              Center(
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: controller.analysisProgress.value,
                        strokeWidth: 6,
                        backgroundColor: const Color(0XFFF4F3E8),
                        valueColor: const AlwaysStoppedAnimation<Color>(myColors.tealPrimary),
                      ),
                      Text(
                        "${(controller.analysisProgress.value * 100).toInt()}%",
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: myColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                "Analyzing Body Movements",
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: myColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                "Calculating infant motor index. Please keep this screen open.",
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: myColors.textMuted,
                ),
              ),
              const SizedBox(height: 28),
              
              const Divider(color: Color(0XFFEFEEE3), height: 1),
              const SizedBox(height: 20),
              
              // Progress steps check list
              Column(
                children: List.generate(controller.analysisSteps.length, (index) {
                  final currentStep = controller.analysisStepIndex.value;
                  final isDone = index < currentStep;
                  final isActive = index == currentStep;
                  
                  Color iconColor = Colors.grey.shade300;
                  IconData stepIcon = Icons.radio_button_unchecked_rounded;
                  
                  if (isDone) {
                    iconColor = Colors.green;
                    stepIcon = Icons.check_circle_rounded;
                  } else if (isActive) {
                    iconColor = myColors.tealPrimary;
                    stepIcon = Icons.sync_rounded; // loading icon style
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(stepIcon, color: iconColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            controller.analysisSteps[index],
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              color: isActive 
                                  ? myColors.textDark 
                                  : (isDone ? myColors.textDark.withValues(alpha: 0.6) : myColors.textMuted.withValues(alpha: 0.4)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // HEALTH ASSESSMENT SCREENING RESULTS PAGE
  // ------------------------------------------------------------------
  Widget _buildResultsLayout() {
    final bool isPositive = controller.resultState.value == "positive";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Icon Card
        Container(
          decoration: BoxDecoration(
            color: isPositive ? const Color(0XFFFFCCD5) : const Color(0XFFD8F3DC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPositive ? const Color(0XFFFFB3C1) : const Color(0XFFB7E4C7),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0XFFFF8FA3) : const Color(0XFF95D5B2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  color: isPositive ? const Color(0XFFC9184A) : const Color(0XFF1B4332),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isPositive ? "Assessment Completed: Further Screen Recommended" : "Assessment Completed: Healthy Range",
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? const Color(0XFF800F2F) : const Color(0XFF081C15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Detailed Info Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0XFFE4E3D7), width: 1),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Movement Pattern Analysis",
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: myColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                isPositive 
                    ? "Our deep learning movement analyzer has identified some differences in your infant's spontaneous general movement patterns. Atypical or asymmetrical movement indices can occasionally suggest developmental hurdles."
                    : "The spatio-temporal posture analysis has confirmed typical development metrics. The baby's movements show bilateral coordination, full extension symmetry, and consistent movement diversity.",
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  height: 1.5,
                  color: myColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              
              const Divider(color: Color(0XFFEFEEE3)),
              const SizedBox(height: 16),
              
              Text(
                "Key Recommendations",
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: myColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              
              if (isPositive) ...[
                _buildRecommendationRow("Share this screening with your primary pediatrician."),
                _buildRecommendationRow("Consult a specialized pediatric neurologist for clinical tests."),
                _buildRecommendationRow("Encourage tummy-time play under visual support."),
              ] else ...[
                _buildRecommendationRow("Continue standard developmental checks and schedules."),
                _buildRecommendationRow("Incorporate interactive tracking play (e.g. rattling toys)."),
                _buildRecommendationRow("Maintain natural milestone logs and movement updates."),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Clinical Disclaimer
        Container(
          decoration: BoxDecoration(
            color: const Color(0XFFF4F3E8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0XFFE4E3D7), width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: myColors.tealSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Medical Disclaimer: This AI-powered movement assessment functions as a preliminary wellness screening assistance, not a primary medical diagnostic test. Always seek specialized pediatrician guidance regarding infant motor concerns.",
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: myColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Re-analyze Button
        ElevatedButton(
          onPressed: () => controller.resetAll(),
          style: ElevatedButton.styleFrom(
            backgroundColor: myColors.tealPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            "Screen Another Video",
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationRow(String recommendation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.fiber_manual_record,
            color: myColors.tealSecondary,
            size: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5,
                color: myColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
