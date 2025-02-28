import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meme_post.dart';

class MemeGalleryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all memes for a specific user
  Stream<List<MemePost>> getUserMemeGallery(String userId) {
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
                audiusTrackId: data['audiusTrackId'],
                trackTitle: data['trackTitle'],
                artwork: data['artwork'],
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
                passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
                userProfileImage: data['userProfileImage'],
              );
            }).toList());
  }

  // Get a specific meme by ID
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
        videoId: data['videoId'],
        videoTitle: data['videoTitle'],
        artistName: data['artistName'],
        audiusTrackId: data['audiusTrackId'],
        trackTitle: data['trackTitle'],
        artwork: data['artwork'],
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        likedByUsers: List<String>.from(data['likedByUsers'] ?? []),
        passedByUsers: List<String>.from(data['passedByUsers'] ?? []),
        userProfileImage: data['userProfileImage'],
      );
    } catch (e) {
      print('Error getting meme by ID: $e');
      return null;
    }
  }

  // Get meme stats
  Future<Map<String, dynamic>> getMemeStats(String memeId) async {
    try {
      final doc = await _firestore.collection('memes').doc(memeId).get();
      if (!doc.exists) {
        return {
          'likeCount': 0,
          'passCount': 0,
        };
      }

      final data = doc.data()!;
      final likedByUsers = List<String>.from(data['likedByUsers'] ?? []);
      final passedByUsers = List<String>.from(data['passedByUsers'] ?? []);

      return {
        'likeCount': likedByUsers.length,
        'passCount': passedByUsers.length,
      };
    } catch (e) {
      print('Error getting meme stats: $e');
      return {
        'likeCount': 0,
        'passCount': 0,
      };
    }
  }
}
