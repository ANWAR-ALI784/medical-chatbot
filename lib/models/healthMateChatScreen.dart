import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../pages/signup.dart';

class HealthMateChatScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  final User firebaseUser;

  const HealthMateChatScreen({
    required this.isDarkMode,
    required this.toggleTheme,
    required this.firebaseUser,
    Key? key,
  }) : super(key: key);

  @override
  State<HealthMateChatScreen> createState() => _HealthMateChatScreenState();
}

class _HealthMateChatScreenState extends State<HealthMateChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ImagePicker _picker = ImagePicker();

  final String apiKey = dotenv.env['GEMINI_API_KEY']!;

  String chatId = const Uuid().v4();
  bool _isLoading = false;
  XFile? _selectedImage;

  /// ============== HELPERS =============

  String cleanAiResponse(String text) {
    return text.replaceAll('**', '').replaceAll('#', '').trim();
  }

  /// ================= FIREBASE =================
  Stream<QuerySnapshot> get chatHistoryStream {
    return FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.firebaseUser.uid)
        .collection("chats")
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  Future<void> _saveMessage(String sender, String text, {String? imagePath}) async {
    final chatRef = FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.firebaseUser.uid)
        .collection("chats")
        .doc(chatId);

    String titleText = text.isNotEmpty ? text.split(" ").take(4).join(" ") : "Shared an image";

    await chatRef.set({
      "timestamp": FieldValue.serverTimestamp(),
      "title": titleText,
    }, SetOptions(merge: true));

    await chatRef.collection("messages").add({
      "sender": sender,
      "text": text,
      "imagePath": imagePath,
      "time": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadChat(String selectedChatId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.firebaseUser.uid)
        .collection("chats")
        .doc(selectedChatId)
        .collection("messages")
        .orderBy("time")
        .get();

    setState(() {
      chatId = selectedChatId;
      _messages.clear();
      for (var doc in snapshot.docs) {
        _messages.add({
          "sender": doc["sender"],
          "text": doc["text"],
          "imagePath": doc.data().containsKey("imagePath") ? doc["imagePath"] : null,
        });
      }
    });
    Navigator.pop(context);
  }

  void _createNewChat() {
    setState(() {
      chatId = const Uuid().v4();
      _messages.clear();
      _selectedImage = null;
    });
    Navigator.pop(context);
  }

  Future<void> _deleteChat(String id) async {
    await FirebaseFirestore.instance
        .collection("Users")
        .doc(widget.firebaseUser.uid)
        .collection("chats")
        .doc(id)
        .delete();
  }

  /// ================= IMAGE =================
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = picked);
  }

  /// ================= AI MESSAGE =================
  Future<void> sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty && _selectedImage == null) return;

    final String? imagePath = _selectedImage?.path;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': userMessage,
        'imagePath': imagePath,
      });
      _controller.clear();
      _selectedImage = null;
      _isLoading = true;
    });

    await _saveMessage('user', userMessage, imagePath: imagePath);

    final stopwatch = Stopwatch()..start();
    print("--- 🚀 Gemini Request Dispatched ---");

    try {
      // MANDATORY POLICY: Explicit system guardrails restricting execution to medical domains exclusively
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
            "CORE IDENTITY: You are HealthMate AI 🏥, a dedicated healthcare assistant. "
                "STRICT POLICIES:\n"
                "1. You are strictly permitted to discuss health, medical conditions, anatomy, first aid, drugs, symptoms, and lifestyle biology.\n"
                "2. If the user asks about ANYTHING outside of medicine (e.g., coding, mathematics, general knowledge, history, celebrity gossip, jokes, recipes, writing essays), you MUST strictly refuse to answer.\n"
                "3. When refusing, respond exactly with: 'I am designed only for medical and health inquiries. Please ask a health-related question.'\n"
                "4. Keep all valid medical responses ultra-short, highly condensed, to-the-point, and completely free of bold ** typography or # header markdown symbols.\n"
                "5. If a condition appears dangerous or critical, immediately advise them to seek professional medical attention."
        ),
      );

      final parts = <Part>[];
      if (userMessage.isNotEmpty) parts.add(TextPart(userMessage));
      if (imagePath != null) {
        final bytes = await File(imagePath).readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }

      // Append placeholder UI item for immediate text buffer allocation
      setState(() {
        _messages.add({'sender': 'bot', 'text': ''});
        _isLoading = false;
      });

      int botMessageIndex = _messages.length - 1;
      StringBuffer responseBuffer = StringBuffer();

      // EXECUTION: Fetch content stream to maximize speed metrics
      final responseStream = model.generateContentStream([Content.multi(parts)]);

      await for (final chunk in responseStream) {
        if (stopwatch.isRunning) {
          stopwatch.stop();
          print("⏱️ Perceived Latency (Time to First Word): ${stopwatch.elapsedMilliseconds} ms");
        }

        String cleanChunk = cleanAiResponse(chunk.text ?? "");
        responseBuffer.write(cleanChunk);

        setState(() {
          _messages[botMessageIndex]['text'] = responseBuffer.toString();
        });
      }

      await _saveMessage('bot', responseBuffer.toString());

    } on GenerativeAIException catch (geo) {
      stopwatch.stop();
      print("❌ Gemini Platform Overloaded: $geo");
      setState(() {
        _isLoading = false;
        if (_messages.isNotEmpty && _messages.last['text'] == '') {
          _messages.removeLast();
        }
        _messages.add({
          'sender': 'bot',
          'text': "🏥 Medical diagnostic servers are experiencing heavy traffic. Please resend your entry."
        });
      });
    } catch (e) {
      stopwatch.stop();
      print("❌ Local Handshake Execution Error: $e");
      setState(() {
        _isLoading = false;
        if (_messages.isNotEmpty && _messages.last['text'] == '') {
          _messages.removeLast();
        }
        _messages.add({'sender': 'bot', 'text': "⚠️ Connection exception encountered."});
      });
    }
  }

  /// ================= LOGOUT =================
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const Signup()), (route) => false);
  }

  /// ================= UI =================
  Widget _buildMessage(Map msg) {
    final isUser = msg["sender"] == "user";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (msg["imagePath"] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(msg["imagePath"]),
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (msg["text"] != null && msg["text"].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.teal
                    : (widget.isDarkMode ? Colors.grey[850] : Colors.grey[200]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 16),
                ),
              ),
              child: Text(
                msg["text"],
                style: TextStyle(
                  color: isUser ? Colors.white : (widget.isDarkMode ? Colors.white : Colors.black87),
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: const Text("HealthMate AI", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode), onPressed: widget.toggleTheme),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.firebaseUser.email?.substring(0, 1).toUpperCase() ?? "U",
                  style: const TextStyle(fontSize: 24, color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ),
              accountName: Text(widget.firebaseUser.displayName ?? "User"),
              accountEmail: Text(widget.firebaseUser.email ?? ""),
            ),
            ListTile(leading: const Icon(Icons.add), title: const Text("New Chat"), onTap: _createNewChat),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: chatHistoryStream,
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final chats = snap.data!.docs;
                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (_, i) {
                      final chat = chats[i];
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(chat["title"]),
                        onTap: () => _loadChat(chat.id),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteChat(chat.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildMessage(_messages[i]),
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Colors.teal, backgroundColor: Colors.transparent),
            ),

          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 100,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(_selectedImage!.path), width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0, top: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.camera_alt_outlined, color: Colors.teal), onPressed: _pickImage),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(hintText: "Ask HealthMate...", border: InputBorder.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  radius: 25,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: sendMessage),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}