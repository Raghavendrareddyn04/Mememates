import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;
  bool _isInitialized = false;

  // Initialize encryption on constructor
  ChatService() {
    _initializeEncryption();
  }

  void _initializeEncryption() {
    if (_isInitialized) return;

    try {
      // Create a 256-bit (32 bytes) key using SHA-256
      final keyString = 'mememates_secure_key_32_bytes_123!';
      final keyBytes = sha256.convert(utf8.encode(keyString)).bytes;
      final keyUint8List = Uint8List.fromList(keyBytes);
      final key = encrypt.Key(keyUint8List);

      // Create a fixed IV from the first 16 bytes of the key
      _iv = encrypt.IV(Uint8List.fromList(keyBytes.sublist(0, 16)));

      _encrypter =
          encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      _isInitialized = true;
    } catch (e) {
      print('Error initializing encryption: $e');
      // Fallback to a proper 256-bit key if needed
      final fallbackKey = encrypt.Key.fromSecureRandom(32);
      _encrypter = encrypt.Encrypter(
          encrypt.AES(fallbackKey, mode: encrypt.AESMode.cbc));
      _iv = encrypt.IV.fromSecureRandom(16);
      _isInitialized = true;
    }
  }

  String _encryptMessage(String message) {
    if (!_isInitialized) {
      _initializeEncryption();
    }

    try {
      final encrypted = _encrypter.encrypt(message, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      return 'PLAIN:$message'; // Return plaintext with marker as fallback
    }
  }

  String _decryptMessage(String encryptedMessage) {
    if (!_isInitialized) {
      _initializeEncryption();
    }

    try {
      if (encryptedMessage.startsWith('PLAIN:')) {
        return encryptedMessage.substring(6); // Remove 'PLAIN:' prefix
      }

      final encrypted = encrypt.Encrypted.fromBase64(encryptedMessage);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('Decryption error: $e');
      return 'Unable to decrypt message'; // Return error message as fallback
    }
  }

  Future<String> getChatId(String userId1, String userId2) async {
    try {
      final sortedIds = [userId1, userId2]..sort();
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

      if (chatsQuery.docs.isEmpty) {
        return [];
      }

      final List<ChatPreview> chats = [];
      for (var doc in chatsQuery.docs) {
        final data = doc.data();
        final participants =
            List<String>.from(data['participants'] as List? ?? []);

        if (participants.isEmpty) continue;

        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) continue;

        final userDoc =
            await _firestore.collection('users').doc(otherUserId).get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data();
        if (userData == null) continue;

        final lastMessage = data['lastMessage'] as String? ?? '';
        final lastMessageTime = data['lastMessageTime'] as Timestamp?;
        final readBy = data['readBy'] as List?;

        chats.add(
          ChatPreview(
            chatId: doc.id,
            otherUserId: otherUserId,
            otherUserName: userData['name'] as String? ?? 'Unknown',
            otherUserProfileImage: userData['profileImage'] as String?,
            lastMessage:
                lastMessage.isEmpty ? '' : _decryptMessage(lastMessage),
            lastMessageTime: lastMessageTime?.toDate() ?? DateTime.now(),
            isRead: readBy?.contains(userId) ?? true,
            canMessage: data['canMessage'] as bool? ?? false,
          ),
        );
      }

      return chats;
    } catch (e) {
      print('Error loading chats: $e');
      return [];
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

      // First, check if the chat document exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Create the chat document if it doesn't exist
        await _firestore.collection('chats').doc(chatId).set({
          'participants': sortedIds,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'readBy': [],
          'canMessage': true, // Set to true immediately
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
          'lastViewed': {},
          'expiresAt': null,
        });
      } else {
        // Update existing chat document
        await _firestore.collection('chats').doc(chatId).update({
          'canMessage': true,
          'active': true,
        });
      }
    } catch (e) {
      print('Error enabling messaging: $e');
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
      final chatData = chatDoc.data();

      if (!(chatData?['canMessage'] as bool? ?? false)) {
        throw 'Messaging is not enabled for this chat';
      }

      final encryptedContent = _encryptMessage(content);

      final batch = _firestore.batch();
      final chatRef = _firestore.collection('chats').doc(chatId);

      batch.update(chatRef, {
        'lastMessage': encryptedContent,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'readBy': [senderId],
      });

      final messageRef = chatRef.collection('messages').doc();
      batch.set(messageRef, {
        'senderId': senderId,
        'content': encryptedContent,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [senderId],
        'expiresAt': DateTime.now().add(const Duration(days: 1)),
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
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final encryptedContent = data['content'] as String? ?? '';
        final timestamp = data['timestamp'] as Timestamp?;
        final expiresAt = data['expiresAt'] as Timestamp?;
        final readBy = data['readBy'] as List?;

        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'] as String? ?? '',
          content:
              encryptedContent.isEmpty ? '' : _decryptMessage(encryptedContent),
          timestamp: timestamp?.toDate() ?? DateTime.now(),
          readBy: List<String>.from(readBy ?? []),
          expiresAt: expiresAt?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> markChatAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      final batch = _firestore.batch();
      final chatRef = _firestore.collection('chats').doc(chatId);

      batch.update(chatRef, {
        'readBy': FieldValue.arrayUnion([userId]),
        'lastViewed.$userId': FieldValue.serverTimestamp(),
      });

      final unreadMessages = await chatRef
          .collection('messages')
          .where('readBy', arrayContains: userId, isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }

      await batch.commit();

      final chatDoc = await chatRef.get();
      final chatData = chatDoc.data();
      if (chatData == null) return;

      final participants =
          List<String>.from(chatData['participants'] as List? ?? []);
      final lastViewed = chatData['lastViewed'] as Map?;

      if (participants.isNotEmpty &&
          lastViewed != null &&
          participants
              .every((participant) => lastViewed.containsKey(participant))) {
        await chatRef.update({
          'expiresAt': DateTime.now().add(const Duration(days: 1)),
        });

        await cleanupExpiredMessages();
      }
    } catch (e) {
      throw 'Failed to mark chat as read: $e';
    }
  }

  Future<void> cleanupExpiredMessages() async {
    try {
      final now = DateTime.now();
      final expiredChatsQuery = await _firestore
          .collection('chats')
          .where('expiresAt', isLessThan: now)
          .get();

      for (var chatDoc in expiredChatsQuery.docs) {
        final batch = _firestore.batch();

        final messagesQuery =
            await chatDoc.reference.collection('messages').get();
        for (var messageDoc in messagesQuery.docs) {
          batch.delete(messageDoc.reference);
        }

        batch.update(chatDoc.reference, {
          'lastMessage': '',
          'lastMessageTime': null,
          'readBy': [],
          'expiresAt': null,
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
  final List<String> readBy;
  final DateTime expiresAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.readBy,
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
