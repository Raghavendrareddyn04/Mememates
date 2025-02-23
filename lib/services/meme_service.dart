import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_auth/models/user_profile.dart';
import 'package:flutter_auth/services/notification_service.dart';
import '../models/meme_post.dart';
import 'cloudinary_service.dart';
import 'chat_service.dart';

class MemeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();

  Future<String?> getConnectionRequestStatus(
    String senderId,
    String receiverId,
  ) async {
    try {
      // Check both directions for connection requests
      final request1 = await _firestore
          .collection('connection_requests')
          .doc('${senderId}_${receiverId}')
          .get();

      final request2 = await _firestore
          .collection('connection_requests')
          .doc('${receiverId}_${senderId}')
          .get();

      // Check connections collection for both users
      final connection1 = await _firestore
          .collection('users')
          .doc(senderId)
          .collection('connections')
          .doc(receiverId)
          .get();

      final connection2 = await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('connections')
          .doc(senderId)
          .get();

      // If there's an active connection between users
      if (connection1.exists && connection2.exists) {
        return 'accepted';
      }

      // Check for pending requests in either direction
      if (request1.exists && request1.data()?['status'] == 'pending') {
        return 'pending';
      }
      if (request2.exists && request2.data()?['status'] == 'pending') {
        return 'pending';
      }

      return null;
    } catch (e) {
      print('Error getting connection request status: $e');
      return null;
    }
  }

  Future<void> sendConnectionRequest(
    String senderId,
    String receiverId,
  ) async {
    try {
      // Check existing connection status first
      final status = await getConnectionRequestStatus(senderId, receiverId);
      if (status != null) {
        throw 'Connection request already exists or users are already connected';
      }

      // Get sender's name for notification
      final senderDoc =
          await _firestore.collection('users').doc(senderId).get();
      if (!senderDoc.exists) {
        throw 'Sender not found';
      }
      final senderName = senderDoc.data()?['name'] ?? 'Someone';

      final requestId = '${senderId}_${receiverId}';

      // Create connection request
      await _firestore.collection('connection_requests').doc(requestId).set({
        'senderId': senderId,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'senderName': senderName,
      });

      // Send notification to receiver
      await _notificationService.handleConnectionRequest(
        receiverId: receiverId,
        senderName: senderName,
        isAccepted: false,
        requestId: requestId,
        senderId: senderId,
      );
    } catch (e) {
      print('Error sending connection request: $e');
      rethrow;
    }
  }

  Future<void> handleConnectionRequest(
    String requestId,
    String status,
  ) async {
    try {
      // Get request data first
      final requestDoc = await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw 'Connection request not found';
      }

      final data = requestDoc.data()!;
      if (data['status'] != 'pending') {
        throw 'Request has already been handled';
      }

      final senderId = data['senderId'] as String;
      final receiverId = data['receiverId'] as String;
      final senderName = data['senderName'] as String;

      // Get user data
      final receiverDoc =
          await _firestore.collection('users').doc(receiverId).get();
      final senderDoc =
          await _firestore.collection('users').doc(senderId).get();

      if (!receiverDoc.exists || !senderDoc.exists) {
        throw 'User data not found';
      }

      final receiverData = receiverDoc.data()!;
      final senderData = senderDoc.data()!;

      final receiverName = receiverData['name'] ?? 'Someone';
      final receiverProfileImage = receiverData['profileImage'];
      final senderProfileImage = senderData['profileImage'];

      final batch = _firestore.batch();

      // Update request status
      batch.update(
        _firestore.collection('connection_requests').doc(requestId),
        {
          'status': status,
          'respondedAt': FieldValue.serverTimestamp(),
        },
      );

      // Also update the reverse request if it exists
      final reverseRequestId = '${receiverId}_${senderId}';
      final reverseRequestDoc = await _firestore
          .collection('connection_requests')
          .doc(reverseRequestId)
          .get();

      if (reverseRequestDoc.exists) {
        batch.update(
          _firestore.collection('connection_requests').doc(reverseRequestId),
          {
            'status': status,
            'respondedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      if (status == 'accepted') {
        final now = Timestamp.now();

        // Create connection for sender
        batch.set(
          _firestore
              .collection('users')
              .doc(senderId)
              .collection('connections')
              .doc(receiverId),
          {
            'userId': receiverId,
            'userName': receiverName,
            'profileImage': receiverProfileImage,
            'connectedAt': now,
            'canMessage': true,
          },
        );

        // Create connection for receiver
        batch.set(
          _firestore
              .collection('users')
              .doc(receiverId)
              .collection('connections')
              .doc(senderId),
          {
            'userId': senderId,
            'userName': senderName,
            'profileImage': senderProfileImage,
            'connectedAt': now,
            'canMessage': true,
          },
        );

        // Create or update chat document
        batch.set(
          _firestore.collection('chats').doc('${senderId}_${receiverId}'),
          {
            'participants': [senderId, receiverId],
            'lastMessage': '',
            'lastMessageTime': now,
            'readBy': [],
            'canMessage': true,
            'active': true,
            'createdAt': now,
            'lastViewed': {},
            'expiresAt': null,
          },
          SetOptions(merge: true),
        );
      }

      // Commit all the batch operations
      await batch.commit();

      // Handle post-batch operations if request was accepted
      if (status == 'accepted') {
        // Create chat and enable messaging
        final chatId = await _chatService.getChatId(senderId, receiverId);
        await _chatService.checkAndEnableMessaging(senderId, receiverId);

        // Create notifications
        await _notificationService.createNotification(
          userId: senderId,
          title: 'Connection Accepted! 🎉',
          message: '$receiverName accepted your connection request!',
          type: NotificationType.connection,
          senderId: receiverId,
          receiverId: senderId,
          relatedId: chatId,
        );

        await _notificationService.createNotification(
          userId: receiverId,
          title: 'Connection Established! 🤝',
          message: 'You are now connected with $senderName!',
          type: NotificationType.connection,
          senderId: senderId,
          receiverId: receiverId,
          relatedId: chatId,
        );
      }
    } catch (e) {
      print('Error handling connection request: $e');
      rethrow;
    }
  }

  // Post a video meme
  Future<void> postVideo({
    required String userId,
    required String userName,
    required String videoPath,
    required String caption,
    String? thumbnailPath,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userProfileImage = userDoc.data()?['profileImage'] as String?;
      final lastPosted = userDoc.data()?['lastPosted'] as Timestamp?;
      final currentStreak = userDoc.data()?['memeStreak'] ?? 0;

      // Calculate streak
      int newStreak = currentStreak;
      if (lastPosted != null) {
        final difference = DateTime.now().difference(lastPosted.toDate());
        if (difference.inDays == 1) {
          newStreak++;
        } else if (difference.inDays > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      // Upload video and thumbnail
      final videoUrl = await _cloudinaryService.uploadVideo(videoPath);
      String? thumbnailUrl;
      if (thumbnailPath != null) {
        thumbnailUrl = await _cloudinaryService.uploadImage(thumbnailPath);
      }

      // Create meme document
      final memeRef = await _firestore.collection('memes').add({
        'userId': userId,
        'userName': userName,
        'memeUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'isVideo': true,
        'createdAt': FieldValue.serverTimestamp(),
        'likedByUsers': [],
        'passedByUsers': [],
        'userProfileImage': userProfileImage,
      });

      // Update user's streak and last posted time
      await _firestore.collection('users').doc(userId).update({
        'lastPosted': FieldValue.serverTimestamp(),
        'memeStreak': newStreak,
        'postedMemes': FieldValue.arrayUnion([memeRef.id])
      });
    } catch (e) {
      throw 'Failed to post video meme: $e';
    }
  }

  // Post a new meme and update streak
  Future<void> postMeme({
    required String userId,
    required String userName,
    required String imagePath,
    required String caption,
    String? videoId,
    String? videoTitle,
    String? artistName,
    String? topText,
    String? bottomText,
    Color? textColor,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userProfileImage = userDoc.data()?['profileImage'] as String?;
      final lastPosted = userDoc.data()?['lastPosted'] as Timestamp?;
      final currentStreak = userDoc.data()?['memeStreak'] ?? 0;

      // Calculate streak
      int newStreak = currentStreak;
      if (lastPosted != null) {
        final difference = DateTime.now().difference(lastPosted.toDate());
        if (difference.inDays == 1) {
          newStreak++;
        } else if (difference.inDays > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      // Convert color to hex string
      String textColorHex = 'co_rgb:1_1_1'; // Default white
      if (textColor != null) {
        textColorHex =
            'co_rgb:${(textColor.red / 255).toStringAsFixed(2)}_${(textColor.green / 255).toStringAsFixed(2)}_${(textColor.blue / 255).toStringAsFixed(2)}';
      }

      // Upload image with text overlays if provided
      String memeUrl;
      if ((topText != null && topText.isNotEmpty) ||
          (bottomText != null && bottomText.isNotEmpty)) {
        final List<String> transformations = [];

        // Add top text with color and position
        if (topText != null && topText.isNotEmpty) {
          final encodedText = Uri.encodeComponent(topText);
          transformations.add(
            'l_text:Arial_70_bold:$encodedText/$textColorHex/g_north,y_50/fl_layer_apply/c_scale,w_0.9',
          );
        }

        // Add bottom text with color and position
        if (bottomText != null && bottomText.isNotEmpty) {
          final encodedText = Uri.encodeComponent(bottomText);
          transformations.add(
            'l_text:Arial_70_bold:$encodedText/$textColorHex/g_south,y_50/fl_layer_apply/c_scale,w_0.9',
          );
        }

        // Add stroke to make text more visible
        transformations.add('e_outline:10');

        memeUrl = await _cloudinaryService.uploadImageWithTransformations(
          imagePath,
          transformations,
        );
      } else {
        memeUrl = await _cloudinaryService.uploadImage(imagePath);
      }

      // Create meme document
      final memeRef = await _firestore.collection('memes').add({
        'userId': userId,
        'userName': userName,
        'memeUrl': memeUrl,
        'caption': caption,
        'videoId': videoId,
        'videoTitle': videoTitle,
        'artistName': artistName,
        'topText': topText,
        'bottomText': bottomText,
        'createdAt': FieldValue.serverTimestamp(),
        'likedByUsers': [],
        'passedByUsers': [],
        'userProfileImage': userProfileImage,
        'isVideo': false,
      });

      // Update user's streak and last posted time
      await _firestore.collection('users').doc(userId).update({
        'lastPosted': FieldValue.serverTimestamp(),
        'memeStreak': newStreak,
        'postedMemes': FieldValue.arrayUnion([memeRef.id])
      });
    } catch (e) {
      throw 'Failed to post meme: $e';
    }
  }

  // Get meme feed for a user (excluding their own memes and liked/passed memes)
  Stream<List<MemePost>> getMemesFeed(
    String userId, {
    int? minAge,
    int? maxAge,
    String? preferredGender,
  }) {
    return _firestore
        .collection('memes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<MemePost> memes = [];
      final userDoc = await _firestore.collection('users').doc(userId).get();

      // Get user's liked and passed memes
      final likedMemeIds =
          List<String>.from(userDoc.data()?['likedMemes'] ?? []);
      final passedMemeIds =
          List<String>.from(userDoc.data()?['passedMemes'] ?? []);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final memeId = doc.id;
        final postUserId = data['userId'] as String;

        // Skip if it's the user's own meme or if they've already interacted with it
        if (postUserId == userId ||
            likedMemeIds.contains(memeId) ||
            passedMemeIds.contains(memeId)) {
          continue;
        }

        // Get poster's profile for filtering
        final posterDoc =
            await _firestore.collection('users').doc(postUserId).get();
        if (!posterDoc.exists) continue;

        final posterData = posterDoc.data()!;
        final posterAge = posterData['age'] as int?;
        final posterGender = posterData['gender'] as String?;

        // Apply age and gender filters if specified
        if (minAge != null && maxAge != null && posterAge != null) {
          if (posterAge < minAge || posterAge > maxAge) continue;
        }

        if (preferredGender != null &&
            preferredGender != 'All' &&
            posterGender != preferredGender) {
          continue;
        }

        memes.add(MemePost(
          id: memeId,
          userId: postUserId,
          userName: data['userName'] ?? '',
          memeUrl: data['memeUrl'] ?? '',
          caption: data['caption'] ?? '',
          videoId: data['videoId'],
          videoTitle: data['videoTitle'],
          artistName: data['artistName'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
          passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
          userProfileImage: data['userProfileImage'],
        ));
      }

      return memes;
    });
  }

  // Like meme and store in user's liked memes
  Future<void> likeMeme(String memeId, String userId) async {
    try {
      // Use transaction for atomic operations
      await _firestore.runTransaction((transaction) async {
        final memeRef = _firestore.collection('memes').doc(memeId);
        final userRef = _firestore.collection('users').doc(userId);

        final memeDoc = await transaction.get(memeRef);
        if (!memeDoc.exists) {
          throw 'Meme not found';
        }

        final memeData = memeDoc.data()!;
        final memeOwnerId = memeData['userId'] as String;

        // Don't allow self-likes
        if (memeOwnerId == userId) {
          throw 'Cannot like your own meme';
        }

        // Check if already liked
        final likedByUsers = List<String>.from(memeData['likedByUsers'] ?? []);
        if (likedByUsers.contains(userId)) {
          throw 'Meme already liked';
        }

        // Update meme document
        transaction.update(memeRef, {
          'likedByUsers': FieldValue.arrayUnion([userId]),
        });

        // Update user's liked memes
        transaction.update(userRef, {
          'likedMemes': FieldValue.arrayUnion([memeId])
        });

        // Get user name for notification
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userName = userDoc.data()?['name'] ?? 'Someone';

        // Create notification
        await _notificationService.handleMemeInteraction(
          memeOwnerId: memeOwnerId,
          interactorName: userName,
          isLike: true,
          memeId: memeId,
        );

        // Check for mutual like and create vibe match if needed
        final hasOtherUserLikedMyMeme =
            await hasUserLikedMyMeme(userId, memeOwnerId);
        if (hasOtherUserLikedMyMeme) {
          await _notificationService.handleVibeMatch(memeOwnerId, userName);

          // Get meme owner's name and notify the current user
          final ownerDoc =
              await _firestore.collection('users').doc(memeOwnerId).get();
          final ownerName = ownerDoc.data()?['name'] ?? 'Someone';
          await _notificationService.handleVibeMatch(userId, ownerName);
        }
      });
    } catch (e) {
      print('Error liking meme: $e');
      rethrow;
    }
  }

  // Pass meme and store in user's passed memes
  Future<void> passMeme(String memeId, String userId) async {
    try {
      final batch = _firestore.batch();
      final memeRef = _firestore.collection('memes').doc(memeId);
      final userRef = _firestore.collection('users').doc(userId);

      batch.update(memeRef, {
        'passedByUsers': FieldValue.arrayUnion([userId]),
      });

      batch.update(userRef, {
        'passedMemes': FieldValue.arrayUnion([memeId])
      });

      await batch.commit();
    } catch (e) {
      throw 'Failed to pass meme: $e';
    }
  }

  // Get user's streak info with timer
  Future<Map<String, dynamic>> getUserStreakInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final lastPosted = userDoc.data()?['lastPosted'] as Timestamp?;
      final currentStreak = userDoc.data()?['memeStreak'] ?? 0;

      final now = DateTime.now();
      final lastPostDate = lastPosted?.toDate() ?? now;
      final difference = now.difference(lastPostDate);

      // Calculate hours remaining in the day
      final hoursRemaining = 24 - difference.inHours;

      // Check if streak is still active
      final isStreakActive = difference.inHours < 24;

      // If more than 24 hours have passed, streak should be reset
      if (!isStreakActive && currentStreak > 0) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'memeStreak': 0});
        return {
          'streak': 0,
          'lastPosted': lastPosted,
          'hoursRemaining': 0,
          'isStreakActive': false
        };
      }

      return {
        'streak': currentStreak,
        'lastPosted': lastPosted,
        'hoursRemaining': hoursRemaining,
        'isStreakActive': isStreakActive
      };
    } catch (e) {
      throw 'Failed to get streak info: $e';
    }
  }

  // Get user's memes
  Stream<List<MemePost>> getUserMemes(String userId) {
    return _firestore
        .collection('memes')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return MemePost(
                id: doc.id,
                userId: data['userId'],
                userName: data['userName'] ?? '',
                memeUrl: data['memeUrl'] ?? '',
                caption: data['caption'] ?? '',
                videoId: data['videoId'],
                videoTitle: data['videoTitle'],
                artistName: data['artistName'],
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
                passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
                userProfileImage: data['userProfileImage'],
              );
            }).toList());
  }

  // Get user's liked memes
  Future<List<MemePost>> getLikedMemes(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final likedMemeIds =
          List<String>.from(userDoc.data()?['likedMemes'] ?? []);

      final memes = <MemePost>[];
      for (final memeId in likedMemeIds) {
        final memeDoc = await _firestore.collection('memes').doc(memeId).get();
        if (memeDoc.exists) {
          final data = memeDoc.data()!;
          memes.add(MemePost(
            id: memeDoc.id,
            userId: data['userId'],
            userName: data['userName'] ?? '',
            memeUrl: data['memeUrl'] ?? '',
            caption: data['caption'] ?? '',
            videoId: data['videoId'],
            videoTitle: data['videoTitle'],
            artistName: data['artistName'],
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
            passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
            userProfileImage: data['userProfileImage'],
          ));
        }
      }
      return memes;
    } catch (e) {
      throw 'Failed to get liked memes: $e';
    }
  }

  // Remove meme from liked memes
  Future<void> removeLikedMeme(String memeId, String userId) async {
    try {
      final batch = _firestore.batch();
      final memeRef = _firestore.collection('memes').doc(memeId);
      final userRef = _firestore.collection('users').doc(userId);

      batch.update(memeRef, {
        'likedByUsers': FieldValue.arrayRemove([userId]),
      });

      batch.update(userRef, {
        'likedMemes': FieldValue.arrayRemove([memeId])
      });

      await batch.commit();
    } catch (e) {
      throw 'Failed to remove liked meme: $e';
    }
  }

  // Get mutual likes for vibe matches
  Future<List<UserProfile>> getMutualLikes(String userId) async {
    try {
      // Get users who liked my memes
      final myMemesQuery = await _firestore
          .collection('memes')
          .where('userId', isEqualTo: userId)
          .get();

      final likedByUsers = <String>{};
      for (var doc in myMemesQuery.docs) {
        final likes = List<String>.from(doc.data()['likedByUsers'] ?? []);
        likedByUsers.addAll(likes);
      }

      // Get users whose memes I liked
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final myLikedMemes =
          List<String>.from(userDoc.data()?['likedMemes'] ?? []);

      final iLikedUsers = <String>{};
      for (final memeId in myLikedMemes) {
        final memeDoc = await _firestore.collection('memes').doc(memeId).get();
        if (memeDoc.exists) {
          iLikedUsers.add(memeDoc.data()!['userId'] as String);
        }
      }

      // Find mutual likes
      final mutualLikes = likedByUsers.intersection(iLikedUsers);

      // Get user profiles for mutual likes
      final List<UserProfile> matches = [];
      for (var matchId in mutualLikes) {
        final userDoc = await _firestore.collection('users').doc(matchId).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          matches.add(UserProfile(
            userId: matchId,
            name: data['name'] ?? '',
            age: data['age'] ?? 0,
            moodBoard: List<String>.from(data['moodBoardImages'] ?? []),
            artistName: data['artistName'] ?? '',
            trackTitle: data['songTitle'] ?? '',
            gender: data['gender'] ?? '',
            preferredGender: data['preferredGender'] ?? '',
            hasLikedMe: true,
            canMessage: true,
            profileImage: data['profileImage'],
          ));
        }
      }

      return matches;
    } catch (e) {
      throw 'Failed to get mutual likes: $e';
    }
  }

  // Background processing for like
  Future<void> _handleLikeBackground(
      String memeId, String userId, String memeOwnerId) async {
    try {
      // Get current user's name
      final currentUserDoc =
          await _firestore.collection('users').doc(userId).get();
      final currentUserName = currentUserDoc.data()?['name'] ?? 'Someone';

      // Create chat entry
      await _chatService.createChatOnMemeLike(memeId, userId, memeOwnerId);

      // Send notification for meme like
      await _notificationService.handleMemeInteraction(
        memeOwnerId: memeOwnerId,
        interactorName: currentUserName,
        isLike: true,
      );

      // Check for mutual like
      final hasOtherUserLikedMyMeme =
          await hasUserLikedMyMeme(userId, memeOwnerId);
      if (hasOtherUserLikedMyMeme) {
        // Enable messaging
        await _chatService.checkAndEnableMessaging(userId, memeOwnerId);

        // Get other user's name
        final ownerDoc =
            await _firestore.collection('users').doc(memeOwnerId).get();
        final ownerName = ownerDoc.data()?['name'] ?? 'Someone';

        // Send vibe match notifications to both users
        await _notificationService.handleVibeMatch(
            memeOwnerId, currentUserName);
        await _notificationService.handleVibeMatch(userId, ownerName);
      }
    } catch (e) {
      print('Background like processing error: $e');
    }
  }

  Future<bool> hasUserLikedMyMeme(String myUserId, String otherUserId) async {
    final querySnapshot = await _firestore
        .collection('memes')
        .where('userId', isEqualTo: myUserId)
        .where('likedByUsers', arrayContains: otherUserId)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Add method for handling mood board interactions
  Future<void> handleMoodBoardInteraction({
    required String boardOwnerId,
    required String interactorId,
    required bool isLike,
  }) async {
    try {
      final interactorDoc =
          await _firestore.collection('users').doc(interactorId).get();
      final interactorName = interactorDoc.data()?['name'] ?? 'Someone';

      await _notificationService.handleMoodBoardInteraction(
        boardOwnerId: boardOwnerId,
        interactorName: interactorName,
        isLike: isLike,
      );
    } catch (e) {
      print('Error handling mood board interaction: $e');
    }
  }

  // Get top 10 memes by likes
  Future<List<MemePost>> getTopMemes() async {
    try {
      final querySnapshot = await _firestore.collection('memes').get();

      // Convert all documents to MemePost objects with user data
      final memes = await Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data();
        final userDoc =
            await _firestore.collection('users').doc(data['userId']).get();
        final userData = userDoc.data();

        return MemePost(
          id: doc.id,
          userId: data['userId'],
          userName: data['userName'] ?? '',
          memeUrl: data['memeUrl'] ?? '',
          caption: data['caption'] ?? '',
          videoId: data['videoId'],
          videoTitle: data['videoTitle'],
          artistName: data['artistName'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
          passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
          userProfileImage: userData?['profileImage'],
        );
      }));

      // Sort by number of likes (descending) and take top 10
      memes.sort(
          (a, b) => b.likedByUsers.length.compareTo(a.likedByUsers.length));
      return memes.take(10).toList();
    } catch (e) {
      throw 'Failed to get top memes: $e';
    }
  }
}
