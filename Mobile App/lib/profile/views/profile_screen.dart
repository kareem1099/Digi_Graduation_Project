import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaiten/contants/colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 128),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // 1. Header Section
          _buildHeader(),

          const SizedBox(height: 32),
          // 2. Main content container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Hero Section
                _buildProfileHero(),

                const SizedBox(height: 32),
                // Stats Bento Grid
                _buildStatsGrid(),

                const SizedBox(height: 32),
                // Detection History Section
                _buildDetectionHistory(),

                const SizedBox(height: 32),
                // Support Section Banner
                _buildSupportBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // HEADER SECTION (Same header as Home screen)
  // ------------------------------------------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                    "assets/images/logo-01.png",
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0XFFC0C8C8),
                width: 1.0,
              ),
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
  // PROFILE HERO SECTION
  // ------------------------------------------------------------------
  Widget _buildProfileHero() {
    return Center(
      child: SizedBox(
        width: 342,
        height: 180,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Profile Picture Circle with edit button overlay
            Positioned(
              top: 0,
              child: SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  children: [
                    // Outer Border
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: myColors.tealAccent,
                          width: 4,
                        ),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: myColors.tealAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: myColors.tealPrimary,
                          size: 56,
                        ),
                      ),
                    ),
                    // Camera / Edit overlay button
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 31,
                        height: 31,
                        decoration: BoxDecoration(
                          color: myColors.tealPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 10),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Parent Name Text
            Positioned(
              top: 128,
              child: Text(
                "Sarah Jenkins",
                style: GoogleFonts.quicksand(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: myColors.textDark,
                ),
              ),
            ),
            // Parent Category Text
            Positioned(
              top: 160,
              child: Text(
                "Parent Account",
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.14,
                  color: myColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // STATS BENTO GRID
  // ------------------------------------------------------------------
  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0XFF356668).withValues(alpha: 0.05),
                  offset: const Offset(0, 20),
                  blurRadius: 40,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: myColors.tealPrimary,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  "Active Since",
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: myColors.textMuted,
                  ),
                ),
                Text(
                  "Oct 2023",
                  style: GoogleFonts.quicksand(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: myColors.tealPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0XFF356668).withValues(alpha: 0.05),
                  offset: const Offset(0, 20),
                  blurRadius: 40,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0XFF525A92),
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  "Alerts Monitored",
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: myColors.textMuted,
                  ),
                ),
                Text(
                  "1,240",
                  style: GoogleFonts.quicksand(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0XFF525A92),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // DETECTION HISTORY LIST
  // ------------------------------------------------------------------
  Widget _buildDetectionHistory() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Detection History",
              style: GoogleFonts.quicksand(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: myColors.textDark,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                "Filter",
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.14,
                  color: myColors.tealPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            // Event 1: Sleep Pose
            _buildHistoryItem(
              title: "Sleep Pose",
              time: "10:30 AM",
              description: "Baby is resting comfortably on their back.",
              icon: Icons.hotel_rounded,
              iconBgColor: myColors.tealAccent,
              iconColor: myColors.tealPrimary,
            ),
            const SizedBox(height: 16),
            // Event 2: Meal
            _buildHistoryItem(
              title: "Feeding",
              time: "1:15 PM",
              description: "Scheduled afternoon feeding completed.",
              icon: Icons.restaurant_rounded,
              iconBgColor: myColors.lavenderAccent,
              iconColor: const Color(0XFF444C83),
            ),
            const SizedBox(height: 16),
            // Event 3: Cry Alert (Critical warning highlighted layout)
            _buildHistoryItem(
              title: "Cry Alert",
              time: "2:45 PM",
              description: "Noise detected; settled within 2 minutes.",
              icon: Icons.warning_amber_rounded,
              iconBgColor: const Color(0XFFFFDAD6),
              iconColor: const Color(0XFFBA1A1A),
              borderColor: const Color(0XFFBA1A1A),
            ),
            const SizedBox(height: 16),
            // Event 4: Movement
            _buildHistoryItem(
              title: "Movement",
              time: "4:00 PM",
              description: "Healthy activity levels during morning playtime.",
              icon: Icons.directions_run_rounded,
              iconBgColor: myColors.limeAccent,
              iconColor: const Color(0XFF575C40),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String time,
    required String description,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: borderColor != null
            ? Border(
                left: BorderSide(
                  color: borderColor,
                  width: 4,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0XFF356668).withValues(alpha: 0.05),
            offset: const Offset(0, 20),
            blurRadius: 40,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Event Icon Background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Event Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.14,
                        color: myColors.textDark,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: myColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: myColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0XFFC0C8C8),
            size: 12,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SUPPORT BANNER WIDGET
  // ------------------------------------------------------------------
  Widget _buildSupportBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: myColors.tealSecondary.withValues(alpha: 0.05),
        border: Border.all(
          color: myColors.tealSecondary.withValues(alpha: 0.1),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Need Help?",
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.14,
                    color: myColors.tealPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Contact our support team anytime.",
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: myColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 108,
            height: 56,
            decoration: BoxDecoration(
              color: myColors.tealPrimary,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(9999),
                onTap: () {},
                child: Center(
                  child: Text(
                    "Chat",
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
