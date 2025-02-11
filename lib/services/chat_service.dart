import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _encryptionKey = encrypt.Key.fromSecureRandom(32);
  final _iv = encrypt.IV.fromSecureRandom(16);

  String _encryptMessage(String message) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    return encrypter.encrypt(message, iv: _iv).base64;
  }

  String _decryptMessage(String encryptedMessage) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    return encrypter.decrypt64(encryptedMessage, iv: _iv);
  }

  Future<String> getChatId(String userId1, String userId2) async {
    try {
      // Sort user IDs to ensure consistent chat ID
      final sortedIds = [userId1, userId2]..sort();
      final chatId = sortedIds.join('_');

      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Create new chat
        await _firestore.collection('chats').doc(chatId).set({
          'participants': sortedIds,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'readBy': [],
          'canMessage': false,
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
          'lastViewed': {},
          'expiresAt': null,
        });
      }

      return chatId;
    } catch (e) {
      throw 'Failed to get chat ID: $e';
    }
  }

  Future<List<ChatPreview>> getChatsForUser(String userId) async {
    try {
      final chatsQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .where('active', isEqualTo: true)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final List<ChatPreview> chats = [];
      for (var doc in chatsQuery.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants']);
        final otherUserId = participants.firstWhere((id) => id != userId);

        // Get other user's profile
        final userDoc =
            await _firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final lastMessage = data['lastMessage'] as String? ?? '';

          chats.add(
            ChatPreview(
              chatId: doc.id,
              otherUserId: otherUserId,
              otherUserName: userData['name'] ?? 'Unknown',
              otherUserProfileImage: userData['profileImage'],
              lastMessage:
                  lastMessage.isNotEmpty ? _decryptMessage(lastMessage) : '',
              lastMessageTime:
                  (data['lastMessageTime'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
              isRead:
                  (data['readBy'] as List<dynamic>?)?.contains(userId) ?? true,
              canMessage: data['canMessage'] ?? false,
            ),
          );
        }
      }

      return chats;
    } catch (e) {
      throw 'Failed to load chats: $e';
    }
  }

  Future<void> createChatOnMemeLike(
      String memeId, String likerId, String memeOwnerId) async {
    try {
      final sortedIds = [likerId, memeOwnerId]..sort();
      final chatId = sortedIds.join('_');

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'participants': sortedIds,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'readBy': [],
          'canMessage': false,
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
          'lastViewed': {},
          'expiresAt': null,
        });
      }
    } catch (e) {
      throw 'Failed to create chat: $e';
    }
  }

  Future<void> checkAndEnableMessaging(String user1Id, String user2Id) async {
    try {
      final sortedIds = [user1Id, user2Id]..sort();
      final chatId = sortedIds.join('_');

      await _firestore
          .collection('chats')
          .doc(chatId)
          .update({'canMessage': true});
    } catch (e) {
      throw 'Failed to enable messaging: $e';
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!(chatDoc.data()?['canMessage'] ?? false)) {
        throw 'Messaging is not enabled for this chat';
      }

      final encryptedContent = _encryptMessage(content);
      final now = DateTime.now();

      final batch = _firestore.batch();
      final chatRef = _firestore.collection('chats').doc(chatId);

      // Update chat document
      batch.update(chatRef, {
        'lastMessage': encryptedContent,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'readBy': [senderId],
        'expiresAt': now.add(const Duration(days: 1)),
      });

      // Add message document
      final messageRef = chatRef.collection('messages').doc();
      batch.set(messageRef, {
        'senderId': senderId,
        'content': encryptedContent,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': now.add(const Duration(days: 1)),
      });

      await batch.commit();
    } catch (e) {
      throw 'Failed to send message: $e';
    }
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('expiresAt', isGreaterThan: DateTime.now())
        .orderBy('expiresAt', descending: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'],
          content: _decryptMessage(data['content']),
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          expiresAt: (data['expiresAt'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  Future<void> markChatAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final lastViewed =
          Map<String, dynamic>.from(chatDoc.data()?['lastViewed'] ?? {});
      lastViewed[userId] = FieldValue.serverTimestamp();

      await _firestore.collection('chats').doc(chatId).update({
        'readBy': FieldValue.arrayUnion([userId]),
        'lastViewed': lastViewed,
      });

      // Check if all participants have viewed the chat
      final participants =
          List<String>.from(chatDoc.data()?['participants'] ?? []);
      final allViewed = participants
          .every((participant) => lastViewed.containsKey(participant));

      if (allViewed) {
        // Set expiration to 24 hours from the last person's view
        await _firestore.collection('chats').doc(chatId).update({
          'expiresAt': DateTime.now().add(const Duration(days: 1)),
        });
      }
    } catch (e) {
      throw 'Failed to mark chat as read: $e';
    }
  }

  Future<void> cleanupExpiredMessages() async {
    try {
      final now = DateTime.now();
      final chatsQuery = await _firestore
          .collection('chats')
          .where('expiresAt', isLessThan: now)
          .get();

      for (var chatDoc in chatsQuery.docs) {
        // Delete expired messages
        final messagesQuery = await chatDoc.reference
            .collection('messages')
            .where('expiresAt', isLessThan: now)
            .get();

        final batch = _firestore.batch();
        for (var messageDoc in messagesQuery.docs) {
          batch.delete(messageDoc.reference);
        }

        // Update chat document
        batch.update(chatDoc.reference, {
          'lastMessage': '',
          'lastMessageTime': null,
          'readBy': [],
          'active': false,
        });

        await batch.commit();
      }
    } catch (e) {
      print('Error cleaning up expired messages: $e');
    }
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final DateTime expiresAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.expiresAt,
  });
}

class ChatPreview {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfileImage;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isRead;
  final bool canMessage;

  ChatPreview({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfileImage,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isRead,
    required this.canMessage,
  });
}
