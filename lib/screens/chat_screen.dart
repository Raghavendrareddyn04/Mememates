import 'package:flutter/material.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user_profile.dart';
import '../models/meme_post.dart';
import '../services/meme_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'meme_detail_screen.dart';

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
  final ScrollController _scrollController = ScrollController();
  final _chatService = ChatService();
  final _memeService = MemeService();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  bool _canChat = false;
  bool _isLoading = true;
  String? _chatId;
  Timer? _expirationTimer;
  MemePost? _latestMeme;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadLatestMeme();
    _messageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _expirationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLatestMeme() async {
    try {
      final memes =
          await _memeService.getUserMemes(widget.profile.userId).first;
      if (memes.isNotEmpty) {
        setState(() {
          _latestMeme = memes.first;
        });
      }
    } catch (e) {
      print('Error loading latest meme: $e');
    }
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final hasCurrentUserLikedOtherMemes =
            await _memeService.hasUserLikedMyMeme(
          widget.profile.userId,
          currentUser.uid,
        );

        final hasOtherUserLikedMyMemes = await _memeService.hasUserLikedMyMeme(
          currentUser.uid,
          widget.profile.userId,
        );

        final connection1 = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('connections')
            .doc(widget.profile.userId)
            .get();

        final connection2 = await _firestore
            .collection('users')
            .doc(widget.profile.userId)
            .collection('connections')
            .doc(currentUser.uid)
            .get();

        final areConnected = connection1.exists && connection2.exists;
        final canMessageFromConnections =
            connection1.data()?['canMessage'] == true &&
                connection2.data()?['canMessage'] == true;

        setState(() {
          _canChat =
              (hasCurrentUserLikedOtherMemes && hasOtherUserLikedMyMemes) ||
                  (areConnected && canMessageFromConnections);
        });

        if (_canChat) {
          _chatId = await _chatService.getChatId(
              currentUser.uid, widget.profile.userId);
          await _chatService.markChatAsRead(
            chatId: _chatId!,
            userId: currentUser.uid,
          );
          _startCleanupTimer();
        }
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
    _expirationTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _chatService.cleanupExpiredMessages();
    });
  }

  void _handleProfileTap() {
    if (_latestMeme != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MemeDetailScreen(meme: _latestMeme!),
        ),
      );
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_canChat || _chatId == null)
      return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final messageText = _messageController.text;
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        chatId: _chatId!,
        senderId: currentUser.uid,
        content: messageText,
      );
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: LoadingAnimation(
            message: "Loading your chat...",
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _handleProfileTap,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.profile.profileImage != null
                    ? NetworkImage(widget.profile.profileImage!)
                    : null,
                backgroundColor: Colors.grey[800],
                child: widget.profile.profileImage == null
                    ? Text(
                        widget.profile.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profile.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: !_canChat
          ? Center(
              child: Text(
                'Chat is locked',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _chatId == null
                      ? const Center(
                          child: Text(
                            'Chat not initialized',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : StreamBuilder<List<ChatMessage>>(
                          stream: _chatService.getChatMessages(_chatId!),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: LoadingAnimation(
                                  message: "Loading messages...",
                                ),
                              );
                            }

                            final messages = snapshot.data!;
                            if (messages.isEmpty) {
                              return Center(
                                child: Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isMe = message.senderId ==
                                    _authService.currentUser?.uid;

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Align(
                                        alignment: isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.75,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isMe
                                                    ? Colors.white
                                                    : const Color(
                                                        0xFFE94DAA), // Pink for received messages
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                message.content,
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.black
                                                      : Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                                right: 8,
                                                left: 8,
                                              ),
                                              child: Text(
                                                _formatMessageTime(
                                                    message.timestamp),
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 8 + MediaQuery.of(context).padding.bottom,
                  ),
                  color: Colors.black,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              hintText: 'Write a message',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE94DAA), // Pink send button
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
