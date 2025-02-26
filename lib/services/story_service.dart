import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_auth/models/story.dart';
import 'package:flutter_auth/services/cloudinary_service.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Future<String> createStory({
    required String userId,
    required String userName,
    required String content,
    required StoryType type,
    String? userProfileImage,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // For image and video stories, upload to Cloudinary first
      String finalContent = content;
      if (type == StoryType.image) {
        finalContent = await _cloudinaryService.uploadImage(content);
      } else if (type == StoryType.video) {
        finalContent = await _cloudinaryService.uploadVideo(content);
      }

      // Create story with 24-hour expiration
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final storyRef = await _firestore.collection('stories').add({
        'userId': userId,
        'userName': userName,
        'userProfileImage': userProfileImage,
        'content': finalContent,
        'type': type.index,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewedBy': [],
        'metadata': metadata,
      });

      // Update user's stories list
      await _firestore.collection('users').doc(userId).update({
        'activeStories': FieldValue.arrayUnion([storyRef.id]),
      });

      return storyRef.id;
    } catch (e) {
      throw 'Failed to create story: $e';
    }
  }

  Future<void> markStoryAsViewed(String storyId, String viewerId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'viewedBy': FieldValue.arrayUnion([viewerId]),
      });
    } catch (e) {
      throw 'Failed to mark story as viewed: $e';
    }
  }

  Stream<List<Story>> getActiveStories() {
    final now = DateTime.now();
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt', descending: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Story>> getUserStories(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt', descending: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
    });
  }

  Future<void> deleteStory(String storyId, String userId) async {
    try {
      // Delete the story document
      await _firestore.collection('stories').doc(storyId).delete();

      // Remove from user's active stories
      await _firestore.collection('users').doc(userId).update({
        'activeStories': FieldValue.arrayRemove([storyId]),
      });
    } catch (e) {
      throw 'Failed to delete story: $e';
    }
  }

  // Clean up expired stories (can be called periodically or via Cloud Functions)
  Future<void> cleanupExpiredStories() async {
    try {
      final now = DateTime.now();
      final expiredStoriesQuery = await _firestore
          .collection('stories')
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (var doc in expiredStoriesQuery.docs) {
        batch.delete(doc.reference);

        // Also remove from user's active stories
        final userId = doc.data()['userId'] as String;
        batch.update(
          _firestore.collection('users').doc(userId),
          {
            'activeStories': FieldValue.arrayRemove([doc.id]),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      print('Error cleaning up expired stories: $e');
    }
  }
}
