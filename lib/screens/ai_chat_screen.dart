import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final controller = TextEditingController();
  final ai = AIService();

  List<Map<String, String>> chats = [];
  bool loading = false;

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
  }

  Widget bubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xff5146b8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef4ff),
      appBar: AppBar(
        title: const Text("SmartPay AI"),
        backgroundColor: const Color(0xff5146b8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (_, i) {
                final item = chats[i];

                return bubble(
                  item["role"] == "user",
                  item["message"] ?? "",
                );
              },
            ),
          ),

          if (loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: CircularProgressIndicator(),
            ),

          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Tanya soal keuangan atau penipuan...",
                      filled: true,
                      fillColor: const Color(0xfff4f6fb),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      loading ? Colors.grey : const Color(0xff5146b8),
                  child: IconButton(
                    onPressed: loading ? null : sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.white,
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