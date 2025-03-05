import 'package:flutter/material.dart';
import 'package:flutter_auth/widgets/loading_animation.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  final _userService = UserService();
  final _chatService = ChatService();
  bool _isLoading = true;
  List<ChatPreview> _chats = [];
  List<ChatPreview> _filteredChats = [];
  final _searchController = TextEditingController();
  bool _isSearching = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadChats();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        final chats = await _chatService.getChatsForUser(currentUser.uid);
        setState(() {
          _chats = chats;
          _filteredChats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading chats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChats = _chats;
      } else {
        _filteredChats = _chats.where((chat) {
          return chat.otherUserName
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              chat.lastMessage.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'MESSAGES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: LoadingAnimation(
                message: "Loading your conversations...",
              ),
            )
          : _buildChatList(),
    );
  }

  Widget _buildChatList() {
    if (_filteredChats.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _loadChats,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _filteredChats.length,
            itemBuilder: (context, index) {
              final chat = _filteredChats[index];
              return _buildChatTile(chat);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(ChatPreview chat) {
    return InkWell(
      onTap: () => _navigateToChat(chat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: chat.otherUserProfileImage != null
                        ? DecorationImage(
                            image: NetworkImage(chat.otherUserProfileImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: Colors.grey[800],
                  ),
                  child: chat.otherUserProfileImage == null
                      ? Center(
                          child: Text(
                            _getInitials(chat.otherUserName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!chat.isRead)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE94DAA),
                    ),
                    child: Center(
                      child: Text(
                        '3', // Replace with actual unread count from chat.unreadCount
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(chat.lastMessageTime),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No matching conversations' : 'No messages yet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching
                ? 'Try a different search term'
                : 'Start matching with people to chat!',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToChat(ChatPreview chat) async {
    if (!chat.isRead) {
      final currentUser = _userService.currentUser;
      if (currentUser != null) {
        await _chatService.markChatAsRead(
          chatId: chat.chatId,
          userId: currentUser.uid,
        );
      }
    }
    final userProfile = await _userService.getUserProfile(chat.otherUserId);
    if (userProfile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            profile: UserProfile(
              userId: chat.otherUserId,
              name: userProfile.name,
              age: userProfile.age,
              moodBoard: userProfile.moodBoard,
              audiusTrackId: userProfile.audiusTrackId,
              trackTitle: userProfile.trackTitle,
              artistName: userProfile.artistName,
              gender: userProfile.gender,
              preferredGender: userProfile.preferredGender,
              hasLikedMe: true,
              canMessage: true,
              profileImage: userProfile.profileImage,
              bio: userProfile.bio,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
