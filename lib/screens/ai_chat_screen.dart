import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final ai = AIService();

  List<Map<String, String>> chats = [];
  bool loading = false;

  final bgDark = const Color(0xff0F1020);
  final cardDark = const Color(0xff1A1B2E);
  final fieldDark = const Color(0xff25263A);
  final primary = const Color(0xff7C5CFF);
  final secondary = const Color(0xff00D1FF);

  @override
  void initState() {
    super.initState();

    chats.add({
      "role": "ai",
      "message":
          "Halo! Saya SmartPay AI. Kamu bisa tanya tentang budgeting, e-wallet, tabungan, investasi dasar, utang, cicilan, dana darurat, atau modus penipuan keuangan.",
    });
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty || loading) return;

    setState(() {
      chats.add({
        "role": "user",
        "message": text,
      });
      loading = true;
    });

    controller.clear();
    scrollToBottom();

    final historyForAI = chats.take(chats.length - 1).toList();

    final reply = await ai.askAI(
      message: text,
      history: historyForAI,
    );

    if (!mounted) return;

    setState(() {
      chats.add({
        "role": "ai",
        "message": reply,
      });
      loading = false;
    });

    scrollToBottom();
  }

  void sendQuickQuestion(String text) {
    controller.text = text;
    sendMessage();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  Widget bubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: primary.withOpacity(0.25),
              child: Icon(Icons.smart_toy, color: secondary, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 7),
              padding: const EdgeInsets.all(15),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          primary,
                          secondary.withOpacity(0.75),
                        ],
                      )
                    : null,
                color: isUser ? null : cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isUser ? 22 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 22),
                ),
                border: isUser ? null : Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? primary.withOpacity(0.22)
                        : Colors.black.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.white70,
                  height: 1.45,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: secondary.withOpacity(0.18),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget quickChip(String text, IconData icon) {
    return InkWell(
      onTap: loading ? null : () => sendQuickQuestion(text),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(right: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: secondary, size: 18),
            const SizedBox(width: 7),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primary.withOpacity(0.25),
            child: Icon(Icons.smart_toy, color: secondary, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 7),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              "SmartPay AI sedang mengetik...",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            const Color(0xff14162E),
            secondary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.16),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SmartPay AI Assistant",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Asisten keuangan, e-wallet, budgeting, dan anti penipuan",
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget inputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: cardDark,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.26),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Tanya soal keuangan...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: fieldDark,
                  prefixIcon: Icon(Icons.chat_bubble_outline, color: secondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: loading
                    ? null
                    : LinearGradient(colors: [primary, secondary]),
                color: loading ? Colors.grey : null,
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: loading ? null : sendMessage,
                icon: const Icon(Icons.send_rounded),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text("SmartPay AI"),
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          header(),

          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                quickChip("Atur uang mahasiswa", Icons.school),
                quickChip("Dana darurat", Icons.savings),
                quickChip("Investasi aman", Icons.trending_up),
                quickChip("Ciri penipuan", Icons.security),
                quickChip("Tips hemat", Icons.wallet),
              ],
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xff0F1020),
              ),
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                itemCount: chats.length + (loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (loading && i == chats.length) {
                    return typingBubble();
                  }

                  final item = chats[i];

                  return bubble(
                    item["role"] == "user",
                    item["message"] ?? "",
                  );
                },
              ),
            ),
          ),

          inputArea(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }
}