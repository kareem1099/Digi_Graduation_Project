import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaiten/contants/colors.dart';
import '../../home/controllers/home_controller.dart';

class SettingsScreen extends GetView<HomeController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Add missing observables to controller dynamically if not already declared.
    // To ensure safety, we can define local Rx variables or declare them directly in the HomeController.
    // Let's create localized state controllers or use the controller.
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
          // 2. Settings main items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Section
                _buildSectionHeader("ACCOUNT"),
                const SizedBox(height: 16),
                _buildAccountCard(),

                const SizedBox(height: 32),
                // Notifications Section
                _buildSectionHeader("NOTIFICATIONS"),
                const SizedBox(height: 16),
                _buildNotificationsCard(),

                const SizedBox(height: 32),
                // Support Section
                _buildSectionHeader("SUPPORT"),
                const SizedBox(height: 16),
                _buildSupportCard(),

                const SizedBox(height: 32),
                // Logout Button
                _buildLogoutButton(),

                const SizedBox(height: 32),
                // Aesthetic Branding
                _buildBranding(),
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
  // SECTION HEADERS
  // ------------------------------------------------------------------
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
        color: myColors.textMuted,
      ),
    );
  }

  // ------------------------------------------------------------------
  // ACCOUNT CARD WIDGET
  // ------------------------------------------------------------------
  Widget _buildAccountCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0XFF356668).withValues(alpha: 0.04),
            offset: const Offset(0, 8),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            title: "Profile Details",
            subtitle: "Update your personal details",
            icon: Icons.person_outline_rounded,
            iconBgColor: const Color(0X33B8C0FF), // rgba(184, 192, 255, 0.3)
            iconColor: const Color(0XFF525A92),
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsItem(
            title: "Baby Profile",
            subtitle: "Manage baby information",
            icon: Icons.child_care_rounded,
            iconBgColor: const Color(0X33B8C0FF),
            iconColor: const Color(0XFF525A92),
            onTap: () {},
          ),
          _buildDivider(),
          Obx(() => _buildSettingsItem(
            title: "Baby's Age",
            subtitle: "Currently set to: ${controller.babyAge.value}",
            icon: Icons.cake_outlined,
            iconBgColor: const Color(0X33B8C0FF),
            iconColor: const Color(0XFF525A92),
            onTap: () => _showAgePickerBottomSheet(Get.context!),
          )),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // AGE PICKER BOTTOM SHEET SELECTOR
  // ------------------------------------------------------------------
  void _showAgePickerBottomSheet(BuildContext context) {
    // Generate list of age options: 1 to 11 months, then 1 to 7 years
    final List<String> ageOptions = [
      for (int i = 1; i <= 11; i++) "$i ${i == 1 ? 'Month' : 'Months'}",
      for (int i = 1; i <= 7; i++) "$i ${i == 1 ? 'Year' : 'Years'}",
    ];

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: myColors.bgCream,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0XFFE4E3D7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Select Baby's Age",
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: myColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Age range: 1 Month to 7 Years",
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: myColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                itemCount: ageOptions.length,
                itemBuilder: (context, index) {
                  final age = ageOptions[index];
                  return Obx(() {
                    final isSelected = controller.babyAge.value == age;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Material(
                        color: isSelected ? myColors.tealPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            controller.babyAge.value = age;
                            Get.back();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  age,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : myColors.textDark,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  // ------------------------------------------------------------------
  // NOTIFICATIONS CARD WIDGET
  // ------------------------------------------------------------------
  Widget _buildNotificationsCard() {
    // Declaring Rx variables locally in case we don't store them in controller,
    // but using RxBool from a standard GetX setup is clean.
    // Let's design it with an Obx showing toggle switch states. We will bind to local state or controller
    // if controller has them, otherwise fallback to standard stateful toggle.
    // Let's create custom switch UI to match Figma exactly!
    final RxBool isPush = true.obs;
    final RxBool isSound = false.obs;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0XFF356668).withValues(alpha: 0.04),
            offset: const Offset(0, 8),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(() => _buildSettingsToggleItem(
                title: "Push Notifications",
                subtitle: "Receive real-time alerts",
                icon: Icons.notifications_outlined,
                iconBgColor: const Color(0X33A8DADC), // rgba(168, 218, 220, 0.3)
                iconColor: myColors.tealPrimary,
                value: isPush.value,
                onChanged: (val) => isPush.value = val,
              )),
          _buildDivider(),
          Obx(() => _buildSettingsToggleItem(
                title: "Sound Alerts",
                subtitle: "Play audio for critical warnings",
                icon: Icons.volume_up_outlined,
                iconBgColor: const Color(0X33A8DADC),
                iconColor: myColors.tealPrimary,
                value: isSound.value,
                onChanged: (val) => isSound.value = val,
              )),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SUPPORT CARD WIDGET
  // ------------------------------------------------------------------
  Widget _buildSupportCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0XFF356668).withValues(alpha: 0.04),
            offset: const Offset(0, 8),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            title: "Help Center",
            subtitle: "Read FAQs and guides",
            icon: Icons.help_outline_rounded,
            iconBgColor: const Color(0X33D0D4B1), // rgba(208, 212, 177, 0.3)
            iconColor: const Color(0XFF5C6145),
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsItem(
            title: "Contact Us",
            subtitle: "Get in touch with support",
            icon: Icons.mail_outline_rounded,
            iconBgColor: const Color(0X33D0D4B1),
            iconColor: const Color(0XFF5C6145),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // LOGOUT BUTTON WIDGET
  // ------------------------------------------------------------------
  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0XFFFFDAD6).withValues(alpha: 0.2),
        border: Border.all(
          color: const Color(0XFFFFDAD6).withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Color(0XFFBA1A1A),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Log Out",
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0XFFBA1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // BRANDING WIDGET
  // ------------------------------------------------------------------
  Widget _buildBranding() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "KAITEN",
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.6,
              color: myColors.tealPrimary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Version 1.0.0 (42)",
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0XFF707979).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // Divider helper
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 1,
        color: const Color(0XFFEFEEE3),
      ),
    );
  }

  // Settings action list item builder
  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: myColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0XFF707979),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Color(0XFFC0C8C8),
        size: 12,
      ),
    );
  }

  // Settings toggle list item builder
  Widget _buildSettingsToggleItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
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
      title: Text(
        title,
        style: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: myColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0XFF707979),
        ),
      ),
      trailing: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 24,
          decoration: BoxDecoration(
            color: value ? myColors.tealPrimary : const Color(0XFFE4E3D7),
            borderRadius: BorderRadius.circular(9999),
          ),
          padding: const EdgeInsets.all(2),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: value ? Colors.white : const Color(0XFFD1D5DB),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
