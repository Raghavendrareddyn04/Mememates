import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meme_post.dart';
import 'cloudinary_service.dart';
import 'chat_service.dart';

class MemeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ChatService _chatService = ChatService();
  final UserMemeInteractions _memeInteractions = UserMemeInteractions();

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
  Stream<List<MemePost>> getMemesFeed(String userId) {
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

  // Like a meme
  Future<void> likeMeme(String memeId, String userId) async {
    final memeDoc = await _firestore.collection('memes').doc(memeId).get();
    final memeData = memeDoc.data();
    
    if (memeData != null) {
      final memeOwnerId = memeData['userId'] as String;
      
      // Add user to likedByUsers
      await _firestore.collection('memes').doc(memeId).update({
        'likedByUsers': FieldValue.arrayUnion([userId]),
      });

      // Create chat entry
      await _chatService.createChatOnMemeLike(memeId, userId, memeOwnerId);

      // Check if there's a mutual like
      final hasOtherUserLikedMyMeme = await _memeInteractions.hasUserLikedMyMeme(userId, memeOwnerId);
      if (hasOtherUserLikedMyMeme) {
        // Enable messaging if there's a mutual like
        await _chatService.checkAndEnableMessaging(userId, memeOwnerId);
      }
    }
  }

  // Pass a meme
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