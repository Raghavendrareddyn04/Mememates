import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_auth/models/user_profile.dart';
import '../models/meme_post.dart';
import 'cloudinary_service.dart';
import 'chat_service.dart';

// Update the MemeService class with optimized methods
class MemeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ChatService _chatService = ChatService();
  final UserMemeInteractions _memeInteractions = UserMemeInteractions();
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
      final theirMemesQuery = await _firestore
          .collection('memes')
          .where('likedByUsers', arrayContains: userId)
          .get();

      final iLikedUsers = <String>{};
      for (var doc in theirMemesQuery.docs) {
        iLikedUsers.add(doc.data()['userId'] as String);
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
            anthem: data['anthem'] ?? '',
            artistName: data['artistName'] ?? '',
            songTitle: data['songTitle'] ?? '',
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

  Future<List<MemePost>> getLikedMemes(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('memes')
          .where('likedByUsers', arrayContains: userId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return MemePost(
          id: doc.id,
          userId: data['userId'],
          userName: data['userName'] ?? '',
          memeUrl: data['memeUrl'] ?? '',
          caption: data['caption'] ?? '',
          songUrl: data['songUrl'],
          songTitle: data['songTitle'],
          artistName: data['artistName'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
          passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
          userProfileImage: data['userProfileImage'],
        );
      }).toList();
    } catch (e) {
      throw 'Failed to get liked memes: $e';
    }
  }

// Update the getMemesFeed method to include filtering
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
      final memes = <MemePost>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final postUserId = data['userId'] as String;

        // Skip if this is the user's own meme
        if (postUserId == userId) continue;

        // Get poster's profile for filtering
        final posterDoc =
            await _firestore.collection('users').doc(postUserId).get();
        final posterData = posterDoc.data();

        // Apply filters
        if (posterData != null) {
          final posterAge = posterData['age'] as int?;
          final posterGender = posterData['gender'] as String?;

          // Skip if doesn't match age filter
          if (minAge != null &&
              maxAge != null &&
              posterAge != null &&
              (posterAge < minAge || posterAge > maxAge)) {
            continue;
          }

          // Skip if doesn't match gender filter
          if (preferredGender != null &&
              preferredGender != 'All' &&
              posterGender != preferredGender) {
            continue;
          }

          memes.add(MemePost(
            id: doc.id,
            userId: postUserId,
            userName: data['userName'] ?? '',
            memeUrl: data['memeUrl'] ?? '',
            caption: data['caption'] ?? '',
            songUrl: data['songUrl'],
            songTitle: data['songTitle'],
            artistName: data['artistName'],
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
            passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
            userProfileImage: posterData['profileImage'],
          ));
        }
      }

      return memes
          .where((meme) => !meme.passedByUsers.contains(userId))
          .toList();
    });
  }

  // Post a new meme
  Future<void> postMeme({
    required String userId,
    required String userName,
    required String imagePath,
    required String caption,
    String? songUrl,
    String? songTitle,
    String? artistName,
  }) async {
    try {
      // Get user profile image from Auth
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userProfileImage = userDoc.data()?['profileImage'] as String?;

      // Upload meme image to Cloudinary
      final memeUrl = await _cloudinaryService.uploadImage(imagePath);

      // Save meme data to Firestore
      await _firestore.collection('memes').add({
        'userId': userId,
        'userName': userName,
        'memeUrl': memeUrl,
        'caption': caption,
        'songUrl': songUrl,
        'songTitle': songTitle,
        'artistName': artistName,
        'createdAt': FieldValue.serverTimestamp(),
        'likedByUsers': [],
        'passedByUsers': [],
        'userProfileImage': userProfileImage,
      });
    } catch (e) {
      throw 'Failed to post meme: $e';
    }
  }

  // Get meme feed for a user (excluding their own memes)
  Stream<List<MemePost>> getMemesFeedWithAgeFilter(String userId,
      {required int minAge, required int maxAge, String? preferredGender}) {
    return _firestore
        .collection('memes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final memes = <MemePost>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final postUserId = data['userId'] as String;

        // Skip if this is the user's own meme
        if (postUserId == userId) continue;

        // Get the latest profile image
        final userDoc =
            await _firestore.collection('users').doc(postUserId).get();
        final userData = userDoc.data();
        final latestProfileImage = userData?['profileImage'] as String?;

        if (latestProfileImage != null && latestProfileImage.isNotEmpty) {
          await doc.reference.update({'userProfileImage': latestProfileImage});
        }

        memes.add(MemePost(
          id: doc.id,
          userId: postUserId,
          userName: data['userName'] ?? '',
          memeUrl: data['memeUrl'] ?? '',
          caption: data['caption'] ?? '',
          songUrl: data['songUrl'],
          songTitle: data['songTitle'],
          artistName: data['artistName'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
          passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
          userProfileImage: latestProfileImage,
        ));
      }

      return memes
          .where((meme) => !meme.passedByUsers.contains(userId))
          .toList();
    });
  }

  // Get user's memes for profile
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
                songUrl: data['songUrl'],
                songTitle: data['songTitle'],
                artistName: data['artistName'],
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
                passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
                userProfileImage: data['userProfileImage'],
              );
            }).toList());
  }

  // Get single meme by ID
  Future<MemePost?> getMemeById(String memeId) async {
    try {
      final doc = await _firestore.collection('memes').doc(memeId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return MemePost(
        id: doc.id,
        userId: data['userId'],
        userName: data['userName'] ?? '',
        memeUrl: data['memeUrl'] ?? '',
        caption: data['caption'] ?? '',
        songUrl: data['songUrl'],
        songTitle: data['songTitle'],
        artistName: data['artistName'],
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
        passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
        userProfileImage: data['userProfileImage'],
      );
    } catch (e) {
      throw 'Failed to get meme: $e';
    }
  }

  // Optimized like meme method
  Future<void> likeMeme(String memeId, String userId) async {
    // Start a batch write
    final batch = _firestore.batch();
    final memeRef = _firestore.collection('memes').doc(memeId);

    // Add user to likedByUsers immediately
    batch.update(memeRef, {
      'likedByUsers': FieldValue.arrayUnion([userId]),
    });

    // Commit the batch
    await batch.commit();

    // Handle chat creation and mutual like check in the background
    _handleLikeBackground(memeId, userId);
  }

  // Background processing for like
  Future<void> _handleLikeBackground(String memeId, String userId) async {
    try {
      final memeDoc = await _firestore.collection('memes').doc(memeId).get();
      final memeData = memeDoc.data();

      if (memeData != null) {
        final memeOwnerId = memeData['userId'] as String;

        // Create chat entry
        await _chatService.createChatOnMemeLike(memeId, userId, memeOwnerId);

        // Check for mutual like
        final hasOtherUserLikedMyMeme =
            await _memeInteractions.hasUserLikedMyMeme(userId, memeOwnerId);
        if (hasOtherUserLikedMyMeme) {
          await _chatService.checkAndEnableMessaging(userId, memeOwnerId);
        }
      }
    } catch (e) {
      // Log error but don't throw - this is background processing
      print('Background like processing error: $e');
    }
  }

  // Optimized pass meme method
  Future<void> passMeme(String memeId, String userId) async {
    await _firestore.collection('memes').doc(memeId).update({
      'passedByUsers': FieldValue.arrayUnion([userId]),
    });
  }
}

class UserMemeInteractions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> hasUserLikedMyMeme(String myUserId, String otherUserId) async {
    final querySnapshot = await _firestore
        .collection('memes')
        .where('userId', isEqualTo: myUserId)
        .where('likedByUsers', arrayContains: otherUserId)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
