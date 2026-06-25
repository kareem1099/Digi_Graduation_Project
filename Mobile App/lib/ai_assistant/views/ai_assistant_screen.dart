import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kaiten/contants/colors.dart';
import '../controllers/ai_assistant_controller.dart';

class AIAssistantScreen extends GetView<AIAssistantController> {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: myColors.textDark,
          ),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: myColors.limeAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Color(0XFF575C40),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Food Assistant",
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: myColors.textDark,
                  ),
                ),
                Text(
                  "Nutrition Expert • Active",
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: myColors.tealPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0XFFEFEEE3), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Messages list
            Expanded(
              child: Obx(
                () => ListView.builder(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: controller.messages.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    return _buildChatBubble(message);
                  },
                ),
              ),
            ),

            // Typing Indicator
            Obx(
              () => controller.isTyping.value
                  ? Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            "Assistant is typing...",
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: myColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Suggestion Chips list
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = controller.suggestions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(
                        suggestion,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: myColors.tealSecondary,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0XFFE4E3D7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () => controller.sendMessage(suggestion),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Input Bar
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
                top: 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0XFFF5F4E8),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0XFF707979),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: controller.messageController,
                              onSubmitted: controller.sendMessage,
                              decoration: InputDecoration(
                                hintText: "Ask about baby food...",
                                hintStyle: GoogleFonts.beVietnamPro(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0XFFC0C8C8),
                                ),
                                border: InputBorder.none,
                              ),
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: myColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => controller.sendMessage(
                      controller.messageController.text,
                    ),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: myColors.tealPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: myColors.limeAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Color(0XFF575C40),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? myColors.tealPrimary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(isUser ? 24 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 24),
                ),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(
                            0XFF356668,
                          ).withValues(alpha: 0.03),
                          offset: const Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
              ),
              child: isUser
                  ? Text(
                      message.text,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                        color: isUser ? Colors.white : myColors.textDark,
                      ),
                    )
                  : MarkdownBody(
                      data: message.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: myColors.limeAccent,
                              width: 1,
                            ),
                          ),
                        ),
                        p: GoogleFonts.beVietnamPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                          color: myColors.textDark,
                        ),
                        h1: GoogleFonts.beVietnamPro(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: myColors.textDark,
                        ),
                        h2: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: myColors.textDark,
                        ),
                        h3: GoogleFonts.beVietnamPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: myColors.textDark,
                        ),
                        strong: GoogleFonts.beVietnamPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: myColors.textDark,
                        ),
                        em: GoogleFonts.beVietnamPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          color: myColors.textDark,
                        ),
                        code: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          backgroundColor: const Color(0XFFF0F0F0),
                          color: const Color(0XFF333333),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0XFFF5F4E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        blockquote: GoogleFonts.beVietnamPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: myColors.tealSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: myColors.limeAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        listBullet: GoogleFonts.beVietnamPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: myColors.textDark,
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: myColors.tealAccent.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: myColors.tealPrimary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
