import 'package:flutter/material.dart';
import 'package:flutter_auth/widgets/audius_player.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
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
  bool _canChat = false;
  bool _isLoading = true;
  String? _chatId;
  Timer? _expirationTimer;
  bool _isComposing = false;
  MemePost? _latestMeme;

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      return '?';
    }
    return name[0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadLatestMeme();
    _messageController.addListener(() {
      setState(() {
        _isComposing = _messageController.text.isNotEmpty;
      });
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
          _latestMeme = memes.first; // Get the most recent meme
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isLargeScreen = size.width > 1200;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: LoadingAnimation(
            message: "Loading your chat...",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleProfileTap,
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.profile.profileImage != null
                    ? NetworkImage(widget.profile.profileImage!)
                    : null,
                child: widget.profile.profileImage == null
                    ? Text(widget.profile.name[0])
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profile.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (!isSmallScreen)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildUserProfile(),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: const Text('Block User'),
                      onTap: () {
                        // Implement block functionality
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.report),
                      title: const Text('Report User'),
                      onTap: () {
                        // Implement report functionality
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.purple.shade900,
              Colors.pink.shade900,
            ],
          ),
        ),
        child: !_canChat
            ? _buildLockedChatView(isSmallScreen)
            : Row(
                children: [
                  if (isLargeScreen)
                    SizedBox(
                      width: 300,
                      child: _buildUserProfile(),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _chatId == null
                              ? const Center(
                                  child: Text('Chat not initialized'))
                              : _buildChatMessages(isSmallScreen),
                        ),
                        _buildMessageInput(isSmallScreen),
                      ],
                    ),
                  ),
                  if (isLargeScreen)
                    SizedBox(
                      width: 300,
                      child: _buildSharedContent(),
                    ),
                ],
              ),
      ),
      floatingActionButton: _isComposing
          ? FloatingActionButton(
              onPressed: _sendMessage,
              backgroundColor: Colors.pink,
              child: const Icon(Icons.send),
              heroTag: 'chat_send_button', // Add unique hero tag
            )
          : FloatingActionButton(
              onPressed: () {
                // Implement voice recording
              },
              backgroundColor: Colors.white.withOpacity(0.1),
              child: const Icon(Icons.mic),
              heroTag: 'chat_mic_button', // Add unique hero tag
            ),
    );
  }

  Widget _buildLockedChatView(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: isSmallScreen ? 48 : 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chat Locked',
              style: TextStyle(
                fontSize: isSmallScreen ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can chat with ${widget.profile.name} once you both like each other\'s memes!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isSmallScreen ? 16 : 18,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 32,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessages(bool isSmallScreen) {
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.getChatMessages(_chatId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: LoadingAnimation(
              message: "LOading your chat...",
            ),
          );
        }

        final messages = snapshot.data!;
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: isSmallScreen ? 48 : 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _authService.currentUser?.uid;
            final showTimestamp =
                index == 0 || messages[index - 1].senderId != message.senderId;

            return Column(
              children: [
                if (showTimestamp) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isSmallScreen
                          ? MediaQuery.of(context).size.width * 0.75
                          : 400,
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.pink.withOpacity(0.8)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isMe ? const Radius.circular(0) : null,
                          bottomLeft: !isMe ? const Radius.circular(0) : null,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.content,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatMessageTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  message.readBy.contains(widget.profile.userId)
                                      ? Icons.done_all
                                      : Icons.done,
                                  size: 12,
                                  color: message.readBy
                                          .contains(widget.profile.userId)
                                      ? Colors.blue
                                      : Colors.white.withOpacity(0.7),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              color: Colors.white,
              onPressed: () {
                // Implement emoji picker
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      color: Colors.white,
                      onPressed: () {
                        // Implement file attachment
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: _isComposing
                  ? IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.pink,
                      onPressed: _sendMessage,
                    )
                  : IconButton(
                      icon: const Icon(Icons.mic),
                      color: Colors.white,
                      onPressed: () {
                        // Implement voice recording
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: widget.profile.profileImage != null
                ? NetworkImage(widget.profile.profileImage!)
                : null,
            child: widget.profile.profileImage == null
                ? Text(
                    _getInitials(widget.profile.name),
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Age: ${widget.profile.age}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (widget.profile.audiusTrackId != null)
            AudiusPlayer(
              trackId: widget.profile.audiusTrackId!,
              title: widget.profile.trackTitle ?? '',
              artistName: widget.profile.artistName ?? '',
            ),
          const SizedBox(height: 16),
          const Text(
            'Mood Board',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.profile.moodBoard.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(widget.profile.moodBoard[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSharedContent() {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Shared Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSharedSection(
                  'Liked Memes',
                  const Icon(Icons.favorite, color: Colors.pink),
                  // Add shared memes here
                ),
                const SizedBox(height: 16),
                _buildSharedSection(
                  'Shared Music',
                  const Icon(Icons.music_note, color: Colors.pink),
                  // Add shared music here
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedSection(String title, Widget icon, [Widget? content]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (content != null) ...[
            const SizedBox(height: 16),
            content,
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
