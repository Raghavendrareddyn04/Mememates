import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _encryptionKey = encrypt.Key.fromSecureRandom(32);
  final _iv = encrypt.IV.fromSecureRandom(16);

  // Encrypt message
  String _encryptMessage(String message) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    return encrypter.encrypt(message, iv: _iv).base64;
  }

  // Decrypt message
  String _decryptMessage(String encryptedMessage) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    return encrypter.decrypt64(encryptedMessage, iv: _iv);
  }

  // Create a new chat when someone likes a meme
  Future<void> createChatOnMemeLike(String memeId, String likerId, String memeOwnerId) async {
    try {
      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('participants', arrayContainsAny: [likerId, memeOwnerId])
          .where('active', isEqualTo: true)
          .get();

      if (existingChat.docs.isEmpty) {
        // Create new chat
        await _firestore.collection('chats').add({
          'participants': [likerId, memeOwnerId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'readBy': [],
          'canMessage': false,
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
        });
      }
    } catch (e) {
      throw 'Failed to create chat: $e';
    }
  }

  // Check and update messaging ability when there's a mutual like
  Future<void> checkAndEnableMessaging(String user1Id, String user2Id) async {
    try {
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContainsAny: [user1Id])
          .where('active', isEqualTo: true)
          .get();

      for (var doc in chatQuery.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(user2Id)) {
          await doc.reference.update({'canMessage': true});
          break;
        }
      }
    } catch (e) {
      throw 'Failed to enable messaging: $e';
    }
  }

  Future<List<ChatPreview>> getChatsForUser(String userId) async {
    try {
      // First query for active chats
      final chatsQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .where('active', isEqualTo: true)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final List<ChatPreview> chats = [];
      final List<Future<void>> userFetches = [];

      for (var doc in chatsQuery.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants']);
        final otherUserId = participants.firstWhere((participant) => participant != userId);

        // Create a Future for fetching user data
        userFetches.add(
          _firestore.collection('users').doc(otherUserId).get().then((userDoc) {
            if (userDoc.exists) {
              final otherUserData = userDoc.data()!;
              final lastMessage = data['lastMessage'] as String;
              chats.add(
                ChatPreview(
                  chatId: doc.id,
                  otherUserId: otherUserId,
                  otherUserName: otherUserData['name'] ?? 'Unknown',
                  otherUserProfileImage: otherUserData['profileImage'],
                  lastMessage: lastMessage.isNotEmpty ? _decryptMessage(lastMessage) : '',
                  lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
                  isRead: (data['readBy'] ?? []).contains(userId),
                  canMessage: data['canMessage'] ?? false,
                ),
              );
            }
          }),
        );
      }

      // Wait for all user data to be fetched
      await Future.wait(userFetches);

      // Sort chats by last message time
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      return chats;
    } catch (e) {
      throw 'Failed to load chats: $e';
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    try {
      // Check if messaging is enabled
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!(chatDoc.data()?['canMessage'] ?? false)) {
        throw 'Messaging is not enabled for this chat';
      }

      final encryptedContent = _encryptMessage(content);
      
      // Create a batch to update both the chat and add the message atomically
      final batch = _firestore.batch();
      
      // Update chat document
      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': encryptedContent,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'readBy': [senderId],
      });

      // Add message document
      final messageRef = chatRef.collection('messages').doc();
      batch.set(messageRef, {
        'senderId': senderId,
        'content': encryptedContent,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Commit the batch
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
            );
          }).toList();
        });
  }

  Future<void> markChatAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw 'Failed to mark chat as read: $e';
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'active': false,
      });
    } catch (e) {
      throw 'Failed to delete chat: $e';
    }
  }
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

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });
}