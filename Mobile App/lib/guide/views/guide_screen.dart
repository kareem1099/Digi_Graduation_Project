import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaiten/contants/colors.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

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
                // Search Section
                _buildSearchSection(),
                
                const SizedBox(height: 32),
                // Featured Guide Card
                _buildFeaturedGuideCard(),

                const SizedBox(height: 32),
                // Categories Grid Section
                _buildCategoriesSection(),

                const SizedBox(height: 32),
                // Recent Updates Section
                _buildRecentUpdatesSection(),
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
  // SEARCH SECTION
  // ------------------------------------------------------------------
  Widget _buildSearchSection() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0XFFF5F4E8),
        borderRadius: BorderRadius.circular(32),
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 20, right: 12),
            child: Icon(
              Icons.search_rounded,
              color: Color(0XFF707979),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          hintText: "Search resources, tips, or guides...",
          hintStyle: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0XFFC0C8C8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        style: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: myColors.textDark,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // FEATURED GUIDE CARD WIDGET
  // ------------------------------------------------------------------
  Widget _buildFeaturedGuideCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: myColors.tealAccent.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category/Tag
          Text(
            "FEATURED GUIDE",
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
              color: myColors.tealPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Heading
          Text(
            "Newborn Care Basics",
            style: GoogleFonts.quicksand(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: myColors.tealSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            "Essential tips for the first few weeks of baby's life, from feeding to sleep schedules.",
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: myColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          // Action Button
          Container(
            width: 176,
            height: 48,
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
                    "Read Guide",
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Illustration Image container with shadow
          Container(
            width: double.infinity,
            height: 192,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 10),
                  blurRadius: 15,
                  spreadRadius: -3,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 6,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                "assets/images/featured_guide.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // CATEGORIES BENTO GRID WIDGET
  // ------------------------------------------------------------------
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Categories",
              style: GoogleFonts.quicksand(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: myColors.textDark,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                "See All",
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
        // Bento Card 1: Sleep Tips
        _buildCategoryCard(
          title: "Sleep Tips",
          subtitle: "Establish healthy sleep patterns and routines for your baby.",
          icon: Icons.nights_stay_rounded,
          iconBgColor: const Color(0XFFDFE0FF),
          iconColor: const Color(0XFF0C154B),
        ),
        const SizedBox(height: 16),
        // Bento Card 2: Feeding Basics
        _buildCategoryCard(
          title: "Feeding Basics",
          subtitle: "Guide to breastfeeding, formula feeding, and introducing solids.",
          icon: Icons.child_care_rounded,
          iconBgColor: const Color(0XFFB9ECEE),
          iconColor: const Color(0XFF002021),
        ),
        const SizedBox(height: 16),
        // Bento Card 3: Safe Play
        _buildCategoryCard(
          title: "Safe Play",
          subtitle: "Age-appropriate activities and toy safety guidelines.",
          icon: Icons.smart_toy_rounded,
          iconBgColor: const Color(0XFFE1E6C2),
          iconColor: const Color(0XFF1A1D07),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Icon Circular Container
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Heading
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: myColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: myColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // RECENT UPDATES SECTION WIDGET
  // ------------------------------------------------------------------
  Widget _buildRecentUpdatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Updates",
          style: GoogleFonts.quicksand(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: myColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        // Article 1: Non-Toxic Toys Guide
        _buildArticleCard(
          imageAsset: "assets/images/toys_guide.png",
          tagLabel: "TOYS",
          tagBgColor: myColors.tealAccent,
          tagTextColor: myColors.tealSecondary,
          timeText: "5 MIN READ",
          title: "Non-Toxic Toys Guide",
          description: "How to choose the safest materials for your baby's development and play.",
        ),
        const SizedBox(height: 16),
        // Article 2: Understanding Sleep Cycles
        _buildArticleCard(
          imageAsset: "assets/images/featured_guide.png", // Reuse the main featured baby illustration
          tagLabel: "SLEEP",
          tagBgColor: myColors.lavenderAccent,
          tagTextColor: const Color(0XFF444C83),
          timeText: "8 MIN READ",
          title: "Understanding Sleep Cycles",
          description: "A deep dive into why babies wake up and how to support their natural rhythms.",
        ),
      ],
    );
  }

  Widget _buildArticleCard({
    required String imageAsset,
    required String tagLabel,
    required Color tagBgColor,
    required Color tagTextColor,
    required String timeText,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Image
          SizedBox(
            height: 192,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBgColor,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        tagLabel,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tagTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Read Time text
                    Text(
                      timeText,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.14,
                        color: myColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Heading
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: myColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                // Description text
                Text(
                  description,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: myColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
