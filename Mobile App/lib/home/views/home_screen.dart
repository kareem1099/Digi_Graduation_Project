import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaiten/contants/colors.dart';
import 'package:kaiten/guide/views/guide_screen.dart';
import 'package:kaiten/settings/views/settings_screen.dart';
import 'package:kaiten/profile/views/profile_screen.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.bgCream,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Stack(
              children: [
                // ----------------------------------------------------
                // BACKGROUND DECORATIONS (Blurred Circles)
                // ----------------------------------------------------
                // Top-Left Circle (300x300, #A8DADC, Blur 40px, Opacity 0.5)
                Positioned(
                  left: -100,
                  top: -100,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 40,
                      sigmaY: 40,
                      tileMode: TileMode.decal,
                    ),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: myColors.tealAccent.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Bottom-Right Circle (250x250, #E1E6C2, Blur 40px, Opacity 0.5)
                Positioned(
                  right: -50,
                  bottom: 100,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 40,
                      sigmaY: 40,
                      tileMode: TileMode.decal,
                    ),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: myColors.limeAccent.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                // ----------------------------------------------------
                // MAIN SCROLLABLE CONTENT
                // ----------------------------------------------------
                Positioned.fill(
                  child: Obx(() {
                    if (controller.selectedIndex.value == 1) {
                      return const GuideScreen();
                    }
                    if (controller.selectedIndex.value == 2) {
                      return const ProfileScreen();
                    }

                    if (controller.selectedIndex.value == 3) {
                      return const SettingsScreen();
                    }
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 128),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // 1. Header Section
                          _buildHeader(),

                          const SizedBox(height: 40),
                          // 2. Hero Section
                          _buildHero(),

                          const SizedBox(height: 40),
                          // 3. Menu / Tools Section
                          _buildMenuSection(),
                        ],
                      ),
                    );
                  }),
                ),

                // ----------------------------------------------------
                // BOTTOM NAVIGATION BAR
                // ----------------------------------------------------
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomNavBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // HEADER WIDGET
  // ------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Logo and App Title Info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: myColors.tealAccent.withValues(alpha: 0.4),
                  border: Border.all(
                    color: myColors.tealSecondary.withValues(alpha: 0.1),
                    width: 1.0,
                  ),
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: Image.asset(
                    "assets/images/logo-02.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "KAITEN",
                    style: GoogleFonts.quicksand(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: myColors.textDark,
                    ),
                  ),
                  Text(
                    "BABY CARE",
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: myColors.textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Right: Notification Bell Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0XFFC0C8C8), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: myColors.tealPrimary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // HERO WIDGET
  // ------------------------------------------------------------------
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Caring for\nBaby Ann",
            style: GoogleFonts.quicksand(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: myColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Everything you need in one calm place",
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: myColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // MENU / TOOLS SECTION WIDGET
  // ------------------------------------------------------------------
  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tools Section Header with Divider
          Row(
            children: [
              Text(
                "TOOLS",
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: myColors.textMuted.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 1.0,
                  color: const Color(0XFFC0C8C8).withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Tool Cards Column
          Column(
            children: [
              _buildMenuCard(
                title: "Cerebral Palsy",
                backgroundColor: const Color(0XFFFFCCD5),
                iconColor: const Color(0XFFC9184A),
                icon: Icons.psychology_rounded,
                onTap: () => controller.goToCerebralPalsy(),
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                title: "Pose Estimation",
                backgroundColor: myColors.tealAccent,
                iconColor: myColors.tealSecondary,
                icon: Icons.child_care_rounded,
                onTap: () => controller.goToPoseEstimation(),
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                title: "Full Monitoring",
                backgroundColor: myColors.lavenderAccent,
                iconColor: const Color(0XFF444C83),
                icon: Icons.videocam_rounded,
                onTap: () => controller.goToFullMonitoring(),
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                title: "Food Guide",
                backgroundColor: myColors.limeAccent,
                iconColor: const Color(0XFF575C40),
                icon: Icons.flatware_rounded,
                onTap: () => controller.goToFoodGuide(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper builder for menu cards
  Widget _buildMenuCard({
    required String title,
    required Color backgroundColor,
    required Color iconColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: const Color(0XFFE4E3D7), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(48),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Rounded Colored Icon Box
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: myColors.textDark,
                    ),
                  ),
                ),
                // Right Chevron
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0XFF707979),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR WIDGET
  // ------------------------------------------------------------------
  Widget _buildBottomNavBar() {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: myColors.bgCream,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0XFF356668).withValues(alpha: 0.06),
            offset: const Offset(0, -8),
            blurRadius: 40,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.grid_view_rounded, "Dashboard"),
          _buildNavItem(1, Icons.menu_book, "Guide"),
          _buildNavItem(2, Icons.person_rounded, "Profile"),
          _buildNavItem(3, Icons.settings_rounded, "Settings"),
        ],
      ),
    );
  }

  // Helper builder for Bottom Navigation Items (with responsive active indicator)
  Widget _buildNavItem(int index, IconData iconData, String label) {
    return Obx(() {
      final bool isActive = controller.selectedIndex.value == index;

      return GestureDetector(
        onTap: () => controller.onBottomNavItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? myColors.tealAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconData,
                color: isActive ? myColors.tealSecondary : myColors.textMuted,
                size: isActive ? 24 : 24,
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: myColors.tealSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
