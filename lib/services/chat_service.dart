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

  ChatService() {
    _initializeEncryption();
  }

  void _initializeEncryption() {
    if (_isInitialized) return;

    try {
      final keyString = 'mememates_secure_key_32_bytes_123!';
      final keyBytes = sha256.convert(utf8.encode(keyString)).bytes;
      final keyUint8List = Uint8List.fromList(keyBytes);
      final key = encrypt.Key(keyUint8List);

      _iv = encrypt.IV(Uint8List.fromList(keyBytes.sublist(0, 16)));
      _encrypter =
          encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      _isInitialized = true;
    } catch (e) {
      print('Error initializing encryption: $e');
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
      return 'PLAIN:$message';
    }
  }

  String _decryptMessage(String encryptedMessage) {
    if (!_isInitialized) {
      _initializeEncryption();
    }

    try {
      if (encryptedMessage.startsWith('PLAIN:')) {
        return encryptedMessage.substring(6);
      }

      final encrypted = encrypt.Encrypted.fromBase64(encryptedMessage);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('Decryption error: $e');
      return 'Unable to decrypt message';
    }
  }

  Future<String> getChatId(String userId1, String userId2) async {
    try {
      final sortedIds = [userId1, userId2]..sort();
      final chatId = sortedIds.join('_');

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Check both connection and mutual meme likes
        final canChat = await _checkChatEligibility(userId1, userId2);

        await _firestore.collection('chats').doc(chatId).set({
          'participants': sortedIds,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'readBy': [],
          'canMessage': canChat,
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

  Future<bool> _checkChatEligibility(String userId1, String userId2) async {
    try {
      // Check connection status
      final connection1 = await _firestore
          .collection('users')
          .doc(userId1)
          .collection('connections')
          .doc(userId2)
          .get();

      final connection2 = await _firestore
          .collection('users')
          .doc(userId2)
          .collection('connections')
          .doc(userId1)
          .get();

      if (connection1.exists && connection2.exists) {
        return true;
      }

      // Check mutual meme likes
      final user1Memes = await _firestore
          .collection('memes')
          .where('userId', isEqualTo: userId1)
          .where('likedByUsers', arrayContains: userId2)
          .get();

      final user2Memes = await _firestore
          .collection('memes')
          .where('userId', isEqualTo: userId2)
          .where('likedByUsers', arrayContains: userId1)
          .get();

      return user1Memes.docs.isNotEmpty && user2Memes.docs.isNotEmpty;
    } catch (e) {
      print('Error checking chat eligibility: $e');
      return false;
    }
  }

  Future<void> checkAndEnableMessaging(String user1Id, String user2Id) async {
    try {
      final sortedIds = [user1Id, user2Id]..sort();
      final chatId = sortedIds.join('_');

      // Check eligibility first
      final canChat = await _checkChatEligibility(user1Id, user2Id);
      if (!canChat) {
        return; // Silently return instead of throwing an error
      }

      // Update or create chat document
      await _firestore.collection('chats').doc(chatId).set({
        'participants': sortedIds,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'readBy': [],
        'canMessage': true,
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
        'lastViewed': {},
        'expiresAt': null,
      }, SetOptions(merge: true));

      // Update connection documents if they exist
      final batch = _firestore.batch();

      final connection1Ref = _firestore
          .collection('users')
          .doc(user1Id)
          .collection('connections')
          .doc(user2Id);

      final connection2Ref = _firestore
          .collection('users')
          .doc(user2Id)
          .collection('connections')
          .doc(user1Id);

      final connection1 = await connection1Ref.get();
      final connection2 = await connection2Ref.get();

      if (connection1.exists && connection2.exists) {
        batch.update(connection1Ref, {'canMessage': true});
        batch.update(connection2Ref, {'canMessage': true});
        await batch.commit();
      }
    } catch (e) {
      print('Error enabling messaging: $e');
      // Don't rethrow the error, just log it
    }
  }

  Future<void> createChatOnMemeLike(
      String memeId, String likerId, String memeOwnerId) async {
    try {
      final sortedIds = [likerId, memeOwnerId]..sort();
      final chatId = sortedIds.join('_');

      // Check if chat already exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      // First check for mutual likes
      final hasLikerLikedOwnerMeme =
          await _checkChatEligibility(likerId, memeOwnerId);

      // Only create/update chat if it doesn't exist or messaging isn't enabled
      if (!chatDoc.exists || !(chatDoc.data()?['canMessage'] ?? false)) {
        // Create or update chat document with messaging enabled if there's a mutual like
        await _firestore.collection('chats').doc(chatId).set({
          'participants': sortedIds,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'readBy': [],
          'canMessage': hasLikerLikedOwnerMeme, // Set based on mutual likes
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
          'lastViewed': {},
          'expiresAt': null,
        }, SetOptions(merge: true));

        // If there's a mutual like, ensure connections are updated
        if (hasLikerLikedOwnerMeme) {
          // Update or create connections for both users
          final batch = _firestore.batch();

          batch.set(
              _firestore
                  .collection('users')
                  .doc(likerId)
                  .collection('connections')
                  .doc(memeOwnerId),
              {
                'userId': memeOwnerId,
                'canMessage': true,
                'connectedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));

          batch.set(
              _firestore
                  .collection('users')
                  .doc(memeOwnerId)
                  .collection('connections')
                  .doc(likerId),
              {
                'userId': likerId,
                'canMessage': true,
                'connectedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));

          await batch.commit();
        }
      }
    } catch (e) {
      throw 'Failed to create chat: $e';
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
      final processedUserIds = <String>{}; // Track processed users

      for (var doc in chatsQuery.docs) {
        final data = doc.data();
        final participants =
            List<String>.from(data['participants'] as List? ?? []);

        if (participants.isEmpty) continue;

        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        // Skip if we've already processed this user
        if (otherUserId.isEmpty || processedUserIds.contains(otherUserId))
          continue;
        processedUserIds.add(otherUserId);

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
