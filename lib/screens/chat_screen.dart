import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_profile.dart';
import '../services/meme_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final UserProfile profile;

  const ChatScreen({
    super.key,
    required this.profile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final _chatService = ChatService();
  final _memeService = UserMemeInteractions();
  final _authService = AuthService();
  bool _canChat = false;
  bool _isLoading = true;
  String? _chatId;
  Timer? _expirationTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _expirationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Get or create chat ID
        _chatId = await _chatService.getChatId(
            currentUser.uid, widget.profile.userId);
        await _checkChatPermission();
        _startCleanupTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startCleanupTimer() {
    // Run cleanup every hour
    _expirationTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _chatService.cleanupExpiredMessages();
    });
  }

  Future<void> _checkChatPermission() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final otherUserLikedMyMeme = await _memeService.hasUserLikedMyMeme(
          currentUser.uid,
          widget.profile.userId,
        );
        final iLikedOtherUserMeme = await _memeService.hasUserLikedMyMeme(
          widget.profile.userId,
          currentUser.uid,
        );

        setState(() {
          _canChat = otherUserLikedMyMeme && iLikedOtherUserMeme;
        });

        if (_canChat && _chatId != null) {
          await _chatService.markChatAsRead(
            chatId: _chatId!,
            userId: currentUser.uid,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking chat permission: $e')),
        );
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_canChat || _chatId == null)
      return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      await _chatService.sendMessage(
        chatId: _chatId!,
        senderId: currentUser.uid,
        content: _messageController.text,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.profile.profileImage != null
                  ? NetworkImage(widget.profile.profileImage!)
                  : null,
              child: widget.profile.profileImage == null
                  ? Text(widget.profile.name[0])
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.profile.name),
                if (_chatId != null)
                  StreamBuilder<List<ChatMessage>>(
                    stream: _chatService.getChatMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox();
                      }
                      final messages = snapshot.data!;
                      final expiresAt = messages.first.expiresAt;
                      final remaining = expiresAt.difference(DateTime.now());

                      return Text(
                        'Messages expire in ${remaining.inHours}h ${remaining.inMinutes % 60}m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_canChat
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chat Locked',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can chat with ${widget.profile.name} once you both like each other\'s memes!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _chatId == null
                          ? const Center(child: Text('Chat not initialized'))
                          : StreamBuilder<List<ChatMessage>>(
                              stream: _chatService.getChatMessages(_chatId!),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                }

                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final messages = snapshot.data!;
                                return ListView.builder(
                                  reverse: true,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final message = messages[index];
                                    final isMe = message.senderId ==
                                        _authService.currentUser?.uid;

                                    return Align(
                                      alignment: isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.deepPurple
                                              : Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.content,
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatTime(message.timestamp),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isMe
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
